import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('='*100)
print('🔧 FIXING UPDATE POLICY - MAKING IT MORE PERMISSIVE')
print('='*100)
print()

conn = psycopg2.connect(conn_string)
cur = conn.cursor()

# Drop existing update policy
print('1️⃣  Dropping old update policy...')
cur.execute('DROP POLICY IF EXISTS "users_update_own" ON users')
conn.commit()
print('   ✅ Dropped')
print()

# Create new, more permissive update policy
print('2️⃣  Creating new update policy (authenticated users can update their own row)...')
sql = """
CREATE POLICY "users_update_own" ON users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid())
"""
cur.execute(sql)
conn.commit()
print('   ✅ Created')
print()

# Verify
print('3️⃣  Verifying policy...')
cur.execute("""
    SELECT policyname, cmd, qual, with_check 
    FROM pg_policies 
    WHERE tablename = 'users' AND policyname = 'users_update_own'
""")
result = cur.fetchone()

if result:
    print(f'   ✅ Policy exists:')
    print(f'      Name: {result[0]}')
    print(f'      Command: {result[1]}')
    print(f'      USING: {result[2]}')
    print(f'      WITH CHECK: {result[3]}')
else:
    print('   ❌ Policy not found!')

print()

cur.close()
conn.close()

print('='*100)
print('✅ POLICY UPDATED! Now try updating profile in the app!')
print('='*100)
