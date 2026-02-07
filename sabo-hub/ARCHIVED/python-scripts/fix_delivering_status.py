import os
from supabase import create_client

supabase = create_client(
    'https://dqddxowyikefqcdiioyh.supabase.co', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y'
)

# Fix 1: Update delivery status from in_progress to completed
print("=== FIXING DELIVERIES ===")
deliveries = supabase.table('deliveries').select('id, order_id, status').eq('status', 'in_progress').execute()
for d in deliveries.data:
    print(f"Updating delivery {d['id'][:8]}... from in_progress to completed")
    supabase.table('deliveries').update({'status': 'completed'}).eq('id', d['id']).execute()

# Fix 2: Update sales_orders that have payment_status=paid but delivery_status=delivering
print("\n=== FIXING SALES ORDERS ===")
orders = supabase.table('sales_orders').select('id, order_number, delivery_status, payment_status').eq('delivery_status', 'delivering').eq('payment_status', 'paid').execute()
for o in orders.data:
    print(f"Updating order {o['order_number']} from delivering to delivered")
    supabase.table('sales_orders').update({'delivery_status': 'delivered'}).eq('id', o['id']).execute()

print("\n✅ DONE! Refresh dashboard to see changes.")
