import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

print('INDEXES:')
cur.execute("SELECT indexname, indexdef FROM pg_indexes WHERE schemaname='public' AND tablename='journey_plans'")
for row in cur.fetchall():
    print(f"- {row[0]} => {row[1]}")

print('\nCONSTRAINTS:')
cur.execute("""
SELECT conname, pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public' AND t.relname = 'journey_plans'
ORDER BY conname
""")
for row in cur.fetchall():
    print(f"- {row[0]} => {row[1]}")

conn.close()
