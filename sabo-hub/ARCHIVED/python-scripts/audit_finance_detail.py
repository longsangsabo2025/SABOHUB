import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
cur = conn.cursor()

tables = ['customer_payments', 'receivables', 'payment_allocations']
for table in tables:
    cur.execute(f"""
        SELECT column_name, data_type, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_name = '{table}'
        ORDER BY ordinal_position
    """)
    rows = cur.fetchall()
    print(f"\n=== {table} ({len(rows)} columns) ===")
    for r in rows:
        print(f"  {r[0]}: {r[1]} (default: {r[2]}, nullable: {r[3]})")

# Check payment_status valid values in sales_orders
print("\n=== Distinct payment_status in sales_orders ===")
cur.execute("SELECT DISTINCT payment_status, COUNT(*) FROM sales_orders GROUP BY payment_status ORDER BY payment_status")
for r in cur.fetchall():
    print(f"  '{r[0]}': {r[1]} orders")

# Check delivery_status valid values
print("\n=== Distinct delivery_status in sales_orders ===")
cur.execute("SELECT DISTINCT delivery_status, COUNT(*) FROM sales_orders GROUP BY delivery_status ORDER BY delivery_status")
for r in cur.fetchall():
    print(f"  '{r[0]}': {r[1]} orders")

# Check status valid values  
print("\n=== Distinct status in sales_orders ===")
cur.execute("SELECT DISTINCT status, COUNT(*) FROM sales_orders GROUP BY status ORDER BY status")
for r in cur.fetchall():
    print(f"  '{r[0]}': {r[1]} orders")

# Check payment_method valid values in customer_payments
print("\n=== Distinct payment_method in customer_payments ===")
cur.execute("SELECT DISTINCT payment_method, COUNT(*) FROM customer_payments GROUP BY payment_method")
for r in cur.fetchall():
    print(f"  '{r[0]}': {r[1]}")

# Check if there are triggers on customer_payments 
print("\n=== Triggers on customer_payments ===")
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement 
    FROM information_schema.triggers 
    WHERE event_object_table = 'customer_payments'
""")
for r in cur.fetchall():
    print(f"  {r[0]} ON {r[1]}: {r[2][:100]}")

# Check v_receivables_aging view columns
print("\n=== v_receivables_aging view columns ===")
cur.execute("""
    SELECT column_name, data_type FROM information_schema.columns 
    WHERE table_name = 'v_receivables_aging' ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

cur.close()
conn.close()
