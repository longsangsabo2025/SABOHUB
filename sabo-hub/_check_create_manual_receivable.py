import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("""
select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where p.proname = 'create_manual_receivable'
order by 1,2;
""")
rows = cur.fetchall()
print(rows)
cur.close(); conn.close()
