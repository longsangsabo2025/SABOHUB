import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Fix: orders with status=completed but delivery_status still delivering
cur.execute("""
    UPDATE sales_orders 
    SET delivery_status = 'delivered' 
    WHERE status = 'completed' AND delivery_status = 'delivering'
""")
print(f"Updated {cur.rowcount} orders: delivering -> delivered")

# Also fix: orders with status=completed but delivery_status still pending or awaiting_pickup
cur.execute("""
    UPDATE sales_orders 
    SET delivery_status = 'delivered' 
    WHERE status = 'completed' AND delivery_status IN ('pending', 'awaiting_pickup')
""")
print(f"Updated {cur.rowcount} orders: pending/awaiting_pickup -> delivered (completed orders)")

conn.commit()

# Verify
cur.execute("""
    SELECT delivery_status, COUNT(*) 
    FROM sales_orders 
    GROUP BY delivery_status
    ORDER BY delivery_status
""")
print("\n=== Updated Distribution ===")
for r in cur.fetchall():
    print(f"{r[0]}: {r[1]}")

cur.close()
conn.close()
