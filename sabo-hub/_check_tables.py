import psycopg2
c = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543,
    dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = c.cursor()
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND (table_name LIKE '%%business%%' OR table_name LIKE '%%compan%%' OR table_name LIKE '%%branch%%') ORDER BY 1")
for r in cur.fetchall():
    print(r[0])
cur.close()
c.close()
