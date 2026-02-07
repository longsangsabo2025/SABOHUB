"""
Validate dashboard stats against code logic
"""
from datetime import datetime, timedelta
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
company_id = "9f8921df-3760-44b5-9a7f-20f8484b0300"

print("=== Validating Dashboard Stats ===\n")

# 1. Total Customers (same as code)
customers_result = supabase.table("customers").select("id, status").eq("company_id", company_id).execute()
customers = customers_result.data
total_customers = len(customers)
active_customers = len([c for c in customers if c.get('status') == 'active'])
print(f"1. Total Customers: {total_customers}")
print(f"   Active Customers: {active_customers}")

# 2. Total Products (same as code)
products_result = supabase.table("products").select("id").eq("company_id", company_id).eq("status", "active").execute()
total_products = len(products_result.data)
print(f"\n2. Total Active Products: {total_products}")

# 3. Orders Stats (same logic as code)
orders_result = supabase.table("sales_orders").select(
    "id, status, delivery_status, payment_status, total, created_at, updated_at"
).eq("company_id", company_id).execute()
orders = orders_result.data

print(f"\n3. Total Orders: {len(orders)}")

# Pending orders calculation (same logic as Dart code)
pending_orders = 0
for o in orders:
    status = o.get('status') or ''
    delivery_status = o.get('delivery_status') or ''
    
    # Skip cancelled
    if status == 'cancelled':
        continue
    
    # Pending = no delivery status or pending or awaiting_pickup
    if delivery_status == '' or delivery_status == 'pending' or delivery_status == 'null' or delivery_status == 'awaiting_pickup':
        pending_orders += 1

print(f"   Pending Orders: {pending_orders}")

# Completed today (same logic)
today = datetime.utcnow()
today_start = datetime(today.year, today.month, today.day)
yesterday_start = today_start - timedelta(hours=7)  # VN timezone

completed_today = 0
for o in orders:
    delivery_status = o.get('delivery_status') or ''
    updated_at_str = o.get('updated_at') or ''
    
    if delivery_status != 'delivered' or not updated_at_str:
        continue
    
    try:
        updated_at = datetime.fromisoformat(updated_at_str.replace('Z', '+00:00').replace('+00:00', ''))
        if updated_at > yesterday_start:
            completed_today += 1
    except:
        pass

print(f"   Completed Today: {completed_today}")

# 4. In Progress Deliveries
deliveries_result = supabase.table("deliveries").select("id, status").eq("company_id", company_id).execute()
deliveries = deliveries_result.data

in_progress_from_deliveries = len([d for d in deliveries if d.get('status') in ['in_progress', 'loading']])
in_progress_from_orders = len([o for o in orders if o.get('delivery_status') in ['delivering', 'awaiting_pickup']])
in_progress = max(in_progress_from_deliveries, in_progress_from_orders)

print(f"\n4. In Progress Deliveries: {in_progress}")
print(f"   - From deliveries table: {in_progress_from_deliveries}")
print(f"   - From orders table: {in_progress_from_orders}")

# 5. Revenue
month_start = datetime(today.year, today.month, 1)
today_revenue = 0
month_revenue = 0

for o in orders:
    delivery_status = o.get('delivery_status') or ''
    payment_status = o.get('payment_status') or ''
    total = o.get('total') or 0
    
    if delivery_status == 'delivered' and payment_status == 'paid':
        updated_at_str = o.get('updated_at') or o.get('created_at') or ''
        if not updated_at_str:
            continue
        
        try:
            updated_at = datetime.fromisoformat(updated_at_str.replace('Z', '+00:00').replace('+00:00', ''))
            
            if updated_at > yesterday_start:
                today_revenue += total
            if updated_at > month_start - timedelta(days=1):
                month_revenue += total
        except:
            pass

print(f"\n5. Revenue:")
print(f"   Today's Revenue: {today_revenue:,.0f} đ")
print(f"   Month's Revenue: {month_revenue:,.0f} đ")

# 6. Receivables
receivables_result = supabase.table("receivables").select(
    "original_amount, paid_amount, due_date, status"
).eq("company_id", company_id).in_("status", ["open", "partial"]).execute()
receivables = receivables_result.data

total_receivables = 0
overdue_receivables = 0

for r in receivables:
    original = r.get('original_amount') or 0
    paid = r.get('paid_amount') or 0
    outstanding = original - paid
    total_receivables += outstanding
    
    due_date_str = r.get('due_date')
    if due_date_str:
        try:
            due_date = datetime.fromisoformat(due_date_str.replace('Z', '+00:00').replace('+00:00', ''))
            if due_date < today:
                overdue_receivables += outstanding
        except:
            pass

print(f"\n6. Receivables:")
print(f"   Total Receivables: {total_receivables:,.0f} đ")
print(f"   Overdue Receivables: {overdue_receivables:,.0f} đ")

print("\n=== Summary ===")
print(f"""
Expected Dashboard Values:
- Đơn chờ xử lý: {pending_orders}
- Đang giao: {in_progress}
- Hoàn thành hôm nay: {completed_today}
- Khách hàng: {total_customers}
- Doanh thu hôm nay: {today_revenue:,.0f} đ
- Doanh thu tháng: {month_revenue:,.0f} đ
""")
