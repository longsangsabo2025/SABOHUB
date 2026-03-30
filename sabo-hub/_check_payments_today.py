import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Check customer_payments from today
print("=== customer_payments today (2026-03-29) ===")
cur.execute("""
    SELECT cp.id, cp.payment_date, cp.amount, cp.payment_method, cp.notes, c.name as customer_name
    FROM customer_payments cp
    LEFT JOIN customers c ON cp.customer_id = c.id
    WHERE cp.payment_date >= '2026-03-29'
    ORDER BY cp.payment_date DESC
    LIMIT 20
""")
for r in cur.fetchall():
    print(r)

# 2. Check if there are recent payments at all
print("\n=== Last 10 customer_payments ===")
cur.execute("""
    SELECT cp.id, cp.payment_date, cp.amount, cp.payment_method, c.name as customer_name
    FROM customer_payments cp
    LEFT JOIN customers c ON cp.customer_id = c.id
    ORDER BY cp.payment_date DESC
    LIMIT 10
""")
for r in cur.fetchall():
    print(r)

# 3. Check today's delivered orders
print("\n=== sales_orders delivered today ===")
cur.execute("""
    SELECT id, order_number, customer_name, total, payment_status, payment_method, delivery_status
    FROM sales_orders
    WHERE order_date >= '2026-03-29' AND delivery_status IN ('delivered', 'completed')
    ORDER BY created_at DESC
    LIMIT 10
""")
for r in cur.fetchall():
    print(r)

# 4. Check today's orders in general
print("\n=== All sales_orders today ===")
cur.execute("""
    SELECT id, order_number, customer_name, total, payment_status, payment_method, status, delivery_status
    FROM sales_orders
    WHERE order_date >= '2026-03-29'
    ORDER BY created_at DESC
    LIMIT 15
""")
for r in cur.fetchall():
    print(r)

# 5. Check customer_payments schema
print("\n=== customer_payments schema ===")
cur.execute("""
    SELECT column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'customer_payments'
    ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(r)

conn.close()
