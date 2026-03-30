import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("""
select id, company_id, name, code, total_debt from customers
where code='gsacat' order by updated_at desc nulls last limit 1;
""")
c = cur.fetchone()
print('customer=', c)
if c:
    cid, company_id, *_ = c
    cur.execute("""
    select id, order_number, total, paid_amount, payment_status, status, created_at
    from sales_orders
    where customer_id=%s and company_id=%s
    order by created_at desc limit 20;
    """, (cid, company_id))
    rows = cur.fetchall()
    print('sales_orders count=', len(rows))
    for r in rows[:10]:
        print('SO', r)

    cur.execute("""
    select id, reference_type, reference_number, original_amount, paid_amount, remaining_amount, status, created_at, invoice_date, due_date
    from receivables
    where customer_id=%s and company_id=%s
    order by created_at desc limit 20;
    """, (cid, company_id))
    recs = cur.fetchall()
    print('receivables count=', len(recs))
    for r in recs[:10]:
        print('RCV', r)

cur.close(); conn.close()
