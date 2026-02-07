import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
conn.autocommit = True
cur = conn.cursor()

# 1. Update update_overdue_receivables() to create notifications
print("=== Updating update_overdue_receivables() with notification support ===")
cur.execute("DROP FUNCTION IF EXISTS update_overdue_receivables()")
cur.execute("""
CREATE OR REPLACE FUNCTION update_overdue_receivables()
RETURNS void AS $$
DECLARE
    v_rec RECORD;
    v_user_id UUID;
BEGIN
    -- Mark open/partial receivables as overdue if past due date
    FOR v_rec IN
        UPDATE receivables 
        SET status = 'overdue', updated_at = NOW()
        WHERE status IN ('open', 'partial')
          AND due_date < CURRENT_DATE
        RETURNING id, company_id, customer_id, reference_number,
                  original_amount, paid_amount, due_date
    LOOP
        -- Create notification for each finance/ceo user of this company
        FOR v_user_id IN
            SELECT e.id FROM employees e
            WHERE e.company_id = v_rec.company_id
              AND e.role IN ('finance', 'ceo', 'MANAGER')
        LOOP
            INSERT INTO notifications (user_id, type, title, message, data, is_read)
            VALUES (
                v_user_id,
                'overdue_payment',
                'Công nợ quá hạn: ' || v_rec.reference_number,
                'Đơn ' || v_rec.reference_number || ' đã quá hạn thanh toán. ' ||
                'Còn nợ: ' || to_char(v_rec.original_amount - v_rec.paid_amount, 'FM999,999,999') || '₫. ' ||
                'Hạn: ' || to_char(v_rec.due_date, 'DD/MM/YYYY'),
                jsonb_build_object(
                    'receivable_id', v_rec.id,
                    'customer_id', v_rec.customer_id,
                    'company_id', v_rec.company_id,
                    'reference_number', v_rec.reference_number,
                    'amount_due', v_rec.original_amount - v_rec.paid_amount,
                    'due_date', v_rec.due_date
                ),
                false
            );
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
""")
print("  ✅ Function updated")

# 2. Create daily digest function
print("\n=== Creating send_overdue_digest_notifications() ===")
cur.execute("DROP FUNCTION IF EXISTS send_overdue_digest_notifications()")
cur.execute("""
CREATE OR REPLACE FUNCTION send_overdue_digest_notifications()
RETURNS void AS $$
DECLARE
    v_company RECORD;
    v_user_id UUID;
    v_total_overdue NUMERIC;
    v_overdue_count INT;
    v_customer_count INT;
    v_severely_overdue INT;
BEGIN
    FOR v_company IN
        SELECT DISTINCT company_id FROM receivables WHERE status = 'overdue'
    LOOP
        SELECT count(*), count(DISTINCT customer_id),
               COALESCE(sum(original_amount - paid_amount), 0)
        INTO v_overdue_count, v_customer_count, v_total_overdue
        FROM receivables 
        WHERE company_id = v_company.company_id AND status = 'overdue';
        
        -- Count severely overdue (>30 days)
        SELECT count(*) INTO v_severely_overdue
        FROM receivables 
        WHERE company_id = v_company.company_id 
          AND status = 'overdue'
          AND due_date < CURRENT_DATE - INTERVAL '30 days';
        
        IF v_overdue_count > 0 THEN
            FOR v_user_id IN
                SELECT e.id FROM employees e
                WHERE e.company_id = v_company.company_id
                  AND e.role IN ('finance', 'ceo', 'MANAGER')
            LOOP
                INSERT INTO notifications (user_id, type, title, message, data, is_read)
                VALUES (
                    v_user_id,
                    'overdue_digest',
                    'Báo cáo công nợ quá hạn hàng ngày',
                    'Có ' || v_overdue_count || ' khoản nợ quá hạn từ ' || 
                    v_customer_count || ' khách hàng. ' ||
                    'Tổng: ' || to_char(v_total_overdue, 'FM999,999,999') || '₫' ||
                    CASE WHEN v_severely_overdue > 0 
                         THEN '. ⚠️ ' || v_severely_overdue || ' khoản quá hạn >30 ngày!'
                         ELSE '' END,
                    jsonb_build_object(
                        'company_id', v_company.company_id,
                        'overdue_count', v_overdue_count,
                        'customer_count', v_customer_count,
                        'total_overdue', v_total_overdue,
                        'severely_overdue', v_severely_overdue
                    ),
                    false
                );
            END LOOP;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
""")
print("  ✅ Digest function created")

# 3. Schedule digest cron (8 AM UTC+7 = 1 AM UTC)
print("\n=== Scheduling daily digest ===")
try:
    # Check if already exists
    cur.execute("SELECT jobid FROM cron.job WHERE jobname = 'send-overdue-digest'")
    existing = cur.fetchone()
    if existing:
        cur.execute("SELECT cron.unschedule(%s)", (existing[0],))
        print(f"  Removed old digest job {existing[0]}")
    
    cur.execute("""
        SELECT cron.schedule(
            'send-overdue-digest',
            '0 1 * * *',
            'SELECT send_overdue_digest_notifications()'
        )
    """)
    job_id = cur.fetchone()[0]
    print(f"  ✅ Digest scheduled at 1 AM UTC (8 AM VN). Job ID: {job_id}")
except Exception as e:
    print(f"  Error: {e}")

# 4. Verify all cron jobs
print("\n=== All cron jobs ===")
cur.execute("SELECT jobid, jobname, schedule, command, active FROM cron.job ORDER BY jobid")
for j in cur.fetchall():
    print(f"  Job {j[0]} ({j[1]}): {j[2]} | {j[3][:60]} | active={j[4]}")

# 5. Test: Manually trigger overdue check
print("\n=== Testing update_overdue_receivables() ===")
cur.execute("SELECT update_overdue_receivables()")
print("  Done")

# Check new notifications
cur.execute("SELECT type, count(*) FROM notifications GROUP BY type ORDER BY type")
print("\n=== Notification types ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# 6. Test digest too
print("\n=== Testing send_overdue_digest_notifications() ===")
cur.execute("SELECT send_overdue_digest_notifications()")
print("  Done")

cur.execute("SELECT type, count(*) FROM notifications GROUP BY type ORDER BY type")
print("\n=== Notification types after digest ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

cur.close()
conn.close()
print("\n✅ All done!")
