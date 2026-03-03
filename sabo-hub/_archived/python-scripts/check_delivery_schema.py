import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check deliveries FK constraints
cur.execute("""
SELECT conname, pg_get_constraintdef(c.oid)
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
JOIN pg_namespace n ON t.relnamespace = n.oid
WHERE t.relname = 'deliveries' AND c.contype = 'f'
ORDER BY conname;
""")
print('=== DELIVERIES FKs ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]}')

# Check columns
cur.execute("""SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'deliveries' 
ORDER BY ordinal_position""")
print('\n=== DELIVERIES COLUMNS ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]} (nullable: {row[2]})')

# Check delivery_status enum or values
cur.execute("""SELECT DISTINCT delivery_status, count(*) 
FROM sales_orders 
GROUP BY delivery_status 
ORDER BY delivery_status""")
print('\n=== SALES_ORDERS delivery_status VALUES ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]} orders')

# Check deliveries status values
cur.execute("""SELECT DISTINCT status, count(*) 
FROM deliveries 
GROUP BY status 
ORDER BY status""")
print('\n=== DELIVERIES status VALUES ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]} deliveries')

conn.close()
print('\nDone!')
