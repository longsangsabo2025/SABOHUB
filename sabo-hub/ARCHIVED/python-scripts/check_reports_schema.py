#!/usr/bin/env python3
"""Check schema and data for Reports page using Transaction Pooler"""

import psycopg2
from datetime import datetime

# Transaction Pooler connection
DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
COMPANY_ID = "9f8921df-3760-44b5-9a7f-20f8484b0300"

def main():
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()
    
    print("=" * 70)
    print("CHECKING REPORTS DATA WITH TRANSACTION POOLER")
    print("=" * 70)
    
    # 1. Check sales_orders schema
    print("\n=== SALES_ORDERS SCHEMA ===")
    cur.execute("""
        SELECT column_name, data_type, is_nullable 
        FROM information_schema.columns 
        WHERE table_name = 'sales_orders'
        ORDER BY ordinal_position
    """)
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} (nullable: {row[2]})")
    
    # 2. Check all sales orders for company
    print("\n=== ALL SALES_ORDERS FOR ODORI ===")
    cur.execute("""
        SELECT id, status, payment_status, delivery_status, total, 
               created_at, order_date, customer_id
        FROM sales_orders 
        WHERE company_id = %s
        ORDER BY created_at DESC
    """, (COMPANY_ID,))
    orders = cur.fetchall()
    print(f"Total orders: {len(orders)}")
    for o in orders:
        print(f"  ID: {o[0][:8]}... | status={o[1]} | payment={o[2]} | delivery={o[3]} | total={o[4]}")
        print(f"      created_at={o[5]} | order_date={o[6]}")
    
    # 3. Check products schema and data
    print("\n=== PRODUCTS SCHEMA ===")
    cur.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'products'
        AND column_name IN ('id', 'name', 'stock_quantity', 'min_stock_level', 'status', 'company_id')
    """)
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]}")
    
    print("\n=== PRODUCTS FOR ODORI ===")
    cur.execute("""
        SELECT id, name, stock_quantity, min_stock_level, status
        FROM products 
        WHERE company_id = %s
        LIMIT 10
    """, (COMPANY_ID,))
    products = cur.fetchall()
    print(f"Total products (limit 10): {len(products)}")
    for p in products:
        print(f"  {p[1]}: stock={p[2]}, min_level={p[3]}, status={p[4]}")
    
    # Count active products
    cur.execute("""
        SELECT COUNT(*) FROM products 
        WHERE company_id = %s AND status = 'active'
    """, (COMPANY_ID,))
    active_count = cur.fetchone()[0]
    print(f"Active products: {active_count}")
    
    # 4. Check if there are orders this month (Feb 2026)
    print("\n=== ORDERS THIS MONTH (Feb 2026) ===")
    start_of_month = datetime(2026, 2, 1)
    cur.execute("""
        SELECT id, status, created_at, total
        FROM sales_orders 
        WHERE company_id = %s AND created_at >= %s
    """, (COMPANY_ID, start_of_month))
    month_orders = cur.fetchall()
    print(f"Orders this month (created_at >= 2026-02-01): {len(month_orders)}")
    for o in month_orders:
        print(f"  {o[0][:8]}... status={o[1]} created_at={o[2]} total={o[3]}")
    
    # Check with order_date
    cur.execute("""
        SELECT id, status, order_date, total
        FROM sales_orders 
        WHERE company_id = %s AND order_date >= '2026-02-01'
    """, (COMPANY_ID,))
    month_orders_by_date = cur.fetchall()
    print(f"Orders this month (order_date >= 2026-02-01): {len(month_orders_by_date)}")
    
    # 5. Check receivables (unpaid orders)
    print("\n=== RECEIVABLES (UNPAID ORDERS) ===")
    cur.execute("""
        SELECT id, payment_status, total
        FROM sales_orders 
        WHERE company_id = %s 
        AND payment_status IN ('unpaid', 'partial', 'pending_transfer', 'pending')
    """, (COMPANY_ID,))
    receivables = cur.fetchall()
    print(f"Unpaid orders: {len(receivables)}")
    total_receivable = 0
    for r in receivables:
        print(f"  {r[0][:8]}... payment_status={r[1]} total={r[2]}")
        total_receivable += r[2] if r[2] else 0
    print(f"Total receivables: {total_receivable:,.0f}đ")
    
    # 6. Check inventory table (if exists)
    print("\n=== INVENTORY TABLE ===")
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = 'inventory'
        )
    """)
    if cur.fetchone()[0]:
        cur.execute("""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = 'inventory'
        """)
        print("Inventory columns:")
        for row in cur.fetchall():
            print(f"  {row[0]}: {row[1]}")
        
        cur.execute("""
            SELECT COUNT(*) FROM inventory WHERE company_id = %s
        """, (COMPANY_ID,))
        inv_count = cur.fetchone()[0]
        print(f"Inventory records for Odori: {inv_count}")
    else:
        print("  Inventory table does not exist!")
    
    # 7. Check customers
    print("\n=== CUSTOMERS ===")
    cur.execute("""
        SELECT COUNT(*) FROM customers WHERE company_id = %s
    """, (COMPANY_ID,))
    cust_count = cur.fetchone()[0]
    print(f"Customers for Odori: {cust_count}")
    
    # 8. Check the exact dates of orders
    print("\n=== ORDER DATES ANALYSIS ===")
    cur.execute("""
        SELECT 
            created_at::date as date,
            COUNT(*) as count,
            SUM(total) as total
        FROM sales_orders 
        WHERE company_id = %s
        GROUP BY created_at::date
        ORDER BY date DESC
    """, (COMPANY_ID,))
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} orders, total={row[2]:,.0f}đ")
    
    cur.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("SUMMARY:")
    print("=" * 70)
    print(f"- Total orders: {len(orders)}")
    print(f"- Orders this month (Feb 2026): {len(month_orders)}")
    print(f"- Unpaid orders: {len(receivables)}, Total: {total_receivable:,.0f}đ")
    print(f"- Active products: {active_count}")
    print(f"- Customers: {cust_count}")

if __name__ == "__main__":
    main()
