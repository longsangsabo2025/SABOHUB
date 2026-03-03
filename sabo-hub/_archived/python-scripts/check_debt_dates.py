import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()
cur.execute("""
    SELECT order_number, delivery_date, created_at, order_date
    FROM sales_orders 
    WHERE order_number IN ('SO-260204-04609', 'SO-260204-56990')
    ORDER BY order_number
""")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_date: {r[1]}, created_at: {r[2]}, order_date: {r[3]}")

# Check all unpaid orders - verify delivery_date vs created_at range
cur.execute("""
    SELECT order_number, delivery_date, created_at, order_date, payment_status
    FROM sales_orders 
    WHERE payment_status IN ('unpaid', 'debt') AND status != 'cancelled'
    ORDER BY created_at DESC
    LIMIT 20
""")
print("\n=== Recent unpaid orders ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_date: {r[1]}, created_at: {r[2]}, order_date: {r[3]}, payment: {r[4]}")

cur.close()
conn.close()
