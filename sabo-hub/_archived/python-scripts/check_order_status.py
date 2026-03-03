import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check 2 specific orders
cur.execute("""
    SELECT order_number, delivery_status, payment_status, status, total
    FROM sales_orders
    WHERE order_number IN ('SO-260205-29567', 'SO-260204-28398')
    ORDER BY order_number
""")
rows = cur.fetchall()
print("=== Specific Orders ===")
for r in rows:
    print(f"Order: {r[0]}, delivery_status: {r[1]}, payment_status: {r[2]}, status: {r[3]}, total: {r[4]}")

# Count delivery_status distribution
cur.execute("""
    SELECT delivery_status, COUNT(*) 
    FROM sales_orders 
    GROUP BY delivery_status
    ORDER BY delivery_status
""")
print("\n=== Delivery Status Distribution ===")
for r in cur.fetchall():
    print(f"{r[0]}: {r[1]}")

# Check orders with delivery_status='delivering' that have deliveries already completed
cur.execute("""
    SELECT so.order_number, so.delivery_status, so.payment_status, so.status,
           d.status as delivery_actual_status, d.completed_at
    FROM sales_orders so
    LEFT JOIN deliveries d ON d.order_id = so.id
    WHERE so.delivery_status = 'delivering'
    ORDER BY so.created_at DESC
    LIMIT 20
""")
print("\n=== Orders with delivery_status='delivering' ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, so.delivery_status: {r[1]}, payment: {r[2]}, so.status: {r[3]}, delivery_actual: {r[4]}, completed_at: {r[5]}")

cur.close()
conn.close()
