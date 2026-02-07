import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check employees table schema
cur.execute('''
    SELECT column_name, data_type
    FROM information_schema.columns 
    WHERE table_name = 'employees'
    ORDER BY ordinal_position
''')

print('=== EMPLOYEES TABLE SCHEMA ===')
for row in cur.fetchall():
    print(f'{row[0]:30} | {row[1]}')

conn.close()
