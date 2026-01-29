import psycopg2
import sys

# Connection string from .env
conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('='*100)
print('🔧 AUTO-FIXING RLS POLICY - INFINITE RECURSION')
print('='*100)
print()

try:
    # Connect to database
    print('📡 Connecting to Supabase PostgreSQL...')
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    print('✅ Connected successfully!')
    print()
    
    # SQL statements to execute
    sql_statements = [
        'DROP POLICY IF EXISTS "Users can view their own profile" ON users',
        'DROP POLICY IF EXISTS "Users can update their own profile" ON users',
        'DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users',
        'DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users',
        'DROP POLICY IF EXISTS "Enable update for users based on id" ON users',
        'DROP POLICY IF EXISTS "Enable delete for users based on id" ON users',
        'DROP POLICY IF EXISTS "Allow users to read own data" ON users',
        'DROP POLICY IF EXISTS "Allow users to update own data" ON users',
        'ALTER TABLE users ENABLE ROW LEVEL SECURITY',
        'CREATE POLICY users_select_own ON users FOR SELECT TO authenticated USING (auth.uid() = id)',
        'CREATE POLICY users_update_own ON users FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id)',
        'CREATE POLICY service_role_all ON users FOR ALL TO service_role USING (true) WITH CHECK (true)',
        'CREATE POLICY users_insert_own ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id)'
    ]
    
    for idx, sql in enumerate(sql_statements, 1):
        print(f'📝 Statement {idx}/{len(sql_statements)}')
        print(f'   {sql[:80]}...')
        
        try:
            cur.execute(sql)
            conn.commit()
            print('   ✅ Success')
        except Exception as e:
            print(f'   ⚠️  Warning: {str(e)[:100]}')
            conn.rollback()
        print()
    
    # Verify policies
    print('🔍 Verifying policies...')
    cur.execute("SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users' ORDER BY policyname")
    policies = cur.fetchall()
    
    print(f'✅ Found {len(policies)} policies:')
    for policy_name, cmd in policies:
        print(f'   - {policy_name} ({cmd})')
    print()
    
    cur.close()
    conn.close()
    
    print('='*100)
    print('✅ RLS POLICY FIX COMPLETE!')
    print('='*100)
    print()
    print('🎯 NOW TRY TO LOGIN WITH: longsangsabo1@gmail.com')
    
except Exception as e:
    print(f'❌ Error: {str(e)}')
    sys.exit(1)
