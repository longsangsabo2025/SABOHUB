"""
Script to disable RLS on manager_permissions table completely
"""
from supabase import create_client
import os
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv()

# Database connection
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("=" * 70)
print("DISABLING RLS ON manager_permissions TABLE")
print("=" * 70)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Drop all policies
    print("\n1. Dropping all RLS policies...")
    policies_to_drop = [
        "CEO can view all manager permissions in their company",
        "CEO can insert manager permissions in their company",
        "CEO can update manager permissions in their company",
        "CEO can delete manager permissions in their company",
        "Manager can view their own permissions",
        "CEO can view manager permissions",
        "CEO can manage manager permissions",
        "Manager can view own permissions"
    ]
    
    for policy_name in policies_to_drop:
        try:
            sql = f'DROP POLICY IF EXISTS "{policy_name}" ON manager_permissions;'
            cur.execute(sql)
            print(f"   ✅ Dropped: {policy_name}")
        except Exception as e:
            print(f"   ⚠️ {policy_name}: {e}")
    
    conn.commit()
    
    # Disable RLS completely
    print("\n2. Disabling RLS on manager_permissions table...")
    cur.execute("ALTER TABLE manager_permissions DISABLE ROW LEVEL SECURITY;")
    conn.commit()
    print("   ✅ RLS DISABLED!")
    
    # Verify
    print("\n3. Verifying...")
    cur.execute("""
        SELECT relname, relrowsecurity 
        FROM pg_class 
        WHERE relname = 'manager_permissions';
    """)
    result = cur.fetchone()
    if result:
        table_name, rls_enabled = result
        if not rls_enabled:
            print(f"   ✅ RLS is OFF for table '{table_name}'")
        else:
            print(f"   ⚠️ RLS is still ON for table '{table_name}'")
    
    # Check remaining policies
    cur.execute("""
        SELECT COUNT(*) 
        FROM pg_policies 
        WHERE tablename = 'manager_permissions';
    """)
    policy_count = cur.fetchone()[0]
    print(f"   📊 Remaining policies: {policy_count}")
    
    cur.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ DONE! RLS completely disabled on manager_permissions")
    print("=" * 70)
    print("\n📱 Now hot restart Flutter app (press 'R' in terminal)")
    print("   CEO should be able to access all data without RLS restrictions!")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
