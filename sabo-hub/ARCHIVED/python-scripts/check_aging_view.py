import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check the aging view definition
cur.execute("SELECT pg_get_viewdef('v_receivables_aging'::regclass, true)")
print("=== v_receivables_aging view definition ===")
print(cur.fetchone()[0])

# Check column names
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'v_receivables_aging' ORDER BY ordinal_position")
print("\n=== v_receivables_aging columns ===")
for r in cur.fetchall():
    print(f"  {r[0]}")

cur.close()
conn.close()
