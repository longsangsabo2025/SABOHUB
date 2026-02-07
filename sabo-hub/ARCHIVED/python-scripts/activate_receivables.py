"""
Phase 2: Activate the receivables system
- Populate receivables from existing unpaid orders
- Set default payment_terms for customers without it
- Fix the overdue logic (use due_date instead of credit_limit comparison)
- Create receivable records for all unpaid delivered orders
"""
import psycopg2
from datetime import datetime, timedelta

DB_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

conn = psycopg2.connect(DB_URL)
conn.autocommit = False
cur = conn.cursor()

try:
    print("=" * 60)
    print("PHASE 2: ACTIVATE RECEIVABLES SYSTEM")
    print("=" * 60)

    # Step 1: Set default payment_terms for customers that don't have it
    print("\n--- Step 1: Set default payment_terms (30 days) ---")
    cur.execute("""
        UPDATE customers 
        SET payment_terms = 30 
        WHERE payment_terms IS NULL OR payment_terms = 0
    """)
    print(f"  Updated {cur.rowcount} customers with default 30-day payment terms")

    # Step 2: Set due_date on sales_orders that don't have one
    # For delivered orders: due_date = delivered_at + payment_terms days
    # For others: due_date = created_at + payment_terms days
    print("\n--- Step 2: Set due_date on sales_orders ---")
    cur.execute("""
        UPDATE sales_orders so
        SET due_date = COALESCE(so.delivery_date, so.created_at) + (COALESCE(c.payment_terms, 30) || ' days')::interval
        FROM customers c
        WHERE so.customer_id = c.id
          AND so.due_date IS NULL
          AND so.payment_status != 'paid'
    """)
    print(f"  Set due_date on {cur.rowcount} sales orders")

    # Step 3: Create receivable records for all unpaid delivered orders
    print("\n--- Step 3: Create receivable records ---")
    
    # First check what exists
    cur.execute("SELECT COUNT(*) FROM receivables")
    existing_count = cur.fetchone()[0]
    print(f"  Existing receivables: {existing_count}")

    # Get all unpaid orders that have been delivered
    cur.execute("""
        SELECT so.id, so.company_id, so.customer_id, so.total, 
               COALESCE(so.paid_amount, 0) as paid_amount,
               so.order_number, so.payment_status,
               COALESCE(so.delivery_date, so.created_at) as invoice_date,
               so.due_date,
               so.created_at
        FROM sales_orders so
        WHERE so.payment_status != 'paid'
          AND so.delivery_status = 'delivered'
          AND NOT EXISTS (
              SELECT 1 FROM receivables r WHERE r.sales_order_id = so.id
          )
        ORDER BY so.created_at ASC
    """)
    unpaid_orders = cur.fetchall()
    print(f"  Found {len(unpaid_orders)} unpaid delivered orders without receivable records")

    created_count = 0
    for order in unpaid_orders:
        order_id, company_id, customer_id, total, paid_amount, order_number, payment_status, invoice_date, due_date, created_at = order
        
        amount_due = total - paid_amount
        if amount_due <= 0:
            continue
            
        # Determine status
        status = 'outstanding'
        if due_date and datetime.now() > due_date.replace(tzinfo=None) if hasattr(due_date, 'replace') else datetime.now() > due_date:
            status = 'overdue'
        if paid_amount > 0:
            status = 'partial'

        cur.execute("""
            INSERT INTO receivables (
                company_id, customer_id, sales_order_id, 
                invoice_number, invoice_date, due_date,
                amount, amount_paid, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (
            company_id, customer_id, order_id,
            f"INV-{order_number}" if order_number else f"INV-{str(order_id)[:8]}",
            invoice_date, due_date,
            total, paid_amount, status
        ))
        created_count += 1

    print(f"  Created {created_count} receivable records")

    # Step 4: Verify receivables data
    print("\n--- Step 4: Verification ---")
    cur.execute("""
        SELECT status, COUNT(*), SUM(amount - amount_paid) as total_outstanding
        FROM receivables
        GROUP BY status
        ORDER BY status
    """)
    for row in cur.fetchall():
        print(f"  {row[0]}: {row[1]} records, outstanding: {row[2]:,.0f} VND")

    # Check aging view
    cur.execute("""
        SELECT customer_name, total_outstanding, current_amount, 
               days_1_30, days_31_60, days_61_90, days_over_90
        FROM v_receivables_aging
        ORDER BY total_outstanding DESC
        LIMIT 10
    """)
    aging_data = cur.fetchall()
    if aging_data:
        print(f"\n--- Aging Report (top {len(aging_data)}) ---")
        for row in aging_data:
            print(f"  {row[0]}: Total={row[1]:,.0f} | Current={row[2]:,.0f} | 1-30={row[3]:,.0f} | 31-60={row[4]:,.0f} | 61-90={row[5]:,.0f} | >90={row[6]:,.0f}")
    else:
        print("  No aging data found")

    # Step 5: Update the complete_delivery_debt function to also create receivables
    print("\n--- Step 5: Update complete_delivery_debt to create receivables ---")
    cur.execute("""
        CREATE OR REPLACE FUNCTION complete_delivery_debt()
        RETURNS trigger AS $$
        BEGIN
            -- Only trigger on delivery completion
            IF NEW.delivery_status = 'delivered' AND 
               (OLD.delivery_status IS NULL OR OLD.delivery_status != 'delivered') THEN
                
                -- Add debt to customer
                UPDATE customers 
                SET total_debt = COALESCE(total_debt, 0) + COALESCE(NEW.total, 0) - COALESCE(NEW.paid_amount, 0)
                WHERE id = NEW.customer_id;

                -- Set due_date if not already set
                IF NEW.due_date IS NULL THEN
                    NEW.due_date := COALESCE(NEW.delivery_date, NOW()) + (
                        COALESCE(
                            (SELECT payment_terms FROM customers WHERE id = NEW.customer_id),
                            30
                        ) || ' days'
                    )::interval;
                END IF;

                -- Auto-create receivable record
                INSERT INTO receivables (
                    company_id, customer_id, sales_order_id,
                    invoice_number, invoice_date, due_date,
                    amount, amount_paid, status
                ) VALUES (
                    NEW.company_id, NEW.customer_id, NEW.id,
                    'INV-' || COALESCE(NEW.order_number, LEFT(NEW.id::text, 8)),
                    COALESCE(NEW.delivery_date, NOW()),
                    NEW.due_date,
                    COALESCE(NEW.total, 0),
                    COALESCE(NEW.paid_amount, 0),
                    CASE 
                        WHEN COALESCE(NEW.paid_amount, 0) >= COALESCE(NEW.total, 0) THEN 'paid'
                        WHEN COALESCE(NEW.paid_amount, 0) > 0 THEN 'partial'
                        ELSE 'outstanding'
                    END
                ) ON CONFLICT (sales_order_id) DO NOTHING;
            END IF;
            
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Updated complete_delivery_debt() function")

    # Step 6: Create/update function to sync payment to receivables
    print("\n--- Step 6: Create payment-to-receivable sync function ---")
    cur.execute("""
        CREATE OR REPLACE FUNCTION sync_payment_to_receivables()
        RETURNS trigger AS $$
        DECLARE
            v_remaining NUMERIC;
            v_receivable RECORD;
        BEGIN
            -- When a customer_payment is inserted, allocate to oldest receivables
            v_remaining := NEW.amount;
            
            FOR v_receivable IN 
                SELECT id, amount, amount_paid, (amount - amount_paid) as outstanding
                FROM receivables
                WHERE customer_id = NEW.customer_id
                  AND company_id = NEW.company_id
                  AND status != 'paid'
                  AND (amount - amount_paid) > 0
                ORDER BY due_date ASC NULLS LAST, created_at ASC
            LOOP
                EXIT WHEN v_remaining <= 0;
                
                DECLARE
                    v_apply NUMERIC;
                    v_new_paid NUMERIC;
                    v_new_status TEXT;
                BEGIN
                    v_apply := LEAST(v_remaining, v_receivable.outstanding);
                    v_new_paid := v_receivable.amount_paid + v_apply;
                    
                    IF v_new_paid >= v_receivable.amount THEN
                        v_new_status := 'paid';
                    ELSE
                        v_new_status := 'partial';
                    END IF;
                    
                    UPDATE receivables
                    SET amount_paid = v_new_paid,
                        status = v_new_status,
                        updated_at = NOW()
                    WHERE id = v_receivable.id;
                    
                    -- Create payment allocation
                    INSERT INTO payment_allocations (
                        payment_id, receivable_id, amount
                    ) VALUES (
                        NEW.id, v_receivable.id, v_apply
                    );
                    
                    v_remaining := v_remaining - v_apply;
                END;
            END LOOP;
            
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Created sync_payment_to_receivables() function")

    # Step 7: Create trigger for auto-sync payments
    print("\n--- Step 7: Create trigger for payment sync ---")
    cur.execute("""
        DROP TRIGGER IF EXISTS trg_sync_payment_to_receivables ON customer_payments;
    """)
    cur.execute("""
        CREATE TRIGGER trg_sync_payment_to_receivables
        AFTER INSERT ON customer_payments
        FOR EACH ROW
        EXECUTE FUNCTION sync_payment_to_receivables();
    """)
    print("  Created trigger: trg_sync_payment_to_receivables")

    # Step 8: Create function to auto-update overdue status daily
    print("\n--- Step 8: Create overdue status updater ---")
    cur.execute("""
        CREATE OR REPLACE FUNCTION update_overdue_receivables()
        RETURNS void AS $$
        BEGIN
            UPDATE receivables
            SET status = 'overdue',
                updated_at = NOW()
            WHERE status IN ('outstanding', 'partial')
              AND due_date < CURRENT_DATE
              AND (amount - amount_paid) > 0;
        END;
        $$ LANGUAGE plpgsql;
    """)
    print("  Updated update_overdue_receivables() function")

    # Run it now to mark current overdue items
    cur.execute("SELECT update_overdue_receivables()")
    print("  Executed update_overdue_receivables()")

    # Final verification
    print("\n" + "=" * 60)
    print("FINAL VERIFICATION")
    print("=" * 60)
    
    cur.execute("SELECT COUNT(*) FROM receivables")
    print(f"  Total receivables: {cur.fetchone()[0]}")
    
    cur.execute("SELECT status, COUNT(*) FROM receivables GROUP BY status ORDER BY status")
    for row in cur.fetchall():
        print(f"    {row[0]}: {row[1]}")

    cur.execute("SELECT COUNT(*) FROM customers WHERE payment_terms IS NOT NULL AND payment_terms > 0")
    print(f"  Customers with payment_terms: {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM sales_orders WHERE due_date IS NOT NULL")
    print(f"  Orders with due_date: {cur.fetchone()[0]}")

    conn.commit()
    print("\n✅ ALL CHANGES COMMITTED SUCCESSFULLY")

except Exception as e:
    conn.rollback()
    print(f"\n❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
finally:
    cur.close()
    conn.close()
