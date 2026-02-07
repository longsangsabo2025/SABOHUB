import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

cur.execute("""
    SELECT username, email, full_name, role 
    FROM employees 
    WHERE username IN ('driver1', 'ketoan1')
""")
for r in cur.fetchall():
    print(f"{r[0]:15} | {r[1]:30} | {r[2]:20} | {r[3]}")

conn.close()
