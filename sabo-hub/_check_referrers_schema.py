import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()
cur.execute("""
    SELECT column_name, data_type, is_nullable, column_default 
    FROM information_schema.columns 
    WHERE table_name = 'referrers' 
    ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(r)

print("\n--- RLS policies ---")
cur.execute("""
    SELECT polname, polcmd, pg_get_expr(polqual, polrelid) as qual, pg_get_expr(polwithcheck, polrelid) as with_check
    FROM pg_policy 
    WHERE polrelid = 'referrers'::regclass
""")
for r in cur.fetchall():
    print(r)

conn.close()
