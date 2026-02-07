import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()
cur.execute("SELECT prosrc FROM pg_proc WHERE proname = 'employee_login'")
row = cur.fetchone()
if row:
    print("=== employee_login function ===")
    print(row[0])
else:
    print('Function not found')
conn.close()
