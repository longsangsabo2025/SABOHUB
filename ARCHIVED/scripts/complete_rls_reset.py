import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('='*100)
print('🔥 COMPLETE RLS POLICY RESET - REMOVING ALL POLICIES')
print('='*100)
print()

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    print('✅ Connected to database')
    print()
    
    # Step 1: Get ALL existing policies
    print('📋 Step 1: Finding ALL existing policies...')
    cur.execute("SELECT policyname FROM pg_policies WHERE tablename = 'users'")
    policies = cur.fetchall()
    
    print(f'Found {len(policies)} policies to remove:')
    for policy in policies:
        print(f'   - {policy[0]}')
    print()
    
    # Step 2: Drop ALL policies
    print('🗑️  Step 2: Dropping ALL policies...')
    for policy in policies:
        policy_name = policy[0]
        try:
            sql = f'DROP POLICY IF EXISTS "{policy_name}" ON users'
            cur.execute(sql)
            conn.commit()
            print(f'   ✅ Dropped: {policy_name}')
        except Exception as e:
            print(f'   ⚠️  Error dropping {policy_name}: {str(e)[:50]}')
            conn.rollback()
    print()
    
    # Step 3: Verify all dropped
    print('🔍 Step 3: Verifying all policies removed...')
    cur.execute("SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users'")
    count = cur.fetchone()[0]
    print(f'   Remaining policies: {count}')
    print()
    
    # Step 4: Create simple, non-recursive policies
    print('📝 Step 4: Creating NEW simple policies...')
    
    new_policies = [
        ('users_select_own', 'CREATE POLICY users_select_own ON users FOR SELECT TO authenticated USING (auth.uid() = id)'),
        ('users_update_own', 'CREATE POLICY users_update_own ON users FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id)'),
        ('users_insert_own', 'CREATE POLICY users_insert_own ON users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id)'),
        ('service_role_all', 'CREATE POLICY service_role_all ON users FOR ALL TO service_role USING (true) WITH CHECK (true)'),
    ]
    
    for policy_name, sql in new_policies:
        try:
            cur.execute(sql)
            conn.commit()
            print(f'   ✅ Created: {policy_name}')
        except Exception as e:
            print(f'   ⚠️  Error: {str(e)[:100]}')
            conn.rollback()
    print()
    
    # Step 5: Final verification
    print('🔍 Step 5: Final verification...')
    cur.execute("SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users' ORDER BY policyname")
    final_policies = cur.fetchall()
    
    print(f'✅ Final policy count: {len(final_policies)}')
    for policy_name, cmd in final_policies:
        print(f'   - {policy_name} ({cmd})')
    print()
    
    cur.close()
    conn.close()
    
    print('='*100)
    print('✅ COMPLETE RESET SUCCESSFUL!')
    print('='*100)
    print()
    print('🎯 NOW TRY TO LOGIN AGAIN!')
    
except Exception as e:
    print(f'❌ Fatal Error: {str(e)}')
    import traceback
    traceback.print_exc()
