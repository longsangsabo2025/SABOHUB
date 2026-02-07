import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
cur = conn.cursor()
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery_debt'")
body = cur.fetchone()[0]
print(body)
cur.close()
conn.close()
