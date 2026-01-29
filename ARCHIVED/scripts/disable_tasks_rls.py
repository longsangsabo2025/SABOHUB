"""
Disable RLS for tasks table
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

def disable_tasks_rls():
    """Disable RLS policies for tasks table"""
    
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not db_url:
        print("❌ Error: SUPABASE_CONNECTION_STRING not found")
        return False
    
    try:
        print("=" * 70)
        print("🔓 DISABLING RLS FOR TASKS TABLE")
        print("=" * 70)
        
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Check current RLS status
        print("\n🔍 Checking current RLS status...")
        cur.execute("""
            SELECT relname, relrowsecurity, relforcerowsecurity
            FROM pg_class
            WHERE relname = 'tasks'
        """)
        
        result = cur.fetchone()
        if result:
            table_name, rls_enabled, rls_forced = result
            print(f"   Table: {table_name}")
            print(f"   RLS Enabled: {rls_enabled}")
            print(f"   RLS Forced: {rls_forced}")
        
        # Drop all existing policies
        print("\n🗑️  Dropping all existing RLS policies...")
        cur.execute("""
            SELECT policyname 
            FROM pg_policies 
            WHERE tablename = 'tasks'
        """)
        
        policies = cur.fetchall()
        if policies:
            for policy in policies:
                policy_name = policy[0]
                print(f"   Dropping policy: {policy_name}")
                cur.execute(f"DROP POLICY IF EXISTS {policy_name} ON tasks;")
            print(f"   ✅ Dropped {len(policies)} policies")
        else:
            print("   ℹ️  No policies found")
        
        # Disable RLS
        print("\n🔓 Disabling RLS on tasks table...")
        cur.execute("ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;")
        print("   ✅ RLS disabled")
        
        # Verify RLS is disabled
        print("\n🔍 Verifying RLS status...")
        cur.execute("""
            SELECT relname, relrowsecurity, relforcerowsecurity
            FROM pg_class
            WHERE relname = 'tasks'
        """)
        
        result = cur.fetchone()
        if result:
            table_name, rls_enabled, rls_forced = result
            print(f"   Table: {table_name}")
            print(f"   RLS Enabled: {rls_enabled}")
            print(f"   RLS Forced: {rls_forced}")
            
            if not rls_enabled:
                print("\n✅ SUCCESS: RLS is now DISABLED")
            else:
                print("\n⚠️  WARNING: RLS still appears to be enabled")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ TASKS TABLE IS NOW OPEN - NO RLS!")
        print("=" * 70)
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Disabling RLS for tasks table...\n")
    success = disable_tasks_rls()
    
    if success:
        print("\n✅ You can now create tasks without RLS restrictions!")
    else:
        print("\n❌ Failed to disable RLS")
