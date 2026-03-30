import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()
cur.execute("SELECT order_number, status, delivery_status FROM sales_orders WHERE order_number IN ('SO-260306-71019','SO-260313-12281')")
for r in cur.fetchall(): print(r)
cur.execute("SELECT count(*) FROM sales_orders WHERE status='ready' AND delivery_status='pending'")
print('Remaining stuck orders:', cur.fetchone()[0])
cur.close()
conn.close()
