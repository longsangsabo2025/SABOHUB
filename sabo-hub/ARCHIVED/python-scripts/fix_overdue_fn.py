import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()
try:
    cur.execute("DROP FUNCTION IF EXISTS update_overdue_receivables()")
    cur.execute("""
        CREATE FUNCTION update_overdue_receivables()
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
    
    cur.execute("SELECT status, COUNT(*) FROM receivables GROUP BY status ORDER BY status")
    print("Final receivables status:")
    for r in cur.fetchall():
        print(f"  {r[0]}: {r[1]}")
    
    conn.commit()
    print("✅ Done")
except Exception as e:
    conn.rollback()
    print(f"❌ {e}")
finally:
    cur.close()
    conn.close()
