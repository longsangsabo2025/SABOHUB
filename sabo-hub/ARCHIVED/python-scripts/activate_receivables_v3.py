"""
Phase 2: Activate receivables (v3 - handles all edge cases)
"""
import psycopg2
from datetime import datetime, timedelta, date

DB_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DB_URL)
conn.autocommit = False
cur = conn.cursor()

try:
    print("=" * 60)
    print("PHASE 2: ACTIVATE RECEIVABLES SYSTEM v3")
    print("=" * 60)

    # Step 1: Set payment_terms
    print("\n--- Step 1: Set default payment_terms (30 days) ---")
    cur.execute("UPDATE customers SET payment_terms = 30 WHERE payment_terms IS NULL OR payment_terms = 0")
    print(f"  Updated {cur.rowcount} customers")

    # Step 2: Set due_date on orders
    print("\n--- Step 2: Set due_date on sales_orders ---")
    cur.execute("""
        UPDATE sales_orders so
        SET due_date = (COALESCE(so.delivery_date, so.created_at)::date + COALESCE(c.payment_terms, 30))
        FROM customers c
        WHERE so.customer_id = c.id
          AND so.due_date IS NULL
          AND so.payment_status != 'paid'
    """)
    print(f"  Set due_date on {cur.rowcount} orders")

    # Step 3: Create receivable records 
    print("\n--- Step 3: Create receivable records ---")
    cur.execute("""
        SELECT so.id, so.company_id, so.customer_id, so.total, 
               COALESCE(so.paid_amount, 0) as paid_amount,
               so.order_number, so.payment_status,
               COALESCE(so.delivery_date, so.created_at)::date as invoice_date,
               COALESCE(so.due_date, (COALESCE(so.delivery_date, so.created_at)::date + 30)) as due_date
        FROM sales_orders so
        WHERE so.payment_status != 'paid'
          AND so.delivery_status = 'delivered'
          AND NOT EXISTS (
              SELECT 1 FROM receivables r 
              WHERE r.reference_type = 'sales_order' AND r.reference_id = so.id
          )
        ORDER BY so.created_at ASC
    """)
    unpaid_orders = cur.fetchall()
    print(f"  Found {len(unpaid_orders)} unpaid delivered orders")

    created = 0
    for order in unpaid_orders:
        order_id, company_id, customer_id, total, paid_amount, order_number, payment_status, invoice_date, due_date = order
        
        if total is None or float(total) <= 0:
            continue
        amount_due = float(total) - float(paid_amount)
        if amount_due <= 0:
            continue

        status = 'open'
        if due_date and date.today() > due_date:
            status = 'overdue'
        if float(paid_amount) > 0:
            status = 'partial'

        ref_num = f"INV-{order_number}" if order_number else f"INV-{str(order_id)[:8]}"

        cur.execute("""
            INSERT INTO receivables (
                company_id, customer_id, 
                reference_type, reference_id, reference_number,
                original_amount, paid_amount,
                invoice_date, due_date, status
            ) VALUES (%s, %s, 'sales_order', %s, %s, %s, %s, %s, %s, %s)
        """, (
            company_id, customer_id, order_id, ref_num,
            total, paid_amount,
            invoice_date, due_date, status
        ))
        created += 1
    print(f"  Created {created} receivables")

    # Step 4: Verify
    print("\n--- Step 4: Verification ---")
    cur.execute("""
        SELECT status, COUNT(*), SUM(original_amount - paid_amount - COALESCE(write_off_amount, 0)) as outstanding
        FROM receivables GROUP BY status ORDER BY status
    """)
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} records, outstanding: {float(row[2] or 0):,.0f} VND")

    # Aging report
    cur.execute("""
        SELECT customer_name, 
               SUM(balance) as total_outstanding,
               SUM(CASE WHEN aging_bucket = 'current' THEN balance ELSE 0 END) as current_amt,
               SUM(CASE WHEN aging_bucket = '1-30' THEN balance ELSE 0 END) as d1_30,
               SUM(CASE WHEN aging_bucket = '31-60' THEN balance ELSE 0 END) as d31_60,
               SUM(CASE WHEN aging_bucket = '61-90' THEN balance ELSE 0 END) as d61_90,
               SUM(CASE WHEN aging_bucket = '90+' THEN balance ELSE 0 END) as d90plus
        FROM v_receivables_aging
        GROUP BY customer_name
        ORDER BY total_outstanding DESC
        LIMIT 10
    """)
    aging = cur.fetchall()
    if aging:
        print(f"\n--- Aging Report ---")
        for row in aging:
            print(f"  {row[0]}: Total={float(row[1]):,.0f} | Current={float(row[2]):,.0f} | 1-30={float(row[3]):,.0f} | 31-60={float(row[4]):,.0f} | 61-90={float(row[5]):,.0f} | >90={float(row[6]):,.0f}")

    # Step 5: Update functions
    print("\n--- Step 5: Update DB functions ---")
    
    # complete_delivery_debt
    cur.execute("""
        CREATE OR REPLACE FUNCTION complete_delivery_debt()
        RETURNS trigger AS $$
        BEGIN
            IF NEW.delivery_status = 'delivered' AND 
               (OLD.delivery_status IS NULL OR OLD.delivery_status != 'delivered') THEN
                
                UPDATE customers 
                SET total_debt = COALESCE(total_debt, 0) + COALESCE(NEW.total, 0) - COALESCE(NEW.paid_amount, 0)
                WHERE id = NEW.customer_id;

                IF NEW.due_date IS NULL THEN
                    NEW.due_date := COALESCE(NEW.delivery_date, CURRENT_DATE) + 
                        COALESCE((SELECT payment_terms FROM customers WHERE id = NEW.customer_id), 30);
                END IF;

                INSERT INTO receivables (
                    company_id, customer_id, 
                    reference_type, reference_id, reference_number,
                    original_amount, paid_amount,
                    invoice_date, due_date, status
                ) VALUES (
                    NEW.company_id, NEW.customer_id,
                    'sales_order', NEW.id,
                    'INV-' || COALESCE(NEW.order_number, LEFT(NEW.id::text, 8)),
                    COALESCE(NEW.total, 0), COALESCE(NEW.paid_amount, 0),
                    COALESCE(NEW.delivery_date, CURRENT_DATE),
                    NEW.due_date,
                    CASE 
                        WHEN COALESCE(NEW.paid_amount, 0) >= COALESCE(NEW.total, 0) THEN 'paid'
                        WHEN COALESCE(NEW.paid_amount, 0) > 0 THEN 'partial'
                        ELSE 'open'
                    END
                ) ON CONFLICT DO NOTHING;
            END IF;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Updated complete_delivery_debt()")

    # sync_payment_to_receivables
    cur.execute("""
        CREATE OR REPLACE FUNCTION sync_payment_to_receivables()
        RETURNS trigger AS $$
        DECLARE
            v_remaining NUMERIC;
            v_receivable RECORD;
            v_apply NUMERIC;
            v_new_paid NUMERIC;
            v_new_status TEXT;
        BEGIN
            v_remaining := NEW.amount;
            FOR v_receivable IN 
                SELECT id, original_amount, paid_amount, 
                       (original_amount - paid_amount - COALESCE(write_off_amount, 0)) as outstanding
                FROM receivables
                WHERE customer_id = NEW.customer_id
                  AND company_id = NEW.company_id
                  AND status NOT IN ('paid', 'written_off')
                  AND (original_amount - paid_amount - COALESCE(write_off_amount, 0)) > 0
                ORDER BY due_date ASC NULLS LAST, created_at ASC
            LOOP
                EXIT WHEN v_remaining <= 0;
                v_apply := LEAST(v_remaining, v_receivable.outstanding);
                v_new_paid := v_receivable.paid_amount + v_apply;
                IF v_new_paid >= v_receivable.original_amount THEN
                    v_new_status := 'paid';
                ELSE
                    v_new_status := 'partial';
                END IF;
                UPDATE receivables
                SET paid_amount = v_new_paid, status = v_new_status,
                    last_payment_date = CURRENT_DATE, updated_at = NOW()
                WHERE id = v_receivable.id;
                INSERT INTO payment_allocations (payment_id, receivable_id, amount)
                VALUES (NEW.id, v_receivable.id, v_apply);
                v_remaining := v_remaining - v_apply;
            END LOOP;
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Created sync_payment_to_receivables()")

    # Trigger
    cur.execute("DROP TRIGGER IF EXISTS trg_sync_payment_to_receivables ON customer_payments")
    cur.execute("""
        CREATE TRIGGER trg_sync_payment_to_receivables
        AFTER INSERT ON customer_payments
        FOR EACH ROW EXECUTE FUNCTION sync_payment_to_receivables();
    """)
    print("  Created trigger")

    # Update overdue
    cur.execute("""
        CREATE OR REPLACE FUNCTION update_overdue_receivables()
        RETURNS void AS $$
        BEGIN
            UPDATE receivables
            SET status = 'overdue', updated_at = NOW()
            WHERE status IN ('open', 'partial')
              AND due_date < CURRENT_DATE
              AND (original_amount - paid_amount - COALESCE(write_off_amount, 0)) > 0;
        END;
        $$ LANGUAGE plpgsql;
    """)
    cur.execute("SELECT update_overdue_receivables()")
    print("  Updated overdue status")

    # Final
    print("\n" + "=" * 60)
    cur.execute("SELECT COUNT(*) FROM receivables")
    print(f"Total receivables: {cur.fetchone()[0]}")
    cur.execute("SELECT status, COUNT(*) FROM receivables GROUP BY status ORDER BY status")
    for r in cur.fetchall():
        print(f"  {r[0]}: {r[1]}")

    conn.commit()
    print("\n✅ ALL COMMITTED")

except Exception as e:
    conn.rollback()
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    cur.close()
    conn.close()
