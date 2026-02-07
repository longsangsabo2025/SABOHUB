#!/usr/bin/env python3
"""Fix inventory quantities based on movement history"""

from supabase import create_client
import os
from dotenv import load_dotenv
load_dotenv('sabohub-nexus/.env')

supabase = create_client(os.getenv('VITE_SUPABASE_URL'), os.getenv('VITE_SUPABASE_ANON_KEY'))

# Get all products with inventory
print('=== FIXING INVENTORY BASED ON MOVEMENTS ===\n')

inventory = supabase.table('inventory').select('*, products(name)').execute()

for inv in inventory.data:
    product_id = inv['product_id']
    warehouse_id = inv['warehouse_id']
    current_qty = inv['quantity']
    product_name = inv.get('products', {}).get('name', 'Unknown')
    
    # Get all movements for this product in this warehouse
    movements = supabase.table('inventory_movements').select(
        'type, quantity, destination_warehouse_id'
    ).eq('product_id', product_id).eq('warehouse_id', warehouse_id).execute()
    
    # Also check for transfers TO this warehouse
    transfers_in = supabase.table('inventory_movements').select(
        'type, quantity'
    ).eq('product_id', product_id).eq('destination_warehouse_id', warehouse_id).eq('type', 'transfer').execute()
    
    total_in = 0
    total_out = 0
    
    for m in movements.data:
        if m['type'] == 'in':
            total_in += m['quantity']
        elif m['type'] == 'out':
            total_out += m['quantity']
        elif m['type'] == 'transfer':
            # For transfer FROM this warehouse
            total_out += m['quantity']
        elif m['type'] in ('adjustment', 'count'):
            # For adjustment/count, the quantity is the NEW total
            total_in = m['quantity']
            total_out = 0
    
    # Add transfers IN from other warehouses
    for m in transfers_in.data:
        total_in += m['quantity']
    
    correct_qty = total_in - total_out
    
    if current_qty != correct_qty:
        print(f'❌ {product_name}')
        print(f'   Hiện tại: {current_qty}, Đúng phải là: {correct_qty}')
        print(f'   (IN: {total_in}, OUT: {total_out})')
        
        # Fix it
        supabase.table('inventory').update({'quantity': correct_qty}).eq('id', inv['id']).execute()
        print(f'   ✅ Đã sửa thành: {correct_qty}')
        print()
    else:
        print(f'✅ {product_name}: {current_qty} (correct)')

print('\n=== DONE ===')
