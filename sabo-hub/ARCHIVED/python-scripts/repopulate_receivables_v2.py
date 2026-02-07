"""
Re-populate receivables for all delivered orders
"""
import psycopg2
from datetime import datetime, timedelta

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# Check customer_payments columns first
print("=== customer_payments columns ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'customer_payments' ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}")

# Check delivered orders without receivables
print("\n=== Delivered orders without receivables ===")
cur.execute("""
    SELECT so.id, so.order_number, so.customer_id, so.total, so.delivery_date,
           so.due_date, so.company_id, so.status, so.delivery_status,
           c.name as customer_name
    FROM sales_orders so
    JOIN customers c ON c.id = so.customer_id
    WHERE so.delivery_status = 'delivered'
      AND so.total > 0
      AND NOT EXISTS (
          SELECT 1 FROM receivables r WHERE r.reference_id = so.id
      )
    ORDER BY so.delivery_date DESC NULLS LAST
""")
orders = cur.fetchall()
print(f"  Found {len(orders)} delivered orders missing receivables")

today = datetime.now().date()
created = 0
overdue_count = 0

for o in orders:
    order_id, order_number, customer_id, total = o[0], o[1], o[2], o[3]
    delivery_date, due_date, company_id = o[4], o[5], o[6]
    
    # Calculate dates
    invoice_date = delivery_date if delivery_date else today
    if due_date is None:
        due_date = invoice_date + timedelta(days=30)
    
    status = 'open'
    if due_date < today:
        status = 'overdue'
        overdue_count += 1
    
    try:
        cur.execute("""
            INSERT INTO receivables (
                company_id, customer_id, reference_type, reference_id,
                reference_number, original_amount, paid_amount, write_off_amount,
                invoice_date, due_date, status, reminder_count
            ) VALUES (%s, %s, 'sales_order', %s, %s, %s, 0, 0, %s, %s, %s, 0)
        """, (company_id, customer_id, order_id, order_number,
              total, invoice_date, due_date, status))
        created += 1
    except Exception as e:
        print(f"  Error for {order_number}: {e}")

print(f"\n  Created {created} receivables ({overdue_count} already overdue)")

# Now check for payments and allocate them
print("\n=== Checking existing payments to allocate ===")
cur.execute("""
    SELECT column_name FROM information_schema.columns 
    WHERE table_name = 'customer_payments' ORDER BY ordinal_position
""")
pay_cols = [r[0] for r in cur.fetchall()]
print(f"  Payment columns: {pay_cols}")

# Get unique customers with receivables
cur.execute("SELECT DISTINCT customer_id FROM receivables WHERE status IN ('open','overdue')")
cust_ids = [r[0] for r in cur.fetchall()]

# For each customer, check if they have payments
allocated_total = 0
for cid in cust_ids:
    # Get total payments for this customer
    cur.execute("""
        SELECT COALESCE(sum(amount), 0) 
        FROM customer_payments 
        WHERE customer_id = %s
    """, (cid,))
    total_paid = cur.fetchone()[0] or 0
    
    if total_paid > 0:
        # Get their receivables ordered by due_date (oldest first)
        cur.execute("""
            SELECT id, original_amount, paid_amount 
            FROM receivables 
            WHERE customer_id = %s AND status IN ('open','overdue')
            ORDER BY due_date ASC
        """, (cid,))
        receivables = cur.fetchall()
        
        remaining = float(total_paid)
        for rec in receivables:
            if remaining <= 0:
                break
            rec_id = rec[0]
            outstanding = float(rec[1]) - float(rec[2])
            if outstanding <= 0:
                continue
            
            alloc = min(remaining, outstanding)
            new_paid = float(rec[2]) + alloc
            new_status = 'paid' if new_paid >= float(rec[1]) else ('partial' if new_paid > 0 else rec[2])
            
            cur.execute("""
                UPDATE receivables 
                SET paid_amount = %s, status = %s, last_payment_date = CURRENT_DATE
                WHERE id = %s
            """, (new_paid, new_status, rec_id))
            
            remaining -= alloc
            allocated_total += alloc
        
        if allocated_total > 0:
            cur.execute("SELECT name FROM customers WHERE id = %s", (cid,))
            cname = cur.fetchone()[0]
            print(f"  Allocated {total_paid} to {cname}")

print(f"  Total allocated: {allocated_total}")

# Final summary
print("\n=== Final receivables summary ===")
cur.execute("""
    SELECT status, count(*), 
           sum(original_amount) as total_original,
           sum(paid_amount) as total_paid,
           sum(original_amount - paid_amount) as outstanding
    FROM receivables 
    GROUP BY status 
    ORDER BY status
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, original={r[2]}, paid={r[3]}, outstanding={r[4]}")

# Aging view
print("\n=== Aging buckets ===")
cur.execute("""
    SELECT aging_bucket, count(*), sum(balance) 
    FROM v_receivables_aging 
    GROUP BY aging_bucket 
    ORDER BY aging_bucket
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, balance={r[2]}")

cur.close()
conn.close()
