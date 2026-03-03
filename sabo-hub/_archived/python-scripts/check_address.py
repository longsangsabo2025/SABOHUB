import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check the two orders and their customer address vs order address
cur.execute("""
    SELECT so.order_number, so.delivery_address, so.customer_name, so.address,
           c.name, c.address as customer_address, c.lat, c.lng
    FROM sales_orders so
    LEFT JOIN customers c ON c.id = so.customer_id
    WHERE so.order_number IN ('SO-260208-60127', 'SO-260208-59381')
    ORDER BY so.order_number
""")
print("=== Orders with addresses ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}")
    print(f"  so.delivery_address: {r[1]}")
    print(f"  so.customer_name: {r[2]}")
    print(f"  so.address: {r[3]}")
    print(f"  customer.name: {r[4]}")
    print(f"  customer.address: {r[5]}")
    print(f"  customer.lat/lng: {r[6]}, {r[7]}")
    print()

# Check sales_orders columns related to address
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' 
    AND column_name LIKE '%address%' OR column_name LIKE '%lat%' OR column_name LIKE '%lng%'
    ORDER BY column_name
""")
print("=== Address columns in sales_orders ===")
for r in cur.fetchall():
    print(r[0])

cur.close()
conn.close()
