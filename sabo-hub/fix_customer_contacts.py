import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check RLS status
cur.execute("""
SELECT relname, relrowsecurity, relforcerowsecurity 
FROM pg_class WHERE relname = 'customer_contacts'
""")
print('=== RLS STATUS ===')
print(cur.fetchall())

# Check policies
cur.execute("""
SELECT policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE tablename = 'customer_contacts'
""")
print('\n=== POLICIES ===')
rows = cur.fetchall()
if not rows:
    print('  NO POLICIES FOUND!')
else:
    for r in rows:
        print(f'  Policy: {r[0]}')
        print(f'  Permissive: {r[1]}')
        print(f'  Roles: {r[2]}')
        print(f'  Cmd: {r[3]}')
        print(f'  USING: {r[4]}')
        print(f'  WITH CHECK: {r[5]}')
        print()

# Check table structure
cur.execute("""
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customer_contacts' 
ORDER BY ordinal_position
""")
print('=== COLUMNS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} nullable={r[2]} default={r[3]}')

# Check company_id column and foreign keys
cur.execute("""
SELECT tc.constraint_name, kcu.column_name, ccu.table_name AS ref_table, ccu.column_name AS ref_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'customer_contacts' AND tc.constraint_type = 'FOREIGN KEY'
""")
print('\n=== FOREIGN KEYS ===')
for r in cur.fetchall():
    print(f'  {r[0]}: {r[1]} -> {r[2]}.{r[3]}')

# Also check customer_addresses
cur.execute("""
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'customer_addresses'
""")
print('\n=== customer_addresses RLS STATUS ===')
print(cur.fetchall())

cur.execute("""
SELECT policyname, cmd, qual, with_check
FROM pg_policies WHERE tablename = 'customer_addresses'
""")
print('\n=== customer_addresses POLICIES ===')
for r in cur.fetchall():
    print(f'  {r[0]}: cmd={r[1]} USING={r[2]} WITH CHECK={r[3]}')

conn.close()
