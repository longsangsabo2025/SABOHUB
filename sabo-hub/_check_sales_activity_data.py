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

print('=== STORE VISITS TODAY BY EMPLOYEE ===')
cur.execute("""
SELECT employee_id, COUNT(*), MIN(check_in_time), MAX(check_in_time)
FROM store_visits
WHERE visit_date >= '2026-03-25' AND visit_date < '2026-03-26'
GROUP BY employee_id
ORDER BY COUNT(*) DESC
""")
for row in cur.fetchall():
    print(row)

print('\n=== SALES ORDERS TODAY BY sale_id ===')
cur.execute("""
SELECT sale_id, COUNT(*), SUM(total)
FROM sales_orders
WHERE created_at >= '2026-03-25' AND created_at < '2026-03-26'
GROUP BY sale_id
ORDER BY COUNT(*) DESC
""")
for row in cur.fetchall():
    print(row)

print('\n=== PRODUCT SAMPLES TODAY BY sent_by_id ===')
cur.execute("""
SELECT sent_by_id, COUNT(*)
FROM product_samples
WHERE sent_date >= '2026-03-25' AND sent_date < '2026-03-26'
GROUP BY sent_by_id
ORDER BY COUNT(*) DESC
""")
for row in cur.fetchall():
    print(row)

print('\n=== STORE VISIT PHOTOS TODAY BY uploaded_by ===')
cur.execute("""
SELECT uploaded_by, COUNT(*)
FROM store_visit_photos
WHERE taken_at >= '2026-03-25' AND taken_at < '2026-03-26'
GROUP BY uploaded_by
ORDER BY COUNT(*) DESC
""")
for row in cur.fetchall():
    print(row)

print('\n=== SURVEY RESPONSES TODAY BY respondent_id ===')
cur.execute("""
SELECT respondent_id, COUNT(*)
FROM survey_responses
WHERE created_at >= '2026-03-25' AND created_at < '2026-03-26'
GROUP BY respondent_id
ORDER BY COUNT(*) DESC
""")
for row in cur.fetchall():
    print(row)

print('\n=== RECENT SAMPLE ROWS TODAY ===')
cur.execute("""
SELECT id, sent_by_id, customer_id, product_name, sent_date, created_at, status
FROM product_samples
WHERE sent_date >= '2026-03-25' AND sent_date < '2026-03-26'
ORDER BY created_at DESC
LIMIT 10
""")
for row in cur.fetchall():
    print(row)

print('\n=== RECENT ORDERS TODAY ===')
cur.execute("""
SELECT id, sale_id, order_number, total, created_at, status
FROM sales_orders
WHERE created_at >= '2026-03-25' AND created_at < '2026-03-26'
ORDER BY created_at DESC
LIMIT 10
""")
for row in cur.fetchall():
    print(row)

print('\n=== RECENT STORE VISITS TODAY ===')
cur.execute("""
SELECT id, employee_id, customer_id, visit_date, check_in_time, check_out_time, status
FROM store_visits
WHERE visit_date >= '2026-03-25' AND visit_date < '2026-03-26'
ORDER BY check_in_time DESC NULLS LAST
LIMIT 10
""")
for row in cur.fetchall():
    print(row)

conn.close()
