"""
Phase 2: Activate the receivables system (FIXED)
Uses correct column names: reference_type/reference_id, original_amount, etc.
"""
import psycopg2
from datetime import datetime, timedelta

DB_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DB_URL)
conn.autocommit = False
cur = conn.cursor()

try:
    print("=" * 60)
    print("PHASE 2: ACTIVATE RECEIVABLES SYSTEM (FIXED)")
    print("=" * 60)

    # Step 1 already done (payment_terms=30 set for 1031 customers)
    # Step 2 already done (due_date set on 80 sales orders)
    
    # Verify prior steps
    cur.execute("SELECT COUNT(*) FROM customers WHERE payment_terms = 30")
    print(f"  Customers with 30-day terms: {cur.fetchone()[0]}")
    cur.execute("SELECT COUNT(*) FROM sales_orders WHERE due_date IS NOT NULL")
    print(f"  Orders with due_date: {cur.fetchone()[0]}")

    # Step 3: Create receivable records for unpaid delivered orders
    print("\n--- Step 3: Create receivable records ---")
    cur.execute("SELECT COUNT(*) FROM receivables")
    print(f"  Existing receivables: {cur.fetchone()[0]}")

    cur.execute("""
        SELECT so.id, so.company_id, so.customer_id, so.total, 
               COALESCE(so.paid_amount, 0) as paid_amount,
               so.order_number, so.payment_status,
               COALESCE(so.delivery_date, so.created_at) as invoice_date,
               so.due_date
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
    print(f"  Found {len(unpaid_orders)} unpaid delivered orders without receivables")

    created_count = 0
    for order in unpaid_orders:
        order_id, company_id, customer_id, total, paid_amount, order_number, payment_status, invoice_date, due_date = order
        
        if total is None:
            continue
        amount_due = float(total) - float(paid_amount or 0)
        if amount_due <= 0:
            continue

        # Determine status
        status = 'outstanding'
        if due_date and datetime.now().date() > due_date:
            status = 'overdue'
        if float(paid_amount or 0) > 0:
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
            total, paid_amount or 0,
            invoice_date, due_date, status
        ))
        created_count += 1

    print(f"  Created {created_count} receivable records")

    # Step 4: Verify
    print("\n--- Step 4: Verification ---")
    cur.execute("""
        SELECT status, COUNT(*), SUM(original_amount - paid_amount - COALESCE(write_off_amount, 0)) as outstanding
        FROM receivables
        GROUP BY status
        ORDER BY status
    """)
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} records, outstanding: {float(row[2] or 0):,.0f} VND")

    # Check aging view
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
    aging_data = cur.fetchall()
    if aging_data:
        print(f"\n--- Aging Report (top {len(aging_data)}) ---")
        for row in aging_data:
            print(f"  {row[0]}: Total={float(row[1]):,.0f} | Current={float(row[2]):,.0f} | 1-30={float(row[3]):,.0f} | 31-60={float(row[4]):,.0f} | 61-90={float(row[5]):,.0f} | >90={float(row[6]):,.0f}")

    # Step 5: Update complete_delivery_debt function
    print("\n--- Step 5: Update complete_delivery_debt ---")
    cur.execute("""
        CREATE OR REPLACE FUNCTION complete_delivery_debt()
        RETURNS trigger AS $$
        BEGIN
            IF NEW.delivery_status = 'delivered' AND 
               (OLD.delivery_status IS NULL OR OLD.delivery_status != 'delivered') THEN
                
                -- Add debt to customer
                UPDATE customers 
                SET total_debt = COALESCE(total_debt, 0) + COALESCE(NEW.total, 0) - COALESCE(NEW.paid_amount, 0)
                WHERE id = NEW.customer_id;

                -- Set due_date if not already set
                IF NEW.due_date IS NULL THEN
                    NEW.due_date := COALESCE(NEW.delivery_date, NOW())::date + (
                        COALESCE(
                            (SELECT payment_terms FROM customers WHERE id = NEW.customer_id),
                            30
                        )
                    );
                END IF;

                -- Auto-create receivable
                INSERT INTO receivables (
                    company_id, customer_id, 
                    reference_type, reference_id, reference_number,
                    original_amount, paid_amount,
                    invoice_date, due_date, status
                ) VALUES (
                    NEW.company_id, NEW.customer_id,
                    'sales_order', NEW.id,
                    'INV-' || COALESCE(NEW.order_number, LEFT(NEW.id::text, 8)),
                    COALESCE(NEW.total, 0),
                    COALESCE(NEW.paid_amount, 0),
                    COALESCE(NEW.delivery_date, CURRENT_DATE),
                    NEW.due_date,
                    CASE 
                        WHEN COALESCE(NEW.paid_amount, 0) >= COALESCE(NEW.total, 0) THEN 'paid'
                        WHEN COALESCE(NEW.paid_amount, 0) > 0 THEN 'partial'
                        ELSE 'outstanding'
                    END
                )
                ON CONFLICT DO NOTHING;
            END IF;
            
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Updated complete_delivery_debt()")

    # Step 6: Create payment-to-receivable sync
    print("\n--- Step 6: Create payment sync function ---")
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
                SET paid_amount = v_new_paid,
                    status = v_new_status,
                    last_payment_date = CURRENT_DATE,
                    updated_at = NOW()
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

    # Step 7: Create trigger
    print("\n--- Step 7: Create payment sync trigger ---")
    cur.execute("DROP TRIGGER IF EXISTS trg_sync_payment_to_receivables ON customer_payments")
    cur.execute("""
        CREATE TRIGGER trg_sync_payment_to_receivables
        AFTER INSERT ON customer_payments
        FOR EACH ROW
        EXECUTE FUNCTION sync_payment_to_receivables();
    """)
    print("  Created trigger: trg_sync_payment_to_receivables")

    # Step 8: Update overdue function
    print("\n--- Step 8: Update overdue status ---")
    cur.execute("""
        CREATE OR REPLACE FUNCTION update_overdue_receivables()
        RETURNS void AS $$
        BEGIN
            UPDATE receivables
            SET status = 'overdue', updated_at = NOW()
            WHERE status IN ('outstanding', 'partial')
              AND due_date < CURRENT_DATE
              AND (original_amount - paid_amount - COALESCE(write_off_amount, 0)) > 0;
        END;
        $$ LANGUAGE plpgsql;
    """)
    cur.execute("SELECT update_overdue_receivables()")
    cur.execute("SELECT COUNT(*) FROM receivables WHERE status = 'overdue'")
    print(f"  Marked {cur.fetchone()[0]} receivables as overdue")

    # Final summary
    print("\n" + "=" * 60)
    print("FINAL SUMMARY")
    print("=" * 60)
    cur.execute("SELECT COUNT(*) FROM receivables")
    print(f"  Total receivables: {cur.fetchone()[0]}")
    cur.execute("SELECT status, COUNT(*) FROM receivables GROUP BY status ORDER BY status")
    for row in cur.fetchall():
        print(f"    {row[0]}: {row[1]}")

    conn.commit()
    print("\n✅ ALL CHANGES COMMITTED")

except Exception as e:
    conn.rollback()
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    cur.close()
    conn.close()
