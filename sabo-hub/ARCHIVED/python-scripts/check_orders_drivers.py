import psycopg2
conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check all orders status
cur.execute('''
    SELECT id, order_number, status, delivery_status, warehouse_id
    FROM sales_orders 
    ORDER BY created_at DESC
    LIMIT 10
''')

print('=== SALES ORDERS STATUS ===')
print(f'{"ID"[:8]:10} | {"Order#":10} | {"Status":15} | {"Delivery Status":20} | Warehouse')
print('-' * 80)
for row in cur.fetchall():
    wh = str(row[4])[:8] if row[4] else 'None'
    print(f'{str(row[0])[:8]:10} | {str(row[1] or ""):10} | {str(row[2] or ""):15} | {str(row[3] or ""):20} | {wh}')

# Check drivers
print()
print('=== DRIVERS ===')
cur.execute('''
    SELECT id, full_name, username FROM employees WHERE role = 'driver'
''')
for row in cur.fetchall():
    print(f'{row[0]} | {row[1]} ({row[2]})')

conn.close()
