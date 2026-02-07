import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Assign Tong kho Q12 to warehouse1
cur.execute('''
    UPDATE employees 
    SET warehouse_id = '82a2f4aa-c7ca-4024-8e29-23dca57eeb70'
    WHERE username = 'warehouse1'
''')
conn.commit()
print('✅ Assigned Tong kho Q12 to warehouse1')

# Verify
cur.execute('''
    SELECT e.full_name, e.username, w.name as warehouse_name
    FROM employees e
    LEFT JOIN warehouses w ON e.warehouse_id = w.id
    WHERE e.role = 'warehouse'
''')
for row in cur.fetchall():
    print(f'   {row[1]} -> {row[2]}')
conn.close()
