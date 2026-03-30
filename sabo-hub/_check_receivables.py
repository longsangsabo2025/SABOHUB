import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()
cur.execute("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'receivables' ORDER BY ordinal_position")
for r in cur.fetchall():
    print(f'  {r[0]:30s} {r[1]:20s} nullable={r[2]} default={r[3]}')
cur.execute('SELECT COUNT(*) FROM receivables')
print(f'Total receivables: {cur.fetchone()[0]}')
cur.execute("SELECT status, COUNT(*) FROM receivables GROUP BY status")
for r in cur.fetchall():
    print(f'  status={r[0]}: {r[1]}')
# Try to select balance - see if it's a generated column or view
try:
    cur.execute("SELECT balance FROM receivables LIMIT 1")
    print(f"balance column works: {cur.fetchone()}")
except Exception as e:
    print(f"balance column ERROR: {e}")
conn.close()
