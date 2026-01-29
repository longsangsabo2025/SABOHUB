"""
Tự động DISABLE RLS cho tất cả các bảng (CHỈ DÙNG TRONG DEVELOPMENT!)
⚠️ WARNING: Removes all security! Only use in development!
"""
import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get connection string
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

if not conn_string:
    print("❌ ERROR: SUPABASE_CONNECTION_STRING not found in .env")
    exit(1)

def disable_all_rls():
    """Disable RLS for all tables"""
    print("\n" + "="*70)
    print("⚠️  DISABLING RLS FOR ALL TABLES (DEVELOPMENT MODE)")
    print("="*70)
    
    try:
        # Connect to database with timeout
        print("\n🔌 Connecting to database...")
        
        conn = psycopg2.connect(
            conn_string,
            connect_timeout=10,
            options='-c statement_timeout=30000'
        )
        cur = conn.cursor()
        print("   ✅ Connected!")
        
        # List of tables to disable RLS
        tables = [
            'users', 'companies', 'branches', 'tables',
            'orders', 'order_items', 'time_slots',
            'management_tasks', 'ai_conversations',
            'ai_messages', 'ai_uploaded_files'
        ]
        
        print("\n1️⃣ Disabling RLS on tables...")
        for table in tables:
            try:
                cur.execute(f"ALTER TABLE {table} DISABLE ROW LEVEL SECURITY;")
                conn.commit()  # Commit after each table
                print(f"   ✅ {table}")
            except Exception as e:
                conn.rollback()  # Rollback failed transaction
                print(f"   ⚠️  {table}: {str(e)[:80]}")
        
        print("\n2️⃣ Dropping all policies...")
        
        # Get all policies
        cur.execute("""
            SELECT tablename, policyname 
            FROM pg_policies 
            WHERE schemaname = 'public'
        """)
        
        policies = cur.fetchall()
        
        if policies:
            print(f"   Found {len(policies)} policies to drop:")
            for table, policy in policies:
                try:
                    cur.execute(f'DROP POLICY IF EXISTS "{policy}" ON {table};')
                    print(f"   ✅ {table}.{policy}")
                except Exception as e:
                    print(f"   ⚠️  {table}.{policy}: {str(e)[:60]}")
            
            conn.commit()
        else:
            print("   ℹ️  No policies found")
        
        print("\n3️⃣ Verifying RLS status...")
        cur.execute("""
            SELECT 
                tablename,
                CASE WHEN rowsecurity THEN '🔒 ENABLED' ELSE '✅ DISABLED' END as status
            FROM pg_tables 
            WHERE schemaname = 'public' 
              AND tablename IN (
                'users', 'companies', 'branches', 'tables', 
                'orders', 'order_items', 'time_slots',
                'management_tasks', 'ai_conversations', 
                'ai_messages', 'ai_uploaded_files'
              )
            ORDER BY tablename;
        """)
        
        results = cur.fetchall()
        for table, status in results:
            print(f"   {status} {table}")
        
        # Close connection
        cur.close()
        conn.close()
        
        print("\n" + "="*70)
        print("✅ SUCCESS! RLS DISABLED FOR ALL TABLES")
        print("="*70)
        print("\n📝 Notes:")
        print("   • All users can now read/write all data")
        print("   • NO SECURITY - Only for development!")
        print("   • Press 'R' in Flutter terminal to hot reload")
        print("   • Dropdown 'Công ty' should now show 'SABO Billiards'")
        print("\n⚠️  REMEMBER: Re-enable RLS before production!")
        print("="*70)
        
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        print("\nℹ️  Make sure:")
        print("   1. SUPABASE_CONNECTION_STRING is correct in .env")
        print("   2. You have admin access to the database")
        print("   3. psycopg2 is installed: pip install psycopg2-binary")

if __name__ == '__main__':
    print("\n⚠️  WARNING: This will DISABLE ALL SECURITY on your database!")
    print("Only proceed if you understand the risks.\n")
    
    response = input("Type 'YES' to continue: ")
    
    if response.upper() == 'YES':
        disable_all_rls()
    else:
        print("\n❌ Cancelled. No changes made.")
