"""
Create a DB trigger that sends notifications when receivables become overdue.
Also update the update_overdue_receivables() function to create notifications.
"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# 1. Update update_overdue_receivables() to also create notification records
print("=== Updating update_overdue_receivables() with notifications ===")
cur.execute("DROP FUNCTION IF EXISTS update_overdue_receivables()")
cur.execute("""
CREATE OR REPLACE FUNCTION update_overdue_receivables()
RETURNS void AS $$
DECLARE
    v_rec RECORD;
    v_finance_users UUID[];
BEGIN
    -- Mark open/partial receivables as overdue if past due date
    FOR v_rec IN
        UPDATE receivables 
        SET status = 'overdue', updated_at = NOW()
        WHERE status IN ('open', 'partial')
          AND due_date < CURRENT_DATE
        RETURNING id, company_id, customer_id, reference_number,
                  original_amount, paid_amount
    LOOP
        -- Get finance/accountant users for this company
        SELECT ARRAY_AGG(e.id) INTO v_finance_users
        FROM employees e
        WHERE e.company_id = v_rec.company_id
          AND e.role IN ('ke_toan', 'accountant', 'manager', 'ceo');
        
        -- Create notification for each finance user
        IF v_finance_users IS NOT NULL THEN
            INSERT INTO notifications (user_id, company_id, title, body, type, 
                                       reference_type, reference_id, is_read, created_at)
            SELECT 
                unnest(v_finance_users),
                v_rec.company_id,
                'Công nợ quá hạn',
                'Đơn ' || v_rec.reference_number || ' đã quá hạn thanh toán. ' ||
                'Còn nợ: ' || to_char(v_rec.original_amount - v_rec.paid_amount, 'FM999,999,999') || '₫',
                'warning',
                'receivable',
                v_rec.id,
                false,
                NOW()
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
""")
print("  ✅ Function updated with notification creation")

# 2. Create a function to generate overdue summary notifications (for daily digest)
print("\n=== Creating daily overdue digest function ===")
cur.execute("""
CREATE OR REPLACE FUNCTION send_overdue_digest_notifications()
RETURNS void AS $$
DECLARE
    v_company RECORD;
    v_finance_users UUID[];
    v_total_overdue NUMERIC;
    v_overdue_count INT;
    v_customer_count INT;
BEGIN
    -- For each company with overdue receivables
    FOR v_company IN
        SELECT DISTINCT company_id FROM receivables WHERE status = 'overdue'
    LOOP
        -- Get aggregate data
        SELECT count(*), count(DISTINCT customer_id), 
               COALESCE(sum(original_amount - paid_amount), 0)
        INTO v_overdue_count, v_customer_count, v_total_overdue
        FROM receivables 
        WHERE company_id = v_company.company_id AND status = 'overdue';
        
        IF v_overdue_count > 0 THEN
            -- Get finance users
            SELECT ARRAY_AGG(e.id) INTO v_finance_users
            FROM employees e
            WHERE e.company_id = v_company.company_id
              AND e.role IN ('ke_toan', 'accountant', 'manager', 'ceo');
            
            IF v_finance_users IS NOT NULL THEN
                INSERT INTO notifications (user_id, company_id, title, body, type,
                                           reference_type, is_read, created_at)
                SELECT 
                    unnest(v_finance_users),
                    v_company.company_id,
                    '📊 Báo cáo công nợ quá hạn',
                    'Có ' || v_overdue_count || ' khoản nợ quá hạn từ ' || 
                    v_customer_count || ' khách hàng. ' ||
                    'Tổng: ' || to_char(v_total_overdue, 'FM999,999,999') || '₫',
                    'warning',
                    'overdue_digest',
                    false,
                    NOW();
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
""")
print("  ✅ Daily digest function created")

# 3. Schedule the digest to run daily at 8 AM (after overdue update at midnight)
print("\n=== Scheduling daily digest cron ===")
try:
    cur.execute("""
        SELECT cron.schedule(
            'send-overdue-digest',
            '0 1 * * *',
            'SELECT send_overdue_digest_notifications()'
        )
    """)
    job_id = cur.fetchone()
    print(f"  ✅ Digest scheduled! Job ID: {job_id}")
except Exception as e:
    print(f"  Note: {e}")

# 4. Verify all cron jobs
print("\n=== All cron jobs ===")
cur.execute("SELECT jobid, schedule, command, active FROM cron.job ORDER BY jobid")
for j in cur.fetchall():
    print(f"  Job {j[0]}: {j[1]} | {j[2][:50]}... | active={j[3]}")

# 5. Test: Run the overdue update now to see if it creates notifications
print("\n=== Running update_overdue_receivables() ===")
cur.execute("SELECT update_overdue_receivables()")
print("  Done")

# 6. Check if any notifications were created
cur.execute("""
    SELECT count(*) FROM notifications 
    WHERE type = 'warning' AND reference_type = 'receivable'
""")
count = cur.fetchone()[0]
print(f"\n=== Overdue notifications created: {count} ===")

# 7. Check notification table columns (for reference)
print("\n=== notifications columns ===")
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'notifications' 
    ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} (null={r[2]})")

cur.close()
conn.close()
