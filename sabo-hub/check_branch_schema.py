import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# 1. Check customer_contacts columns
cur.execute("""
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customer_contacts' 
ORDER BY ordinal_position
""")
print('=== customer_contacts COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} nullable={r[2]} default={r[3]}')

# 2. Check customer_addresses columns
cur.execute("""
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customer_addresses' 
ORDER BY ordinal_position
""")
print('\n=== customer_addresses COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} nullable={r[2]} default={r[3]}')

# 3. Check sales_orders - does it have delivery_address_id or address_id?
cur.execute("""
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'sales_orders' 
ORDER BY ordinal_position
""")
print('\n=== sales_orders COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} nullable={r[2]} default={r[3]}')

# 4. Check if there's any branch-related table
cur.execute("""
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND (table_name LIKE '%branch%' OR table_name LIKE '%location%' OR table_name LIKE '%outlet%')
ORDER BY table_name
""")
print('\n=== branch/location related tables ===')
rows = cur.fetchall()
if not rows:
    print('  NONE found')
else:
    for r in rows:
        print(f'  {r[0]}')

# 5. Check FK from sales_orders to customer_addresses
cur.execute("""
SELECT tc.constraint_name, kcu.column_name, ccu.table_name, ccu.column_name AS ref_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'sales_orders' 
AND tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_name IN ('customer_addresses', 'customer_contacts')
""")
print('\n=== sales_orders FK to addresses/contacts ===')
rows = cur.fetchall()
if not rows:
    print('  NO FK to customer_addresses or customer_contacts')
else:
    for r in rows:
        print(f'  {r[0]}: {r[1]} -> {r[2]}.{r[3]}')

# 6. Check if sales_orders has delivery address columns
cur.execute("""
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'sales_orders' 
AND (column_name LIKE '%address%' OR column_name LIKE '%delivery%' OR column_name LIKE '%branch%')
""")
print('\n=== sales_orders address/delivery columns ===')
for r in cur.fetchall():
    print(f'  {r[0]}')

conn.close()
