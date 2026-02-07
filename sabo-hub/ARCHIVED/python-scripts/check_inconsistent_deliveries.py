import os
from supabase import create_client

supabase = create_client(
    'https://dqddxowyikefqcdiioyh.supabase.co', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y'
)

print("=== CHECKING INCONSISTENT DELIVERY STATUS ===\n")

# Case 1: Delivery completed but sales_order not delivered
print("CASE 1: Delivery completed, but sales_order NOT delivered")
print("-" * 60)
deliveries_completed = supabase.table('deliveries').select('id, order_id, status, created_at').eq('status', 'completed').execute()
for d in deliveries_completed.data:
    order_id = d.get('order_id')
    if not order_id:
        continue
    order = supabase.table('sales_orders').select('id, order_number, delivery_status').eq('id', order_id).single().execute()
    if order.data and order.data.get('delivery_status') != 'delivered':
        print(f"❌ Order {order.data.get('order_number')}: delivery COMPLETED, but sales_order.delivery_status = {order.data.get('delivery_status')}")

# Case 2: Sales_order delivered but delivery not completed
print("\nCASE 2: Sales_order delivered, but delivery NOT completed")
print("-" * 60)
orders_delivered = supabase.table('sales_orders').select('id, order_number, delivery_status').eq('delivery_status', 'delivered').execute()
for o in orders_delivered.data:
    order_id = o.get('id')
    delivery = supabase.table('deliveries').select('id, order_id, status').eq('order_id', order_id).execute()
    if delivery.data:
        for d in delivery.data:
            if d.get('status') != 'completed':
                print(f"❌ Order {o.get('order_number')}: sales_order DELIVERED, but deliveries.status = {d.get('status')}")
    # else: no delivery record (may be delivered without delivery tracking)

# Case 3: Sales_order paid but still delivering
print("\nCASE 3: Sales_order PAID but still DELIVERING")
print("-" * 60)
orders_paid_delivering = supabase.table('sales_orders').select('id, order_number, delivery_status, payment_status').eq('delivery_status', 'delivering').eq('payment_status', 'paid').execute()
for o in orders_paid_delivering.data:
    print(f"⚠️ Order {o.get('order_number')}: payment_status=PAID but delivery_status=DELIVERING")

# Case 4: Deliveries in_progress with sales_orders that are delivered
print("\nCASE 4: Delivery IN_PROGRESS but sales_order DELIVERED")
print("-" * 60)
deliveries_in_progress = supabase.table('deliveries').select('id, order_id, status').eq('status', 'in_progress').execute()
for d in deliveries_in_progress.data:
    order_id = d.get('order_id')
    if not order_id:
        continue
    order = supabase.table('sales_orders').select('id, order_number, delivery_status').eq('id', order_id).single().execute()
    if order.data and order.data.get('delivery_status') == 'delivered':
        print(f"⚠️ Order {order.data.get('order_number')}: sales_order DELIVERED but delivery IN_PROGRESS")

print("\n✅ Check completed!")
