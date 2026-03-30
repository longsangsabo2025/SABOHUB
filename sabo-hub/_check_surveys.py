import psycopg2
conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()
cur.execute("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name='surveys' ORDER BY ordinal_position")
print("=== surveys ===")
for r in cur.fetchall():
    print(r)

print("\n=== survey_responses ===")
cur.execute("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name='survey_responses' ORDER BY ordinal_position")
for r in cur.fetchall():
    print(r)

print("\n=== existing surveys count ===")
cur.execute("SELECT count(*) FROM surveys")
print(cur.fetchone())

print("\n=== check constraints ===")
cur.execute("SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE conrelid='surveys'::regclass AND contype='c'")
for r in cur.fetchall():
    print(r)

conn.close()
