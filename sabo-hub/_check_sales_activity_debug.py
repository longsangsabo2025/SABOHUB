import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

print('=== EMPLOYEES FOR TODAY ACTIVITY IDS ===')
cur.execute("""
SELECT id, full_name, role, company_id
FROM employees
WHERE id IN (
  '0673afdd-56c5-4bd1-b15b-70a36b951cea',
  '2b0fddce-e809-4780-86fa-8e45f320ebb0'
)
ORDER BY full_name
""")
for row in cur.fetchall():
    print(row)

print('\n=== PRODUCT_SAMPLES TABLE COLUMNS ===')
cur.execute("""
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'product_samples'
ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(row)

print('\n=== SAMPLE COUNT FOR EACH FILTER STYLE ===')
queries = [
    ("sent_date >= '2026-03-25' AND sent_date < '2026-03-26'", "SELECT COUNT(*) FROM product_samples WHERE sent_date >= '2026-03-25' AND sent_date < '2026-03-26'"),
    ("sent_date::date = '2026-03-25'", "SELECT COUNT(*) FROM product_samples WHERE sent_date::date = '2026-03-25'"),
    ("created_at >= '2026-03-25' AND created_at < '2026-03-26'", "SELECT COUNT(*) FROM product_samples WHERE created_at >= '2026-03-25' AND created_at < '2026-03-26'"),
    ("sent_by_id=2b0... and sent_date range", "SELECT COUNT(*) FROM product_samples WHERE sent_by_id = '2b0fddce-e809-4780-86fa-8e45f320ebb0' AND sent_date >= '2026-03-25' AND sent_date < '2026-03-26'"),
    ("sent_by_id=2b0... and created_at range", "SELECT COUNT(*) FROM product_samples WHERE sent_by_id = '2b0fddce-e809-4780-86fa-8e45f320ebb0' AND created_at >= '2026-03-25' AND created_at < '2026-03-26'"),
]
for label, query in queries:
    cur.execute(query)
    print(label, '=>', cur.fetchone()[0])

print('\n=== DIRECT SELECT USED BY PAGE FOR SAMPLES ===')
cur.execute("""
SELECT id, status, sent_date, quantity, unit, product_name, customer_id, sent_by_id
FROM product_samples
WHERE sent_by_id = '2b0fddce-e809-4780-86fa-8e45f320ebb0'
  AND sent_date >= '2026-03-25'
  AND sent_date <= '2026-03-26'
ORDER BY created_at DESC
""")
for row in cur.fetchall():
    print(row)

conn.close()
