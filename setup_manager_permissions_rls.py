"""
Script to setup RLS policies for manager_permissions table
"""
from supabase import create_client
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client with service role (bypasses RLS for admin operations)
SUPABASE_URL = os.getenv('SUPABASE_URL')
SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

print("=" * 70)
print("SETTING UP RLS POLICIES FOR manager_permissions TABLE")
print("=" * 70)

# SQL script to create RLS policies
sql_commands = [
    # Drop existing policies if any
    'DROP POLICY IF EXISTS "CEO can view all manager permissions in their company" ON manager_permissions;',
    'DROP POLICY IF EXISTS "CEO can insert manager permissions in their company" ON manager_permissions;',
    'DROP POLICY IF EXISTS "CEO can update manager permissions in their company" ON manager_permissions;',
    'DROP POLICY IF EXISTS "CEO can delete manager permissions in their company" ON manager_permissions;',
    'DROP POLICY IF EXISTS "Manager can view their own permissions" ON manager_permissions;',
    
    # Enable RLS
    'ALTER TABLE manager_permissions ENABLE ROW LEVEL SECURITY;',
    
    # Policy 1: CEO can SELECT
    '''CREATE POLICY "CEO can view all manager permissions in their company"
    ON manager_permissions
    FOR SELECT
    USING (
      company_id IN (
        SELECT company_id 
        FROM employees 
        WHERE id = auth.uid() 
        AND role = 'CEO'
      )
    );''',
    
    # Policy 2: CEO can INSERT
    '''CREATE POLICY "CEO can insert manager permissions in their company"
    ON manager_permissions
    FOR INSERT
    WITH CHECK (
      company_id IN (
        SELECT company_id 
        FROM employees 
        WHERE id = auth.uid() 
        AND role = 'CEO'
      )
    );''',
    
    # Policy 3: CEO can UPDATE
    '''CREATE POLICY "CEO can update manager permissions in their company"
    ON manager_permissions
    FOR UPDATE
    USING (
      company_id IN (
        SELECT company_id 
        FROM employees 
        WHERE id = auth.uid() 
        AND role = 'CEO'
      )
    )
    WITH CHECK (
      company_id IN (
        SELECT company_id 
        FROM employees 
        WHERE id = auth.uid() 
        AND role = 'CEO'
      )
    );''',
    
    # Policy 4: CEO can DELETE
    '''CREATE POLICY "CEO can delete manager permissions in their company"
    ON manager_permissions
    FOR DELETE
    USING (
      company_id IN (
        SELECT company_id 
        FROM employees 
        WHERE id = auth.uid() 
        AND role = 'CEO'
      )
    );''',
    
    # Policy 5: Manager can view their own
    '''CREATE POLICY "Manager can view their own permissions"
    ON manager_permissions
    FOR SELECT
    USING (
      manager_id = auth.uid()
    );'''
]

print("\n📋 Executing SQL commands...")
print("-" * 70)

for i, sql in enumerate(sql_commands, 1):
    try:
        # Show what we're doing
        command_type = sql.split()[0:3]
        command_desc = ' '.join(command_type)
        print(f"\n{i}. {command_desc}...")
        
        # Execute SQL using Supabase RPC or direct SQL execution
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print(f"   ✅ Success")
        
    except Exception as e:
        # If RPC doesn't work, try using PostgREST API directly
        print(f"   ⚠️ RPC failed, trying alternative method...")
        try:
            # For DDL commands, we need to use the database connection string
            import psycopg2
            conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
            conn = psycopg2.connect(conn_string)
            cur = conn.cursor()
            cur.execute(sql)
            conn.commit()
            cur.close()
            conn.close()
            print(f"   ✅ Success (via direct connection)")
        except Exception as e2:
            print(f"   ❌ Error: {e2}")

print("\n" + "=" * 70)
print("VERIFYING RLS POLICIES")
print("=" * 70)

# Verify policies were created
print("\n📊 Checking created policies...")
try:
    import psycopg2
    conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    cur.execute("""
        SELECT policyname, cmd, qual, with_check
        FROM pg_policies
        WHERE tablename = 'manager_permissions'
        ORDER BY policyname;
    """)
    
    policies = cur.fetchall()
    
    if policies:
        print(f"\n✅ Found {len(policies)} RLS policies:")
        for policy in policies:
            policy_name, cmd, qual, with_check = policy
            print(f"\n   📌 {policy_name}")
            print(f"      Command: {cmd}")
            if qual:
                print(f"      USING: {qual[:80]}...")
            if with_check:
                print(f"      WITH CHECK: {with_check[:80]}...")
    else:
        print("\n⚠️ No policies found - may need manual creation via Supabase dashboard")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Could not verify policies: {e}")
    print("\n💡 Please verify manually in Supabase dashboard:")
    print("   1. Go to Database > Policies")
    print("   2. Select 'manager_permissions' table")
    print("   3. You should see 5 policies listed")

print("\n" + "=" * 70)
print("TESTING DATA ACCESS")
print("=" * 70)

# Test if we can query the data with service role
print("\n🔍 Testing data access with service_role...")
try:
    result = supabase.from_('manager_permissions').select('*').execute()
    print(f"✅ Service role can access {len(result.data)} permission records")
    for perm in result.data:
        print(f"   - Manager ID: {perm['manager_id']}, Company ID: {perm['company_id']}")
except Exception as e:
    print(f"❌ Error: {e}")

print("\n" + "=" * 70)
print("✅ SETUP COMPLETE!")
print("=" * 70)
print("\n📱 Next steps:")
print("   1. Hot restart your Flutter app (press 'r' in terminal)")
print("   2. Login as CEO")
print("   3. Go to Company Details > Phân quyền tab")
print("   4. You should now see the 2 manager permissions!")
print("=" * 70)
