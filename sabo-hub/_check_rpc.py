import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery_transfer'")
r = cur.fetchone()
if r:
    print(r[0])
else:
    print('NOT FOUND')
conn.close()
