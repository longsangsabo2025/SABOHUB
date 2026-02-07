import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

print("=== EMPLOYEES BY ROLE ===")
cur.execute('''
    SELECT id, username, full_name, role, company_id
    FROM employees 
    ORDER BY role, username
''')

for row in cur.fetchall():
    print(f"{row[3]:15} | {row[1]:15} | {row[2]:20} | {str(row[0])[:8]}")

conn.close()
