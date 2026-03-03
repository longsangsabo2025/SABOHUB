import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Drop old constraint and add new one with all valid values
cur.execute("""
    ALTER TABLE sales_orders DROP CONSTRAINT IF EXISTS sales_orders_delivery_status_check;
""")

cur.execute("""
    ALTER TABLE sales_orders ADD CONSTRAINT sales_orders_delivery_status_check 
    CHECK (delivery_status IN ('pending', 'awaiting_pickup', 'driver_accepted', 'delivering', 'delivered'));
""")

conn.commit()

# Verify
cur.execute("""
    SELECT conname, pg_get_constraintdef(c.oid) 
    FROM pg_constraint c 
    WHERE conrelid = 'sales_orders'::regclass AND conname = 'sales_orders_delivery_status_check'
""")
for r in cur.fetchall():
    print(f"Constraint: {r[0]}")
    print(f"Definition: {r[1]}")

cur.close()
conn.close()
print("\nDone! Constraint updated.")
