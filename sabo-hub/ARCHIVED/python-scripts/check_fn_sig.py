import psycopg2
conn = psycopg2.connect("postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres")
cur = conn.cursor()

# Check function signature
cur.execute("""
    SELECT routine_name, data_type, 
           pg_get_function_arguments(p.oid) as args
    FROM information_schema.routines r
    JOIN pg_proc p ON p.proname = r.routine_name
    WHERE routine_name = 'complete_delivery_debt'
""")
for row in cur.fetchall():
    print(f"Function: {row[0]}({row[2]}) -> {row[1]}")

# Check function body
cur.execute("""
    SELECT prosrc FROM pg_proc WHERE proname = 'complete_delivery_debt'
""")
for row in cur.fetchall():
    print(f"\nBody:\n{row[0][:500]}")

cur.close()
conn.close()
