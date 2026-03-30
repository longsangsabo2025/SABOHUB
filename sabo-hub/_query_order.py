import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# 1. Find the specific order
cur.execute("""
SELECT id, order_number, total, payment_status, payment_method, delivery_status, status, customer_name, rejected_at, created_at
FROM sales_orders 
WHERE order_number ILIKE '%%31412%%'
""")
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
print("=== ORDER SO-260326-31412 ===")
for r in rows:
    d = dict(zip(cols, r))
    for k, v in d.items():
        print(f"  {k}: {v}")
    order_id = d['id']

# 2. Thao Nhi recent orders
print("\n=== THAO NHI ORDERS (from 25/3) ===")
cur.execute("""
SELECT id, order_number, total, payment_status, payment_method, delivery_status, status, customer_name, created_at
FROM sales_orders 
WHERE customer_name ILIKE '%%Th%%o Nhi%%' AND created_at >= '2026-03-25'
ORDER BY created_at DESC LIMIT 10
""")
rows2 = cur.fetchall()
cols2 = [d[0] for d in cur.description]
for r in rows2:
    d = dict(zip(cols2, r))
    print(f"  {d['order_number']} | {d['total']} | pay:{d['payment_status']} | method:{d['payment_method']} | del:{d['delivery_status']} | status:{d['status']}")

# 3. Check deliveries for this order
print("\n=== DELIVERIES FOR ORDER ===")
cur.execute("""
SELECT d.id, d.order_id, d.driver_id, d.status, d.completed_at, d.created_at
FROM deliveries d
WHERE d.order_id = %s
""", (order_id,))
rows3 = cur.fetchall()
cols3 = [d[0] for d in cur.description]
for r in rows3:
    d = dict(zip(cols3, r))
    for k, v in d.items():
        print(f"  {k}: {v}")

# 4. Check schemas of payment-related tables
print("\n=== TABLE SCHEMAS ===")
for tname in ['receivables', 'payments', 'customer_payments']:
    cur.execute("""
    SELECT column_name, data_type FROM information_schema.columns 
    WHERE table_schema='public' AND table_name=%s ORDER BY ordinal_position
    """, (tname,))
    print(f"\n  --- {tname} ---")
    for r in cur.fetchall():
        print(f"    {r[0]}: {r[1]}")

# 5. Check receivables for this order (using reference_id)
print("\n=== RECEIVABLES (by reference_id) ===")
cur.execute("SELECT * FROM receivables WHERE reference_id = %s", (order_id,))
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
for r in rows:
    d = dict(zip(cols, r))
    for k, v in d.items():
        print(f"  {k}: {v}")
if not rows:
    print("  (no records)")

# 6. Get customer_id from order
cur.execute("SELECT customer_id FROM sales_orders WHERE id = %s", (order_id,))
customer_id = cur.fetchone()[0]
print(f"\n  customer_id: {customer_id}")

# 7. Check payments for this customer around 26/3
print("\n=== PAYMENTS for customer around 26/3 ===")
cur.execute("""
SELECT id, payment_number, payment_date, amount, payment_method, status, notes, created_at
FROM payments WHERE customer_id = %s AND payment_date >= '2026-03-25' AND payment_date <= '2026-03-30'
ORDER BY payment_date
""", (customer_id,))
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
for r in rows:
    d = dict(zip(cols, r))
    print(f"  {d}")
if not rows:
    print("  (no records)")

# 8. Check customer_payments for this customer around 26/3
print("\n=== CUSTOMER_PAYMENTS for customer around 26/3 ===")
cur.execute("""
SELECT id, amount, payment_date, payment_method, reference, notes, created_at
FROM customer_payments WHERE customer_id = %s AND payment_date >= '2026-03-25' AND payment_date <= '2026-03-30'
ORDER BY payment_date
""", (customer_id,))
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
for r in rows:
    d = dict(zip(cols, r))
    print(f"  {d}")
if not rows:
    print("  (no records)")

# 9. Check payment_allocations
print("\n=== PAYMENT_ALLOCATIONS schema ===")
cur.execute("""
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_schema='public' AND table_name='payment_allocations' ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# 10. All payments for this customer (recent)
print("\n=== ALL PAYMENTS for customer (recent) ===")
cur.execute("""
SELECT id, payment_number, payment_date, amount, payment_method, status, created_at
FROM payments WHERE customer_id = %s ORDER BY payment_date DESC LIMIT 10
""", (customer_id,))
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
for r in rows:
    d = dict(zip(cols, r))
    print(f"  {d}")
if not rows:
    print("  (no records)")

# 11. All customer_payments for this customer (recent)
print("\n=== ALL CUSTOMER_PAYMENTS for customer (recent) ===")
cur.execute("""
SELECT id, amount, payment_date, payment_method, reference, notes, created_at
FROM customer_payments WHERE customer_id = %s ORDER BY payment_date DESC LIMIT 10
""", (customer_id,))
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
for r in rows:
    d = dict(zip(cols, r))
    print(f"  {d}")
if not rows:
    print("  (no records)")


rows4 = cur.fetchall()
cols4 = [d[0] for d in cur.description]
for r in rows4:
    d = dict(zip(cols4, r))
    for k, v in d.items():
        print(f"  {k}: {v}")

# 5. Check if there's a payments table
print("\n=== CHECK PAYMENTS TABLE ===")
cur.execute("""
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE '%%payment%%'
""")
for r in cur.fetchall():
    print(f"  table: {r[0]}")

cur.execute("""
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE '%%transaction%%'
""")
for r in cur.fetchall():
    print(f"  table: {r[0]}")

conn.close()
