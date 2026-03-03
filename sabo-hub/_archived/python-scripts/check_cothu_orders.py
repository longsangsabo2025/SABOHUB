import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Find orders for customer "Cô Thu Phạm Văn Chí"
cur.execute("""
    SELECT so.order_number, so.delivery_date, so.created_at, so.order_date, 
           so.total, so.payment_status, so.paid_amount,
           c.name
    FROM sales_orders so
    JOIN customers c ON c.id = so.customer_id
    WHERE c.name ILIKE '%thu%phạm%' OR c.name ILIKE '%cô thu%'
    ORDER BY so.created_at DESC
""")
print("=== Orders for Cô Thu ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}, delivery_date: {r[1]}, created_at: {r[2]}, order_date: {r[3]}, total: {r[4]}, payment: {r[5]}, paid: {r[6]}, customer: {r[7]}")

cur.close()
conn.close()
