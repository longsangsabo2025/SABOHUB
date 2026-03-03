import psycopg2
conn = psycopg2.connect(host="aws-1-ap-southeast-2.pooler.supabase.com", port=6543, dbname="postgres", user="postgres.dqddxowyikefqcdiioyh", password="Acookingoil123")
cur = conn.cursor()
CID = '9f8921df-3760-44b5-9a7f-20f8484b0300'
TODAY = '2026-02-24'

tables_to_check = [
    ("deliveries", True),
    ("inventory_movements", True),
    ("stock_movements", True),
    ("receivables", False),
    ("customer_payments", True),
    ("sales_reports", True),
    ("sell_out_transactions", True),
    ("market_analysis", True),
    ("customer_visits", False),
    ("customer_contacts", False),
    ("competitor_reports", False),
    ("surveys", False),
    ("distributor_promotions", False),
    ("business_targets", False),
    ("sales_targets", False),
]

print("BANG             | TOTAL | TRUOC 24/02 | GHI CHU")
print("-" * 60)

for table, has_date in tables_to_check:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table} WHERE company_id = %s", (CID,))
        total = cur.fetchone()[0]
        before = '-'
        if has_date and total > 0:
            try:
                cur.execute(f"SELECT COUNT(*) FROM {table} WHERE company_id = %s AND DATE(created_at) < %s", (CID, TODAY))
                before = cur.fetchone()[0]
            except:
                conn.rollback()
                before = '?'
        print(f"{table:<25} {total:>5} | {str(before):>11} | {'XOA' if total > 0 and (before == '-' or (isinstance(before, int) and before > 0)) else ''}")
    except:
        conn.rollback()

# sales_order_history
print("\n--- sales_order_history ---")
try:
    cur.execute("SELECT COUNT(*) FROM sales_order_history")
    total = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM sales_order_history WHERE order_id NOT IN (SELECT id FROM sales_orders)")
    orphan = cur.fetchone()[0]
    print(f"  Total: {total}, Orphan: {orphan}")
except:
    conn.rollback()

# Stale customer fields
print("\n--- Customer stale fields ---")
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_order_date IS NOT NULL AND last_order_date < %s", (CID, TODAY))
print(f"  last_order_date < today: {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM customers WHERE company_id = %s AND last_visit_date IS NOT NULL", (CID,))
print(f"  last_visit_date != null: {cur.fetchone()[0]}")

conn.close()
