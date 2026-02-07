import psycopg2
import os
from dotenv import load_dotenv

load_dotenv('sabohub-app/SABOHUB/.env')
conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_str)
cur = conn.cursor()

# Check CHECK constraints on deliveries
print("CHECK CONSTRAINTS ON deliveries:")
cur.execute("""
    SELECT con.conname, pg_get_constraintdef(con.oid)
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE rel.relname = 'deliveries' AND nsp.nspname = 'public' AND con.contype = 'c'
""")
checks = cur.fetchall()
if checks:
    for r in checks:
        print(f"  {r[0]}: {r[1]}")
else:
    print("  No CHECK constraints")

# Check if 'loading' and 'planned' are valid statuses
print("\nDelivery statuses in code: planned, loading, in_progress, completed")
print("Deliveries by status:")
cur.execute("SELECT status, COUNT(*) FROM deliveries GROUP BY status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# Check delivery_items data
print("\nDELIVERY_ITEMS sample:")
cur.execute("SELECT COUNT(*) FROM delivery_items")
print(f"  Total rows: {cur.fetchone()[0]}")
cur.execute("SELECT status, COUNT(*) FROM delivery_items GROUP BY status ORDER BY count DESC")
for r in cur.fetchall():
    print(f"  status={r[0]}: {r[1]}")

# Check if sales_orders has delivery_address column
print("\nSALES_ORDERS - delivery_address column:")
cur.execute("""
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'sales_orders' AND column_name = 'delivery_address'
""")
r = cur.fetchone()
print(f"  exists: {bool(r)}")

cur.close()
conn.close()
