import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check address-related columns in sales_orders
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'sales_orders' 
    AND (column_name LIKE '%address%' OR column_name LIKE '%lat%' OR column_name LIKE '%lng%' OR column_name LIKE '%delivery%')
    ORDER BY column_name
""")
print("=== Address/delivery columns in sales_orders ===")
for r in cur.fetchall():
    print(r[0])

# Check the two orders
cur.execute("""
    SELECT so.order_number, so.delivery_address, so.customer_name,
           c.name, c.address as customer_address, c.lat, c.lng
    FROM sales_orders so
    LEFT JOIN customers c ON c.id = so.customer_id
    WHERE so.order_number IN ('SO-260208-60127', 'SO-260208-59381')
    ORDER BY so.order_number
""")
print("\n=== Orders with addresses ===")
for r in cur.fetchall():
    print(f"Order: {r[0]}")
    print(f"  so.delivery_address: {r[1]}")
    print(f"  so.customer_name: {r[2]}")
    print(f"  customer.name: {r[3]}")
    print(f"  customer.address: {r[4]}")
    print(f"  customer.lat/lng: {r[5]}, {r[6]}")
    print()

# Check deliveries table for these orders
cur.execute("""
    SELECT d.delivery_number, d.order_id, d.status, d.delivery_address,
           so.order_number
    FROM deliveries d
    JOIN sales_orders so ON so.id = d.order_id
    WHERE so.order_number IN ('SO-260208-60127', 'SO-260208-59381')
""")
print("=== Deliveries ===")
for r in cur.fetchall():
    print(f"Delivery: {r[0]}, order: {r[4]}, status: {r[2]}, delivery_address: {r[3]}")

cur.close()
conn.close()
