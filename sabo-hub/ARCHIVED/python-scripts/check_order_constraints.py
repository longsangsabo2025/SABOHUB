import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
cur = conn.cursor()
cur.execute("""
    SELECT constraint_name, check_clause 
    FROM information_schema.check_constraints 
    WHERE constraint_name LIKE 'sales_orders%'
""")
for r in cur.fetchall():
    print(f"{r[0]}:\n  {r[1]}\n")
cur.execute("SELECT DISTINCT status FROM sales_orders LIMIT 20")
print("Existing statuses:", [r[0] for r in cur.fetchall()])
cur.close()
conn.close()
