import psycopg2
from datetime import datetime, timedelta

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Find all completed cash orders that DON'T have a matching customer_payments record
cur.execute("""
SELECT 
    so.id, so.order_number, so.total, so.customer_id, so.customer_name,
    so.payment_status, so.payment_method, so.payment_collected_at, so.created_at,
    so.company_id,
    d.completed_at as delivery_completed_at
FROM sales_orders so
LEFT JOIN deliveries d ON d.order_id = so.id AND d.status = 'completed'
WHERE so.payment_status = 'paid'
  AND so.payment_method = 'cash'
  AND so.delivery_status = 'delivered'
  AND so.status = 'completed'
  AND so.rejected_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM customer_payments cp 
    WHERE cp.customer_id = so.customer_id
      AND cp.amount = so.total
      AND cp.payment_method = 'cash'
      AND cp.notes LIKE '%' || so.order_number || '%'
  )
ORDER BY so.created_at DESC
""")

rows = cur.fetchall()
cols = [d[0] for d in cur.description]
print(f"=== CASH ORDERS WITHOUT customer_payments RECORD ({len(rows)} found) ===")
for r in rows:
    d = dict(zip(cols, r))
    print(f"  {d['order_number']} | {d['total']} | {d['customer_name']} | created: {d['created_at']} | delivered: {d['delivery_completed_at']}")

conn.close()
