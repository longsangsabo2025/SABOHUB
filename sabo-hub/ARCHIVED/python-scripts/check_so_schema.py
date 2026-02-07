import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
cur = conn.cursor()
cur.execute("""
    SELECT column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'sales_orders'
    ORDER BY ordinal_position
""")
print("=== sales_orders columns ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} (default: {r[2]})")

cur.close()
conn.close()
