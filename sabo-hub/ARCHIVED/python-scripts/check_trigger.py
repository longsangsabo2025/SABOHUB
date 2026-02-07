import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
cur = conn.cursor()

# Check trigger exists
print("=== Triggers on customer_payments ===")
cur.execute("""
    SELECT trigger_name, event_manipulation, action_timing, action_statement
    FROM information_schema.triggers
    WHERE event_object_table = 'customer_payments'
""")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[2]} {r[1]} -> {r[3]}")

# Check function body
print("\n=== sync_payment_to_receivables body ===")
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'sync_payment_to_receivables'")
rows = cur.fetchall()
if rows:
    print(rows[0][0])
else:
    print("  FUNCTION NOT FOUND!")

cur.close()
conn.close()
