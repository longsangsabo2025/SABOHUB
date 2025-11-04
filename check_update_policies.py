import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('='*100)
print('🔍 CHECKING UPDATE POLICIES ON USERS TABLE')
print('='*100)
print()

conn = psycopg2.connect(conn_string)
cur = conn.cursor()

# Check UPDATE policies
cur.execute("""
    SELECT policyname, cmd, qual, with_check 
    FROM pg_policies 
    WHERE tablename = 'users' AND cmd = 'UPDATE'
    ORDER BY policyname
""")

policies = cur.fetchall()

if policies:
    print(f'✅ Found {len(policies)} UPDATE policies:')
    print()
    for policy_name, cmd, qual, with_check in policies:
        print(f'📋 Policy: {policy_name}')
        print(f'   Command: {cmd}')
        print(f'   USING clause: {qual}')
        print(f'   WITH CHECK clause: {with_check}')
        print()
else:
    print('❌ NO UPDATE POLICIES FOUND!')
    print('   This means users CANNOT update their own data!')
    print()

# Check if user's auth.uid() matches their ID
print('🔍 Testing auth.uid() function...')
cur.execute("SELECT auth.uid() as current_user_id")
result = cur.fetchone()
print(f'   Current auth.uid(): {result[0] if result else "NULL"}')
print()

cur.close()
conn.close()

print('='*100)
