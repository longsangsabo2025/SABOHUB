import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("""
select id, company_id from customers where code='gsacat' limit 1;
""")
cid, company_id = cur.fetchone()
cur.execute("""
select count(*), coalesce(sum(total - coalesce(paid_amount,0)),0)
from sales_orders
where customer_id=%s and company_id=%s and payment_status <> 'paid' and status <> 'cancelled';
""", (cid, company_id))
print('sales_orders_unpaid_count,sum_remaining=', cur.fetchone())
cur.execute("""
select count(*), coalesce(sum(original_amount - coalesce(paid_amount,0) - coalesce(write_off_amount,0)),0)
from receivables
where customer_id=%s and company_id=%s
and (original_amount - coalesce(paid_amount,0) - coalesce(write_off_amount,0)) > 0;
""", (cid, company_id))
print('receivables_unpaid_count,sum_remaining=', cur.fetchone())
cur.close(); conn.close()
