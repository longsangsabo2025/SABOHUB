"""
Create the payment-to-receivables sync trigger
"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# 1. Create the sync function
print("Creating sync_payment_to_receivables()...")
cur.execute("""
CREATE OR REPLACE FUNCTION sync_payment_to_receivables()
RETURNS TRIGGER AS $$
DECLARE
    v_remaining NUMERIC;
    v_rec RECORD;
    v_alloc NUMERIC;
BEGIN
    v_remaining := NEW.amount;
    
    -- Allocate payment to oldest unpaid receivables for this customer
    FOR v_rec IN
        SELECT id, original_amount, paid_amount,
               (original_amount - paid_amount - COALESCE(write_off_amount, 0)) as outstanding
        FROM receivables
        WHERE customer_id = NEW.customer_id
          AND company_id = NEW.company_id
          AND status IN ('open', 'overdue', 'partial')
          AND (original_amount - paid_amount - COALESCE(write_off_amount, 0)) > 0
        ORDER BY due_date ASC, created_at ASC
    LOOP
        EXIT WHEN v_remaining <= 0;
        
        v_alloc := LEAST(v_remaining, v_rec.outstanding);
        
        -- Create allocation record
        INSERT INTO payment_allocations (payment_id, receivable_id, amount)
        VALUES (NEW.id, v_rec.id, v_alloc);
        
        -- Update receivable
        UPDATE receivables SET
            paid_amount = paid_amount + v_alloc,
            last_payment_date = CURRENT_DATE,
            status = CASE
                WHEN (paid_amount + v_alloc) >= original_amount THEN 'paid'
                ELSE 'partial'
            END,
            updated_at = NOW()
        WHERE id = v_rec.id;
        
        v_remaining := v_remaining - v_alloc;
    END LOOP;
    
    -- Update customer total_debt
    UPDATE customers SET
        total_debt = GREATEST(0, COALESCE(total_debt, 0) - NEW.amount),
        updated_at = NOW()
    WHERE id = NEW.customer_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
""")
print("  ✅ Function created")

# 2. Create the trigger
print("Creating trigger...")
cur.execute("DROP TRIGGER IF EXISTS trg_sync_payment_to_receivables ON customer_payments")
cur.execute("""
    CREATE TRIGGER trg_sync_payment_to_receivables
    AFTER INSERT ON customer_payments
    FOR EACH ROW
    EXECUTE FUNCTION sync_payment_to_receivables()
""")
print("  ✅ Trigger created")

# 3. Verify
cur.execute("""
    SELECT trigger_name, event_manipulation, action_timing
    FROM information_schema.triggers
    WHERE event_object_table = 'customer_payments'
""")
for r in cur.fetchall():
    print(f"  Verified: {r[0]} ({r[2]} {r[1]})")

cur.close()
conn.close()
