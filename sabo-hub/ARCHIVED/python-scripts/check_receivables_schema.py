import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'receivables' ORDER BY ordinal_position")
print("=== receivables columns ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")
    
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'payment_allocations' ORDER BY ordinal_position")
print("\n=== payment_allocations columns ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

# Check constraints/unique indexes on receivables
cur.execute("""
    SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'receivables'
""")
print("\n=== receivables indexes ===")
for r in cur.fetchall():
    print(f"  {r[0]}: {r[1]}")

cur.close()
conn.close()
