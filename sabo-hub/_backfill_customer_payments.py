"""
Backfill customer_payments records for historical cash orders that were completed
via driver_deliveries_page._completeDelivery() BEFORE the fix was deployed.

These orders have:
- payment_status = 'paid'
- payment_method = 'cash'  
- delivery_status = 'delivered'
- status = 'completed'
- NO matching customer_payments record

This script only inserts records for orders with total > 0.
"""
import psycopg2
from datetime import datetime

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Find all completed cash orders missing customer_payments
cur.execute("""
SELECT 
    so.id, so.order_number, so.total, so.customer_id, so.customer_name,
    so.company_id, so.payment_collected_at, so.created_at,
    d.completed_at as delivery_completed_at,
    d.driver_id
FROM sales_orders so
LEFT JOIN deliveries d ON d.order_id = so.id AND d.status = 'completed'
WHERE so.payment_status = 'paid'
  AND so.payment_method = 'cash'
  AND so.delivery_status = 'delivered'
  AND so.status = 'completed'
  AND so.rejected_at IS NULL
  AND so.total > 0
  AND NOT EXISTS (
    SELECT 1 FROM customer_payments cp 
    WHERE cp.customer_id = so.customer_id
      AND cp.amount = so.total
      AND cp.payment_method = 'cash'
      AND cp.notes LIKE '%%' || so.order_number || '%%'
  )
ORDER BY so.created_at ASC
""")

rows = cur.fetchall()
cols = [d[0] for d in cur.description]
orders = [dict(zip(cols, r)) for r in rows]

print(f"Found {len(orders)} cash orders with total > 0 missing customer_payments records")
print()

inserted = 0
skipped = 0
errors = 0

for o in orders:
    # Use delivery_completed_at or payment_collected_at as payment_date
    payment_date = o['delivery_completed_at'] or o['payment_collected_at'] or o['created_at']
    
    if o['customer_id'] is None:
        print(f"  SKIP {o['order_number']}: no customer_id")
        skipped += 1
        continue
    
    try:
        cur.execute("""
        INSERT INTO customer_payments (company_id, customer_id, amount, payment_date, payment_method, created_by, notes)
        VALUES (%s, %s, %s, %s, 'cash', %s, %s)
        """, (
            o['company_id'],
            o['customer_id'],
            o['total'],
            payment_date,
            o['driver_id'],  # created_by = driver who completed delivery
            f"Thu tiền mặt khi giao hàng - {o['order_number']} (backfill)",
        ))
        inserted += 1
        print(f"  INSERT {o['order_number']} | {o['total']:>12,.0f}đ | {o['customer_name']}")
    except Exception as e:
        print(f"  ERROR {o['order_number']}: {e}")
        errors += 1
        conn.rollback()

conn.commit()
print(f"\nDone: {inserted} inserted, {skipped} skipped, {errors} errors")
conn.close()
