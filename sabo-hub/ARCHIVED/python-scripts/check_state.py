"""Quick check of receivables current state"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
cur = conn.cursor()

print("=== Receivables summary ===")
cur.execute("""
    SELECT status, count(*), 
           sum(original_amount) as original,
           sum(paid_amount) as paid,
           sum(original_amount - paid_amount) as outstanding
    FROM receivables GROUP BY status ORDER BY status
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, original={r[2]}, paid={r[3]}, outstanding={r[4]}")

print("\n=== Aging buckets ===")
cur.execute("""
    SELECT aging_bucket, count(*), sum(balance) 
    FROM v_receivables_aging GROUP BY aging_bucket ORDER BY aging_bucket
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]} records, balance={r[2]}")

print("\n=== Cron jobs ===")
cur.execute("SELECT jobid, schedule, command, active FROM cron.job")
for j in cur.fetchall():
    print(f"  Job {j[0]}: {j[1]} | {j[2]} | active={j[3]}")

print("\n=== Total customers with receivables ===")
cur.execute("SELECT count(DISTINCT customer_id) FROM receivables")
print(f"  {cur.fetchone()[0]}")

cur.close()
conn.close()
