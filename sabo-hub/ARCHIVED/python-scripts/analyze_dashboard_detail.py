"""
Deep analysis of what user sees on dashboard
"""
from datetime import datetime, timedelta
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
company_id = "9f8921df-3760-44b5-9a7f-20f8484b0300"

print("=== Deep Analysis: What User Sees ===\n")

# Get all orders with details
orders_result = supabase.table("sales_orders").select(
    "order_number, customer_name, status, delivery_status, payment_status, total, created_at, updated_at"
).eq("company_id", company_id).order("created_at", desc=True).execute()

orders = orders_result.data

print("ALL ORDERS DETAILS:")
print("-" * 100)

total_revenue_all = 0
total_revenue_delivered = 0
total_revenue_delivered_paid = 0

for o in orders:
    total = o.get('total') or 0
    total_revenue_all += total
    
    ds = o.get('delivery_status') or ''
    ps = o.get('payment_status') or ''
    
    if ds == 'delivered':
        total_revenue_delivered += total
    if ds == 'delivered' and ps == 'paid':
        total_revenue_delivered_paid += total
    
    print(f"📦 {o['order_number']}: {o.get('customer_name', 'N/A')}")
    print(f"   Status: {o.get('status')} | Delivery: {ds} | Payment: {ps}")
    print(f"   Total: {total:,.0f} đ")
    print(f"   Created: {o.get('created_at')}")
    print(f"   Updated: {o.get('updated_at')}")
    print()

print("-" * 100)
print(f"\n📊 REVENUE ANALYSIS:")
print(f"   Total from all orders: {total_revenue_all:,.0f} đ")
print(f"   Total from delivered orders: {total_revenue_delivered:,.0f} đ")
print(f"   Total from delivered+paid orders: {total_revenue_delivered_paid:,.0f} đ")
print()

# What user probably expects vs what they see
print("=" * 100)
print("⚠️  POTENTIAL ISSUE FOUND:")
print()
print(f"   Dashboard shows TODAY'S REVENUE: {total_revenue_delivered_paid:,.0f} đ")
print(f"   But total sales today (all delivered): {total_revenue_delivered:,.0f} đ")
print(f"   Difference: {total_revenue_delivered - total_revenue_delivered_paid:,.0f} đ (unpaid orders)")
print()
print("   This may confuse users who expect to see total sales, not just paid orders.")
print("=" * 100)

# Check recent orders for "Đơn hàng gần đây" section
print("\n📋 RECENT ORDERS (what shows in 'Đơn hàng gần đây'):")
recent = supabase.table("sales_orders").select(
    "order_number, status, delivery_status, payment_status, total, created_at, customers(name)"
).eq("company_id", company_id).order("created_at", desc=True).limit(10).execute()

for o in recent.data:
    customer = o.get('customers', {}) or {}
    customer_name = customer.get('name', 'N/A')
    ds = o.get('delivery_status') or 'N/A'
    ps = o.get('payment_status') or 'N/A'
    
    # Status color logic (from code)
    if ds == 'delivered':
        status_icon = "🟢"
    elif ds in ['delivering', 'in_progress']:
        status_icon = "🟠"
    elif ds == 'cancelled':
        status_icon = "🔴"
    else:
        status_icon = "⚪"
    
    print(f"   {status_icon} {o['order_number']}: {customer_name} - {o.get('total', 0):,.0f} đ")
    print(f"      Delivery: {ds} | Payment: {ps}")
