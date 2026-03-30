import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("""
select column_name from information_schema.columns
where table_schema='public' and table_name='receivables'
order by ordinal_position;
""")
print([r[0] for r in cur.fetchall()])
cur.close(); conn.close()
