"""
Check dashboard data for Manager Overview tab
Using transaction pooler for production data
"""
import os
from datetime import datetime, timedelta
from supabase import create_client

# Transaction pooler connection (from codemagic.yaml)
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get company ID for Odori
companies = supabase.table("companies").select("id, name").execute()
print("=== Companies ===")
for c in companies.data:
    print(f"  {c['name']}: {c['id']}")

company_id = None
for c in companies.data:
    if c['name'] == 'Odori':
        company_id = c['id']
        break

if not company_id:
    print("❌ Company 'Odori' not found!")
    exit(1)

print(f"\n✅ Using company: Odori ({company_id})")

# Check sales_orders schema
print("\n=== Sales Orders Schema ===")
orders_result = supabase.table("sales_orders").select("*").eq("company_id", company_id).limit(1).execute()
if orders_result.data:
    sample = orders_result.data[0]
    print(f"Sample order columns: {list(sample.keys())}")
else:
    print("No orders found")

# Get all orders for analysis
print("\n=== All Orders Analysis ===")
all_orders = supabase.table("sales_orders").select(
    "id, order_number, status, delivery_status, payment_status, total, created_at, updated_at"
).eq("company_id", company_id).execute()

print(f"Total orders: {len(all_orders.data)}")

# Analyze statuses
status_counts = {}
delivery_status_counts = {}
payment_status_counts = {}

for order in all_orders.data:
    s = order.get('status') or 'null'
    ds = order.get('delivery_status') or 'null'
    ps = order.get('payment_status') or 'null'
    
    status_counts[s] = status_counts.get(s, 0) + 1
    delivery_status_counts[ds] = delivery_status_counts.get(ds, 0) + 1
    payment_status_counts[ps] = payment_status_counts.get(ps, 0) + 1

print("\nStatus breakdown:")
for s, count in sorted(status_counts.items()):
    print(f"  {s}: {count}")

print("\nDelivery status breakdown:")
for ds, count in sorted(delivery_status_counts.items()):
    print(f"  {ds}: {count}")

print("\nPayment status breakdown:")
for ps, count in sorted(payment_status_counts.items()):
    print(f"  {ps}: {count}")

# Calculate revenue
print("\n=== Revenue Calculation ===")
today = datetime.utcnow()
today_start = datetime(today.year, today.month, today.day)
yesterday_start = today_start - timedelta(hours=7)  # VN timezone
month_start = datetime(today.year, today.month, 1)

print(f"Today (UTC): {today}")
print(f"Yesterday start (for VN): {yesterday_start}")
print(f"Month start: {month_start}")

today_revenue = 0
month_revenue = 0
delivered_paid_orders = []

for order in all_orders.data:
    ds = order.get('delivery_status') or ''
    ps = order.get('payment_status') or ''
    total = order.get('total') or 0
    
    if ds == 'delivered' and ps == 'paid':
        updated_at_str = order.get('updated_at') or order.get('created_at') or ''
        if updated_at_str:
            try:
                updated_at = datetime.fromisoformat(updated_at_str.replace('Z', '+00:00').replace('+00:00', ''))
                
                delivered_paid_orders.append({
                    'order_number': order.get('order_number'),
                    'total': total,
                    'updated_at': updated_at,
                    'in_today': updated_at > yesterday_start
                })
                
                if updated_at > yesterday_start:
                    today_revenue += total
                if updated_at > month_start - timedelta(days=1):
                    month_revenue += total
            except Exception as e:
                print(f"  Error parsing date: {e}")

print(f"\nDelivered + Paid orders: {len(delivered_paid_orders)}")
print(f"Today's revenue (delivered+paid in last 24h): {today_revenue:,.0f} đ")
print(f"Month's revenue (delivered+paid this month): {month_revenue:,.0f} đ")

# Show recent delivered+paid orders
print("\n=== Recent Delivered + Paid Orders ===")
for o in sorted(delivered_paid_orders, key=lambda x: x['updated_at'], reverse=True)[:10]:
    marker = "✅" if o['in_today'] else "  "
    print(f"  {marker} {o['order_number']}: {o['total']:,.0f} đ - {o['updated_at']}")

# Check recent orders (for "Đơn hàng gần đây" section)
print("\n=== Recent Orders (last 10 by created_at) ===")
recent = supabase.table("sales_orders").select(
    "order_number, status, delivery_status, payment_status, total, created_at, customers(name)"
).eq("company_id", company_id).order("created_at", desc=True).limit(10).execute()

for o in recent.data:
    customer = o.get('customers', {}) or {}
    customer_name = customer.get('name', 'N/A')
    print(f"  {o['order_number']}: {customer_name}")
    print(f"    Status: {o.get('status')}, Delivery: {o.get('delivery_status')}, Payment: {o.get('payment_status')}")
    print(f"    Total: {o.get('total', 0):,.0f} đ, Created: {o.get('created_at')}")
    print()

# Check deliveries table for comparison
print("\n=== Deliveries Table Analysis ===")
deliveries = supabase.table("deliveries").select("id, status, order_id, created_at").eq("company_id", company_id).execute()
print(f"Total deliveries: {len(deliveries.data)}")

delivery_status_counts2 = {}
for d in deliveries.data:
    s = d.get('status') or 'null'
    delivery_status_counts2[s] = delivery_status_counts2.get(s, 0) + 1

print("Delivery statuses from deliveries table:")
for s, count in sorted(delivery_status_counts2.items()):
    print(f"  {s}: {count}")
