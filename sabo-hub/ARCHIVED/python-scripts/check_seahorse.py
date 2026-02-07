#!/usr/bin/env python3
"""Check all movements for Sea Horse product"""

from supabase import create_client
import os
from dotenv import load_dotenv
load_dotenv('sabohub-nexus/.env')

supabase = create_client(
    os.getenv('VITE_SUPABASE_URL'),
    os.getenv('VITE_SUPABASE_ANON_KEY')
)

# Find Nuoc Xa Sea Horse product
products = supabase.table('products').select('id, name, sku').ilike('name', '%Sea Horse%').execute()
if products.data:
    prod = products.data[0]
    print(f'Product: {prod["name"]} (ID: {prod["id"]})')
    
    # Get all movements for this product
    print('\n=== TẤT CẢ MOVEMENTS CỦA SẢN PHẨM NÀY ===')
    movements = supabase.table('inventory_movements').select('*').eq('product_id', prod['id']).order('created_at', desc=True).execute()
    total_in = 0
    total_out = 0
    for m in movements.data:
        qty = m['quantity']
        if m['type'] == 'in':
            total_in += qty
        else:
            total_out += qty
        print(f'{m["type"]}: qty={qty}, before={m["before_quantity"]} -> after={m["after_quantity"]}, reason={m.get("reason")}, warehouse_id={m.get("warehouse_id")}, time={m["created_at"]}')
    
    print(f'\n📊 Tổng IN: {total_in}, Tổng OUT: {total_out}')
    print(f'📊 Tồn kho lý thuyết: {total_in - total_out}')
    
    # Get inventory records
    print('\n=== TỒN KHO HIỆN TẠI TRONG DB ===')
    inv = supabase.table('inventory').select('*, warehouses(name)').eq('product_id', prod['id']).execute()
    total_actual = 0
    for i in inv.data:
        total_actual += i['quantity']
        print(f'Kho: {i["warehouses"]["name"]}, Quantity: {i["quantity"]}')
    print(f'\n📊 Tổng tồn kho thực tế: {total_actual}')
    
    if total_actual != (total_in - total_out):
        print(f'\n⚠️ SAI LỆCH: Tồn kho thực tế ({total_actual}) != Lý thuyết ({total_in - total_out})')
