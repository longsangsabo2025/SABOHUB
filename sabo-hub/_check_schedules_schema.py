import psycopg2
conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543, dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123', sslmode='require'
)
cur = conn.cursor()
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'schedules' ORDER BY ordinal_position")
for r in cur.fetchall():
    print(r)
conn.close()
