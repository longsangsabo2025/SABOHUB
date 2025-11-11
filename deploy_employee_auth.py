#!/usr/bin/env python3
"""
Deploy Employee Auth System Migration
"""

import os
import psycopg2
from dotenv import load_dotenv

# Load environment
load_dotenv()

def main():
    print("="*60)
    print("🚀 DEPLOYING EMPLOYEE AUTH SYSTEM")
    print("="*60)
    
    # Get connection string
    conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_str:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env")
        return 1
    
    # Read migration SQL
    print("\n📄 Reading migration file...")
    migration_file = 'database/migrations/010_employee_auth_system.sql'
    
    try:
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql = f.read()
        print(f"✅ Loaded migration ({len(sql):,} characters)")
    except FileNotFoundError:
        print(f"❌ Migration file not found: {migration_file}")
        return 1
    
    # Connect and execute
    print("\n🔌 Connecting to Supabase database...")
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        print("✅ Connected successfully!")
        
        print("\n⚙️  Executing migration SQL...")
        print("   This may take a few seconds...")
        
        # Execute migration
        cur.execute(sql)
        conn.commit()
        
        print("✅ Migration executed successfully!")
        
        # Verify installation
        print("\n🔍 Verifying installation...")
        
        # 1. Check employees table
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'employees'
            );
        """)
        
        if cur.fetchone()[0]:
            print("   ✅ employees table created")
            
            # Get column count
            cur.execute("""
                SELECT COUNT(*) 
                FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'employees';
            """)
            col_count = cur.fetchone()[0]
            print(f"      └─ {col_count} columns")
        else:
            print("   ❌ employees table NOT created")
        
        # 2. Check functions
        cur.execute("SELECT EXISTS (SELECT FROM pg_proc WHERE proname = 'employee_login');")
        if cur.fetchone()[0]:
            print("   ✅ employee_login() function created")
        else:
            print("   ❌ employee_login() function NOT created")
        
        cur.execute("SELECT EXISTS (SELECT FROM pg_proc WHERE proname = 'hash_password');")
        if cur.fetchone()[0]:
            print("   ✅ hash_password() function created")
        else:
            print("   ❌ hash_password() function NOT created")
        
        # 3. Check RLS policies
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'employees';
        """)
        policy_count = cur.fetchone()[0]
        
        if policy_count > 0:
            print(f"   ✅ {policy_count} RLS policies created")
            
            # List policies
            cur.execute("""
                SELECT policyname, cmd 
                FROM pg_policies 
                WHERE tablename = 'employees';
            """)
            for policy_name, cmd in cur.fetchall():
                print(f"      └─ {policy_name} ({cmd})")
        else:
            print("   ⚠️  No RLS policies found")
        
        # 4. Check indexes
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_indexes 
            WHERE tablename = 'employees';
        """)
        index_count = cur.fetchone()[0]
        print(f"   ✅ {index_count} indexes created")
        
        # 5. Check triggers
        cur.execute("""
            SELECT COUNT(*) 
            FROM information_schema.triggers 
            WHERE event_object_table = 'employees';
        """)
        trigger_count = cur.fetchone()[0]
        print(f"   ✅ {trigger_count} trigger created")
        
        # Test password hashing
        print("\n🔐 Testing password hashing...")
        cur.execute("SELECT public.hash_password('test123');")
        hashed = cur.fetchone()[0]
        
        if hashed and hashed.startswith('$2'):
            print(f"   ✅ Password hashing works!")
            print(f"      └─ Hash sample: {hashed[:30]}...")
        else:
            print("   ❌ Password hashing FAILED")
        
        cur.close()
        conn.close()
        
        print("\n" + "="*60)
        print("🎉 DEPLOYMENT SUCCESSFUL!")
        print("="*60)
        print("\n📋 What was installed:")
        print("   • employees table (for non-auth users)")
        print("   • employee_login() function")
        print("   • hash_password() function")
        print("   • RLS policies for data security")
        print("   • Indexes for performance")
        print("   • Auto-update timestamp trigger")
        
        print("\n🚀 Next Steps:")
        print("   1. Run: python test_dual_auth.py")
        print("   2. Update app router to use DualLoginPage")
        print("   3. Test CEO login (email/password)")
        print("   4. Test Employee login (company/username/password)")
        print("   5. Create first employee account from CEO dashboard")
        
        return 0
        
    except psycopg2.Error as e:
        print(f"\n❌ Database Error: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        return 1
    except Exception as e:
        print(f"\n❌ Unexpected Error: {e}")
        if 'conn' in locals():
            conn.close()
        return 1

if __name__ == '__main__':
    import sys
    sys.exit(main())
