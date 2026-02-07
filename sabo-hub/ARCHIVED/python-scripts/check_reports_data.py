"""
Check data for Reports tabs: Công nợ, Tồn kho, Đơn hàng
"""
from datetime import datetime, timedelta
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
company_id = "9f8921df-3760-44b5-9a7f-20f8484b0300"

print("=" * 60)
print("CHECKING REPORTS DATA FOR MANAGER TABS")
print("=" * 60)

# ==================== 1. REVENUE TAB ====================
print("\n📊 1. DOANH THU (Revenue) Tab")
print("-" * 40)

now = datetime.now()
start_of_month = datetime(now.year, now.month, 1)

# Check orders with status filter (same as code)
orders_confirmed = supabase.table("sales_orders").select("id, total, status").eq("company_id", company_id).in_("status", ["confirmed", "processing", "completed"]).execute()
print(f"Orders with status [confirmed, processing, completed]: {len(orders_confirmed.data)}")

# Check ALL orders
all_orders = supabase.table("sales_orders").select("id, total, status, order_date").eq("company_id", company_id).execute()
print(f"ALL orders: {len(all_orders.data)}")

# Status breakdown
status_counts = {}
for o in all_orders.data:
    s = o.get('status') or 'null'
    status_counts[s] = status_counts.get(s, 0) + 1
print("\nStatus breakdown of all orders:")
for s, c in sorted(status_counts.items()):
    print(f"  - {s}: {c}")

# ==================== 2. CÔNG NỢ (Receivables) Tab ====================
print("\n💰 2. CÔNG NỢ (Receivables) Tab")
print("-" * 40)

# Check unpaid/partial orders (same filter as code)
unpaid_orders = supabase.table("sales_orders").select("id, total, payment_status").eq("company_id", company_id).in_("payment_status", ["unpaid", "partial"]).execute()
print(f"Orders with payment_status [unpaid, partial]: {len(unpaid_orders.data)}")

# Check all payment statuses
payment_status_counts = {}
for o in all_orders.data:
    ps = o.get('payment_status') or 'null'
    payment_status_counts[ps] = payment_status_counts.get(ps, 0) + 1
print("\nPayment status breakdown:")
for ps, c in sorted(payment_status_counts.items()):
    print(f"  - {ps}: {c}")

# ==================== 3. TỒN KHO (Inventory) Tab ====================
print("\n📦 3. TỒN KHO (Inventory) Tab")
print("-" * 40)

# Check warehouses
warehouses = supabase.table("warehouses").select("id, name, is_main").eq("company_id", company_id).execute()
print(f"Warehouses: {len(warehouses.data)}")
for w in warehouses.data:
    print(f"  - {w['name']} (main: {w.get('is_main', False)})")

# Check inventory
inventory = supabase.table("inventory").select("id, product_id, warehouse_id, quantity").eq("company_id", company_id).execute()
print(f"\nInventory records: {len(inventory.data)}")
total_qty = sum(i.get('quantity', 0) for i in inventory.data)
print(f"Total quantity: {total_qty}")

# Check products
products = supabase.table("products").select("id, name, status").eq("company_id", company_id).execute()
print(f"\nProducts: {len(products.data)}")
product_status = {}
for p in products.data:
    s = p.get('status') or 'null'
    product_status[s] = product_status.get(s, 0) + 1
for s, c in sorted(product_status.items()):
    print(f"  - {s}: {c}")

# ==================== 4. ĐƠN HÀNG (Orders) Tab ====================
print("\n🛒 4. ĐƠN HÀNG (Orders) Tab")
print("-" * 40)

# Check order_items
order_items = supabase.table("order_items").select("id, quantity, unit_price, order_id").execute()
print(f"Order items: {len(order_items.data)}")

# Check recent orders
recent_orders = supabase.table("sales_orders").select(
    "id, order_number, status, delivery_status, payment_status, total, created_at"
).eq("company_id", company_id).order("created_at", desc=True).limit(5).execute()

print(f"\nRecent 5 orders:")
for o in recent_orders.data:
    print(f"  {o['order_number']}: status={o['status']}, delivery={o.get('delivery_status')}, payment={o.get('payment_status')}, total={o.get('total', 0):,.0f}")

# ==================== SUMMARY ====================
print("\n" + "=" * 60)
print("📋 SUMMARY - Why tabs might be empty:")
print("=" * 60)

print(f"""
1. DOANH THU Tab:
   - Code filters: status IN [confirmed, processing, completed]
   - Found: {len(orders_confirmed.data)} orders
   - ISSUE: All orders have status='completed', should work ✅

2. CÔNG NỢ Tab:  
   - Code filters: payment_status IN [unpaid, partial]
   - Found: {len(unpaid_orders.data)} orders
   - Status: {'✅ Has data' if unpaid_orders.data else '❌ No unpaid orders'}

3. TỒN KHO Tab:
   - Warehouses: {len(warehouses.data)}
   - Inventory records: {len(inventory.data)}
   - Status: {'✅ Has data' if inventory.data else '❌ No inventory'}

4. ĐƠN HÀNG Tab:
   - Total orders: {len(all_orders.data)}
   - Order items: {len(order_items.data)}
   - Status: {'✅ Has data' if all_orders.data else '❌ No orders'}
""")
