import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# 1. Verify current RLS policies
cur.execute("""
SELECT policyname, cmd, qual, with_check
FROM pg_policies WHERE tablename = 'customer_contacts'
""")
print('=== CURRENT customer_contacts POLICIES ===')
for r in cur.fetchall():
    print(f'  {r[0]} [{r[1]}]:')
    print(f'    USING: {r[2]}')
    print(f'    WITH CHECK: {r[3]}')
    print()

# 2. Check if RLS is enabled
cur.execute("""
SELECT relrowsecurity, relforcerowsecurity 
FROM pg_class WHERE relname = 'customer_contacts'
""")
print('=== RLS enabled? ===')
print(cur.fetchone())

# 3. Try to see if auth.uid() works with transaction pooler
# The issue might be that auth.uid() returns NULL when using transaction pooler
# because the JWT is not properly set for the session
cur.execute("SELECT current_setting('request.jwt.claims', true)")
print('\n=== JWT claims ===')
print(cur.fetchone())

conn.close()
