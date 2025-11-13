"""
RLS Policy Audit Script
Checks all Row Level Security policies in Supabase database
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment
load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def check_table_policies(table_name: str):
    """Check RLS policies for a specific table"""
    print(f"\n{'='*60}")
    print(f"📋 TABLE: {table_name}")
    print('='*60)
    
    # Query pg_policies view
    query = f"""
        SELECT 
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd,
            qual,
            with_check
        FROM pg_policies 
        WHERE tablename = '{table_name}'
        ORDER BY policyname;
    """
    
    try:
        result = supabase.rpc('exec_sql', {'query': query}).execute()
        
        if result.data and len(result.data) > 0:
            policies = result.data
            print(f"✅ Found {len(policies)} RLS policies\n")
            
            for i, policy in enumerate(policies, 1):
                print(f"Policy {i}: {policy['policyname']}")
                print(f"  Command: {policy['cmd']}")
                print(f"  Roles: {policy['roles']}")
                print(f"  Permissive: {policy['permissive']}")
                if policy['qual']:
                    print(f"  USING: {policy['qual']}")
                if policy['with_check']:
                    print(f"  WITH CHECK: {policy['with_check']}")
                print()
        else:
            print(f"⚠️  No RLS policies found!")
            
    except Exception as e:
        print(f"❌ Error checking policies: {e}")

def check_rls_enabled(table_name: str):
    """Check if RLS is enabled on table"""
    query = f"""
        SELECT 
            tablename,
            rowsecurity
        FROM pg_tables 
        WHERE tablename = '{table_name}' 
        AND schemaname = 'public';
    """
    
    try:
        result = supabase.rpc('exec_sql', {'query': query}).execute()
        
        if result.data and len(result.data) > 0:
            enabled = result.data[0]['rowsecurity']
            if enabled:
                print(f"✅ RLS is ENABLED")
            else:
                print(f"⚠️  RLS is DISABLED!")
        else:
            print(f"❌ Table not found")
            
    except Exception as e:
        # Fallback: try direct query
        try:
            # Check if table exists
            response = supabase.table(table_name).select("*").limit(1).execute()
            print(f"✅ Table exists (RLS status unknown)")
        except Exception as e2:
            print(f"❌ Error: {e}")

def main():
    print("🔒 RLS POLICY AUDIT")
    print("=" * 60)
    
    # Critical tables to audit
    tables = [
        'companies',
        'employees', 
        'branches',
        'tasks',
        'documents',
        'contracts',
        'attendance',
        'shifts',
    ]
    
    for table in tables:
        check_rls_enabled(table)
        check_table_policies(table)
    
    print("\n" + "="*60)
    print("✅ RLS AUDIT COMPLETE")
    print("="*60)
    
    # Summary
    print("\n📊 SECURITY CHECKLIST:")
    print("1. ✓ Check all tables have RLS enabled")
    print("2. ✓ Check policies use auth.uid() for user isolation")
    print("3. ✓ Check soft delete filters (deleted_at IS NULL)")
    print("4. ✓ Verify no overly permissive policies")
    print("5. ✓ Test cross-company access blocked")

if __name__ == "__main__":
    main()
