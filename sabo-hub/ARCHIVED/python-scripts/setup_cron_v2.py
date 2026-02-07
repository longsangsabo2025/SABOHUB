"""
Check receivables schema and set up pg_cron for daily overdue updates
"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# 1. Check receivables columns
print("=== Receivables columns ===")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'receivables' 
    ORDER BY ordinal_position
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# 2. Receivables status summary using actual columns
print("\n=== Receivables status summary ===")
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
    print(f"  {r[0]}: {r[1]} records, original={r[2]}, paid={r[3]}, outstanding={r[4]}")

# 3. Check past-due receivables
print("\n=== Receivables past due ===")
cur.execute("""
    SELECT id, customer_id, original_amount, paid_amount,
           original_amount - paid_amount as outstanding,
           status, due_date,
           CURRENT_DATE - due_date as days_overdue
    FROM receivables 
    WHERE due_date < CURRENT_DATE AND status IN ('open', 'partial')
    ORDER BY due_date
    LIMIT 20
""")
rows = cur.fetchall()
print(f"  Found {len(rows)} past-due receivables still open/partial")
for r in rows:
    print(f"  ID={r[0][:8]}.. outstanding={r[4]}, status={r[5]}, due={r[6]}, overdue={r[7]}d")

# 4. Enable pg_cron extension
print("\n=== Setting up pg_cron ===")
try:
    cur.execute("CREATE EXTENSION IF NOT EXISTS pg_cron")
    print("  pg_cron extension enabled!")
except Exception as e:
    print(f"  Error enabling pg_cron: {e}")
    # Try alternative: check if we can use it via supabase
    print("  Will try alternative approach...")

# 5. Schedule the job
try:
    cur.execute("""
        SELECT cron.schedule(
            'update-overdue-receivables',
            '0 0 * * *',
            'SELECT update_overdue_receivables()'
        )
    """)
    job_id = cur.fetchone()
    print(f"  Cron job scheduled! Job ID: {job_id}")
except Exception as e:
    print(f"  Error scheduling cron job: {e}")

# 6. Verify scheduled jobs
try:
    cur.execute("SELECT jobid, schedule, command, active FROM cron.job")
    jobs = cur.fetchall()
    print(f"\n=== Scheduled cron jobs ({len(jobs)}) ===")
    for j in jobs:
        print(f"  Job {j[0]}: {j[1]} | {j[2]} | active={j[3]}")
except Exception as e:
    print(f"  Could not list jobs: {e}")

# 7. Run the function now to mark current overdue
print("\n=== Running update_overdue_receivables() now ===")
cur.execute("SELECT update_overdue_receivables()")
print("  Done!")

# 8. Check results after run
print("\n=== Updated status summary ===")
cur.execute("""
    SELECT status, count(*), 
           sum(original_amount - paid_amount) as total_outstanding
    FROM receivables 
    GROUP BY status 
    ORDER BY status
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, outstanding={r[2]}")

cur.close()
conn.close()
