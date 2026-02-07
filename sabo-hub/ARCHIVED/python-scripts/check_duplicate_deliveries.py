import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check for duplicate deliveries per order
print("=== CHECKING DUPLICATE DELIVERIES ===")
cur.execute('''
    SELECT order_id, COUNT(*) as cnt 
    FROM deliveries 
    GROUP BY order_id 
    HAVING COUNT(*) > 1
''')
duplicates = cur.fetchall()
if duplicates:
    for row in duplicates:
        print(f"⚠️  Order {row[0]} has {row[1]} delivery records")
else:
    print("✅ No duplicate deliveries found")

# Check all deliveries
print("\n=== ALL DELIVERIES ===")
cur.execute('''
    SELECT d.id, d.order_id, d.status, d.driver_id, so.order_number
    FROM deliveries d
    LEFT JOIN sales_orders so ON so.id = d.order_id
    ORDER BY d.created_at DESC
''')
for row in cur.fetchall():
    print(f"Delivery: {str(row[0])[:8]} | Order: {str(row[1])[:8]} | {row[4]} | Status: {row[2]} | Driver: {str(row[3])[:8] if row[3] else 'None'}")

# Check order SO-260201-53408 specifically (from screenshot)
print("\n=== ORDER SO-260201-53408 DETAILS ===")
cur.execute('''
    SELECT id, order_number, status, delivery_status 
    FROM sales_orders 
    WHERE order_number = 'SO-260201-53408'
''')
order = cur.fetchone()
if order:
    print(f"Order ID: {order[0]}")
    print(f"Status: {order[2]}, Delivery Status: {order[3]}")
    
    cur.execute('''
        SELECT id, status, driver_id, created_at
        FROM deliveries 
        WHERE order_id = %s
    ''', (order[0],))
    deliveries = cur.fetchall()
    print(f"Number of delivery records: {len(deliveries)}")
    for d in deliveries:
        print(f"  - {d[0][:8]} | Status: {d[1]} | Driver: {d[2]} | Created: {d[3]}")

conn.close()
