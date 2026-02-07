#!/usr/bin/env python3
"""Check inventory movements to debug the doubling issue"""

from supabase import create_client
import os
from dotenv import load_dotenv
load_dotenv('sabohub-nexus/.env')

SUPABASE_URL = os.getenv('VITE_SUPABASE_URL')
SUPABASE_KEY = os.getenv('VITE_SUPABASE_ANON_KEY')

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Check recent inventory movements to see what happened
print('=== 10 LỊCH SỬ NHẬP KHO GẦN NHẤT ===')
movements = supabase.table('inventory_movements').select(
    '*, products(name), warehouses!inventory_movements_warehouse_id_fkey(name)'
).eq('type', 'in').order('created_at', desc=True).limit(10).execute()

for m in movements.data:
    product = m.get('products', {}).get('name', 'N/A')
    warehouse = m.get('warehouses', {}).get('name', 'N/A')
    print(f"""
Sản phẩm: {product}
Kho: {warehouse}
SL nhập: {m['quantity']}
Trước: {m['before_quantity']} → Sau: {m['after_quantity']}
Ngày: {m['created_at']}
---""")

# Check current inventory 
print('\n=== TỒN KHO HIỆN TẠI ===')
inventory = supabase.table('inventory').select(
    '*, products(name, sku), warehouses(name)'
).order('updated_at', desc=True).limit(15).execute()

for inv in inventory.data:
    product = inv.get('products', {})
    warehouse = inv.get('warehouses', {}).get('name', 'N/A')
    print(f"{product.get('name', 'N/A')} ({product.get('sku', '')}) @ {warehouse}: {inv['quantity']}")

# Check for database triggers on inventory table
print('\n=== KIỂM TRA TRIGGER TRÊN BẢNG INVENTORY ===')
try:
    result = supabase.rpc('get_inventory_triggers', {}).execute()
    print(result.data)
except Exception as e:
    print(f"Không có RPC function: {e}")
