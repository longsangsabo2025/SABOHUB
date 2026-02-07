#!/usr/bin/env python3
"""Check inventory data for reports page debugging"""

from supabase import create_client

url = 'https://ycgipxoedgtgbxnfovaf.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljZ2lweG9lZGd0Z2J4bmZvdmFmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxNjE3NzgwMCwiZXhwIjoyMDMxNzUzODAwfQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI'
supabase = create_client(url, key)

company_id = '9f8921df-3760-44b5-9a7f-20f8484b0300'

print("=" * 60)
print("CHECKING REPORTS DATA")
print("=" * 60)

# Check products table
print('\n=== Products Table ===')
products = supabase.table('products').select('id, name, sku, stock_quantity, min_stock_level, selling_price, status').eq('company_id', company_id).execute()
for p in products.data[:5]:
    print(f"  - {p.get('name')}: stock={p.get('stock_quantity')}, min={p.get('min_stock_level')}, status={p.get('status')}")
print(f'  Total: {len(products.data)} products')

# Check active products only  
active_products = [p for p in products.data if p.get('status') == 'active']
print(f'  Active products: {len(active_products)}')

# Check inventory table
print('\n=== Inventory Table ===')
try:
    inv = supabase.table('inventory').select('*').eq('company_id', company_id).limit(5).execute()
    for i in inv.data:
        print(f"  - {i}")
    print(f'  Total records: {len(inv.data)}')
except Exception as e:
    print(f'  Error: {e}')

# Check sales orders for reports
print('\n=== Sales Orders for Reports ===')
orders = supabase.table('sales_orders').select('id, status, payment_status, delivery_status, total, created_at, order_date').eq('company_id', company_id).execute()

print(f'Total orders: {len(orders.data)}')
for order in orders.data:
    print(f"  - ID: {order.get('id')[:8]}... | status={order.get('status')} | payment={order.get('payment_status')} | delivery={order.get('delivery_status')} | total={order.get('total')}")
    print(f"    created_at={order.get('created_at')} | order_date={order.get('order_date')}")

# Check by payment status for receivables  
print('\n=== Receivables Filter Check ===')
unpaid_orders = [o for o in orders.data if o.get('payment_status') in ['unpaid', 'partial', 'pending_transfer', 'pending']]
print(f'Orders matching receivables filter: {len(unpaid_orders)}')
for o in unpaid_orders:
    print(f"  - {o.get('id')[:8]}... payment_status={o.get('payment_status')} total={o.get('total')}")

# Check orders for orders report
print('\n=== Orders Report Check ===')
from datetime import datetime
now = datetime.now()
start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
print(f'Start of month: {start_of_month.isoformat()}')

month_orders = supabase.table('sales_orders').select('id, status, created_at').eq('company_id', company_id).gte('created_at', start_of_month.isoformat()).execute()
print(f'Orders this month (using created_at): {len(month_orders.data)}')

# Also check customers
print('\n=== Customers ===')
customers = supabase.table('customers').select('id, name, phone').eq('company_id', company_id).limit(5).execute()
print(f'Total customers: {len(customers.data)}')
for c in customers.data[:3]:
    print(f"  - {c.get('name')} ({c.get('phone')})")
