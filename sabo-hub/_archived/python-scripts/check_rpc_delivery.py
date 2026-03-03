import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check complete_delivery RPC
cur.execute("""
    SELECT routine_name, routine_definition
    FROM information_schema.routines
    WHERE routine_name IN ('complete_delivery', 'start_delivery', 'complete_delivery_transfer')
    AND routine_schema = 'public'
""")
for r in cur.fetchall():
    print(f"\n=== {r[0]} ===")
    print(r[1])

cur.close()
conn.close()
