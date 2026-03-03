import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check the constraint definition
cur.execute("""
    SELECT conname, pg_get_constraintdef(c.oid) 
    FROM pg_constraint c 
    WHERE conrelid = 'sales_orders'::regclass 
    AND contype = 'c'
""")
rows = cur.fetchall()
for r in rows:
    print(f"Constraint: {r[0]}")
    print(f"Definition: {r[1]}")
    print()

# Also check column definition
cur.execute("""
    SELECT column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'sales_orders' AND column_name = 'delivery_status'
""")
cols = cur.fetchall()
for c in cols:
    print(f"Column: {c[0]}, Type: {c[1]}, Default: {c[2]}")

cur.close()
conn.close()
