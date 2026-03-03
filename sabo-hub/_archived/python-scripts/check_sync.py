import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Current delivery_status distribution
cur.execute("""
    SELECT delivery_status, status, COUNT(*) 
    FROM sales_orders 
    GROUP BY delivery_status, status
    ORDER BY delivery_status, status
""")
print("=== delivery_status vs status ===")
for r in cur.fetchall():
    print(f"delivery_status={r[0]}, status={r[1]}: {r[2]}")

# Check orders that are 'delivering' still
cur.execute("""
    SELECT so.order_number, so.delivery_status, so.payment_status, so.status,
           d.status as d_status, d.completed_at, so.created_at
    FROM sales_orders so
    LEFT JOIN deliveries d ON d.order_id = so.id
    WHERE so.delivery_status != 'delivered'
    ORDER BY so.created_at DESC
""")
print("\n=== Non-delivered orders ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_status: {r[1]}, payment: {r[2]}, status: {r[3]}, d_status: {r[4]}, d_completed: {r[5]}, created: {r[6]}")

# Check SO-260204-14327 specifically
cur.execute("""
    SELECT so.order_number, so.delivery_status, so.payment_status, so.status,
           d.status as d_status, d.completed_at
    FROM sales_orders so
    LEFT JOIN deliveries d ON d.order_id = so.id
    WHERE so.order_number = 'SO-260204-14327'
""")
print("\n=== SO-260204-14327 ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_status: {r[1]}, payment: {r[2]}, status: {r[3]}, d_status: {r[4]}, d_completed: {r[5]}")

# Check SO-260204-30580
cur.execute("""
    SELECT so.order_number, so.delivery_status, so.payment_status, so.status,
           d.status as d_status, d.completed_at
    FROM sales_orders so
    LEFT JOIN deliveries d ON d.order_id = so.id
    WHERE so.order_number = 'SO-260204-30580'
""")
print("\n=== SO-260204-30580 ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_status: {r[1]}, payment: {r[2]}, status: {r[3]}, d_status: {r[4]}, d_completed: {r[5]}")

cur.close()
conn.close()
