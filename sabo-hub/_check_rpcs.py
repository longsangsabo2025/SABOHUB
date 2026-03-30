import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'start_delivery'")
row = cur.fetchone()
if row: print('start_delivery src:\n', row[0][:3000])
# Also check if start_delivery updates sales_orders
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery'")
row = cur.fetchone()
if row: print('\ncomplete_delivery src:\n', row[0][:2000])
# Check sales_order_history RLS
cur.execute("SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'sales_order_history'")
rows = cur.fetchall()
print('\nsales_order_history RLS:')
for r in rows: print(f'  {r[0]} {r[1]}: {str(r[2])[:200]}')
cur.close(); conn.close()
print('done')
