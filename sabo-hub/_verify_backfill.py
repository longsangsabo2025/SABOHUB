import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123')
cur = conn.cursor()
cur.execute("SELECT id, amount, payment_date, payment_method, notes, created_at FROM customer_payments WHERE customer_id = 'd414a0c7-81be-44e9-899a-2b4808eb5bf7' ORDER BY payment_date DESC")
cols = [d[0] for d in cur.description]
for r in cur.fetchall():
    print(dict(zip(cols, r)))

# Also verify no more missing cash payments
cur.execute("""
SELECT COUNT(*) FROM sales_orders so
WHERE so.payment_status = 'paid' AND so.payment_method = 'cash'
  AND so.delivery_status = 'delivered' AND so.status = 'completed'
  AND so.rejected_at IS NULL AND so.total > 0
  AND NOT EXISTS (
    SELECT 1 FROM customer_payments cp 
    WHERE cp.customer_id = so.customer_id
      AND cp.amount = so.total AND cp.payment_method = 'cash'
      AND cp.notes LIKE '%%' || so.order_number || '%%'
  )
""")
missing = cur.fetchone()[0]
print(f"\nRemaining missing cash payments: {missing}")
conn.close()
