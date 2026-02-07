"""
Step 1: Set up pg_cron to run update_overdue_receivables() daily at midnight
"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

# 1. Check if pg_cron extension is available
print("=== Checking pg_cron availability ===")
try:
    cur.execute("SELECT * FROM pg_available_extensions WHERE name = 'pg_cron'")
    row = cur.fetchone()
    if row:
        print(f"pg_cron available: {row}")
    else:
        print("pg_cron NOT available in pg_available_extensions")
except Exception as e:
    print(f"Error checking pg_cron: {e}")

# 2. Check if cron schema exists
try:
    cur.execute("SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'cron'")
    row = cur.fetchone()
    if row:
        print(f"cron schema exists: {row}")
    else:
        print("cron schema does NOT exist")
except Exception as e:
    print(f"Error: {e}")

# 3. Check current function
print("\n=== Current update_overdue_receivables function ===")
try:
    cur.execute("""
        SELECT routine_name, data_type 
        FROM information_schema.routines 
        WHERE routine_name = 'update_overdue_receivables'
    """)
    rows = cur.fetchall()
    for r in rows:
        print(f"  {r}")
except Exception as e:
    print(f"Error: {e}")

# 4. Test calling the function directly
print("\n=== Testing update_overdue_receivables() ===")
try:
    cur.execute("SELECT update_overdue_receivables()")
    result = cur.fetchone()
    print(f"Result: {result}")
except Exception as e:
    print(f"Error calling function: {e}")

# 5. Check how many receivables are now overdue
print("\n=== Receivables status summary ===")
try:
    cur.execute("""
        SELECT status, count(*), sum(balance) 
        FROM receivables 
        GROUP BY status 
        ORDER BY status
    """)
    for r in cur.fetchall():
        print(f"  {r[0]}: {r[1]} records, balance={r[2]}")
except Exception as e:
    print(f"Error: {e}")

# 6. Check receivables with due_date in the past
print("\n=== Receivables past due date ===")
try:
    cur.execute("""
        SELECT id, customer_id, original_amount, balance, status, due_date,
               CURRENT_DATE - due_date as days_overdue
        FROM receivables 
        WHERE due_date < CURRENT_DATE AND status IN ('open', 'partial')
        ORDER BY due_date
        LIMIT 20
    """)
    rows = cur.fetchall()
    print(f"  Found {len(rows)} past-due receivables still open/partial")
    for r in rows:
        print(f"  ID={r[0]}, balance={r[3]}, status={r[4]}, due={r[5]}, overdue={r[6]}d")
except Exception as e:
    print(f"Error: {e}")

cur.close()
conn.close()
