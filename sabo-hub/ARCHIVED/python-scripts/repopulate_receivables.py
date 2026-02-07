"""
Check delivered orders and re-populate receivables if needed
"""
import psycopg2
from datetime import datetime, timedelta

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# 1. Check delivered orders that should have receivables
print("=== Delivered orders without receivables ===")
cur.execute("""
    SELECT so.id, so.order_number, so.customer_id, so.total, so.delivery_date,
           so.due_date, so.company_id,
           c.name as customer_name
    FROM sales_orders so
    JOIN customers c ON c.id = so.customer_id
    WHERE so.delivery_status = 'delivered'
      AND so.total > 0
      AND NOT EXISTS (
          SELECT 1 FROM receivables r 
          WHERE r.reference_id = so.id
      )
    ORDER BY so.delivery_date DESC
""")
orders = cur.fetchall()
print(f"  Found {len(orders)} delivered orders missing receivables")
for o in orders[:5]:
    print(f"  Order {o[1]}: customer={o[7]}, total={o[3]}, delivered={o[4]}")

# 2. Check total receivables count
cur.execute("SELECT count(*) FROM receivables")
rec_count = cur.fetchone()[0]
print(f"\n=== Current receivables count: {rec_count} ===")

# 3. Check total payments
cur.execute("SELECT count(*), sum(amount) FROM customer_payments WHERE status = 'confirmed'")
pay = cur.fetchone()
print(f"=== Payments: {pay[0]} records, total={pay[1]} ===")

# 4. Re-create receivables for all delivered orders
if len(orders) > 0:
    print(f"\n=== Creating {len(orders)} receivables ===")
    created = 0
    for o in orders:
        order_id = o[0]
        order_number = o[1]
        customer_id = o[2]
        total = o[3]
        delivery_date = o[4]
        due_date = o[5]
        company_id = o[6]
        
        # Calculate due_date if missing (payment_terms = 30 days)
        if due_date is None:
            if delivery_date:
                due_date = delivery_date + timedelta(days=30)
            else:
                due_date = datetime.now().date() + timedelta(days=30)
        
        invoice_date = delivery_date if delivery_date else datetime.now().date()
        
        # Check for existing payments for this order
        cur.execute("""
            SELECT COALESCE(sum(amount), 0) 
            FROM customer_payments 
            WHERE customer_id = %s AND status = 'confirmed'
        """, (customer_id,))
        # Note: payments aren't order-specific in all cases, so we start with paid_amount=0
        
        # Determine status
        status = 'open'
        if due_date and due_date < datetime.now().date():
            status = 'overdue'
        
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
            print(f"  Error creating receivable for {order_number}: {e}")
    
    print(f"  Created {created} receivables")

# 5. Run update_overdue to mark any that are past due
print("\n=== Running update_overdue_receivables() ===")
cur.execute("SELECT update_overdue_receivables()")

# 6. Final summary
print("\n=== Final receivables summary ===")
cur.execute("""
    SELECT status, count(*), 
           sum(original_amount) as total_original,
           sum(paid_amount) as total_paid,
           sum(original_amount - paid_amount) as total_outstanding
    FROM receivables 
    GROUP BY status 
    ORDER BY status
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, original={r[2]}, outstanding={r[4]}")

# 7. Verify aging view works
print("\n=== Aging view check ===")
cur.execute("""
    SELECT aging_bucket, count(*), sum(balance) 
    FROM v_receivables_aging 
    GROUP BY aging_bucket
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, balance={r[2]}")

cur.close()
conn.close()
