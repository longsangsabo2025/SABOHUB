import os
from supabase import create_client

supabase = create_client(
    'https://dqddxowyikefqcdiioyh.supabase.co', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y'
)

# Check deliveries that are still in progress
print('=== DELIVERIES IN PROGRESS OR LOADING ===')
deliveries = supabase.table('deliveries').select('id, order_id, status, created_at, updated_at').in_('status', ['in_progress', 'loading']).execute()
for d in deliveries.data:
    order_id = d.get('order_id', 'N/A')
    order_preview = order_id[:8] if order_id else 'N/A'
    print(f"ID: {d['id'][:8]}... | Status: {d['status']} | Order: {order_preview}...")
print(f'Total: {len(deliveries.data)}')

print()

# Check sales_orders with delivering status
print('=== SALES ORDERS WITH DELIVERING STATUS ===')
orders = supabase.table('sales_orders').select('id, order_number, delivery_status, payment_status, created_at').in_('delivery_status', ['delivering', 'awaiting_pickup']).execute()
for o in orders.data:
    print(f"Order: {o['order_number']} | Delivery: {o['delivery_status']} | Payment: {o.get('payment_status', 'N/A')}")
print(f'Total: {len(orders.data)}')
