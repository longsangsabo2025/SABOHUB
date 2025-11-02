import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)

cur = conn.cursor()

print("STORES table:")
cur.execute("SELECT COUNT(*) FROM stores WHERE deleted_at IS NULL")
print(f"  Active records: {cur.fetchone()[0]}")
cur.execute("SELECT COUNT(*) FROM stores WHERE deleted_at IS NOT NULL")
print(f"  Deleted records: {cur.fetchone()[0]}")

print("\nBRANCHES table:")
cur.execute("SELECT COUNT(*) FROM branches")
print(f"  Total records: {cur.fetchone()[0]}")

conn.close()
