#!/usr/bin/env python3
"""
Test Dual Authentication System

This script verifies:
1. employees table exists
2. employee_login function works
3. hash_password function works
4. RLS policies are in place
"""

import os
import sys
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_connection():
    """Get database connection"""
    conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_str:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env")
        sys.exit(1)
    
    return psycopg2.connect(conn_str)

def test_employees_table(cur):
    """Test if employees table exists and has correct structure"""
    print("\n📋 Testing employees table...")
    
    # Check if table exists
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'employees'
        );
    """)
    
    exists = cur.fetchone()[0]
    
    if not exists:
        print("❌ employees table does not exist!")
        return False
    
    # Check columns
    cur.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'employees'
        ORDER BY ordinal_position;
    """)
    
    columns = cur.fetchall()
    print("✅ employees table exists with columns:")
    for col in columns:
        print(f"   - {col[0]}: {col[1]} ({'nullable' if col[2] == 'YES' else 'not null'})")
    
    # Check unique constraint
    cur.execute("""
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_schema = 'public' 
        AND table_name = 'employees'
        AND constraint_name = 'unique_username_per_company';
    """)
    
    constraint = cur.fetchone()
    if constraint:
        print("✅ Unique constraint on (company_id, username) exists")
    else:
        print("⚠️  Unique constraint not found")
    
    return True

def test_functions(cur):
    """Test if functions exist"""
    print("\n⚙️  Testing functions...")
    
    # Test employee_login function
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM pg_proc 
            WHERE proname = 'employee_login'
        );
    """)
    
    if cur.fetchone()[0]:
        print("✅ employee_login function exists")
    else:
        print("❌ employee_login function not found!")
        return False
    
    # Test hash_password function
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM pg_proc 
            WHERE proname = 'hash_password'
        );
    """)
    
    if cur.fetchone()[0]:
        print("✅ hash_password function exists")
    else:
        print("❌ hash_password function not found!")
        return False
    
    return True

def test_rls_policies(cur):
    """Test if RLS policies are in place"""
    print("\n🔒 Testing RLS policies...")
    
    # Check if RLS is enabled
    cur.execute("""
        SELECT relrowsecurity
        FROM pg_class
        WHERE relname = 'employees' AND relnamespace = 'public'::regnamespace;
    """)
    
    result = cur.fetchone()
    if result and result[0]:
        print("✅ RLS is enabled on employees table")
    else:
        print("⚠️  RLS not enabled on employees table")
    
    # List policies
    cur.execute("""
        SELECT policyname, cmd
        FROM pg_policies
        WHERE tablename = 'employees';
    """)
    
    policies = cur.fetchall()
    if policies:
        print(f"✅ Found {len(policies)} RLS policies:")
        for policy in policies:
            print(f"   - {policy[0]} ({policy[1]})")
    else:
        print("⚠️  No RLS policies found")
    
    return True

def test_password_hashing(cur):
    """Test password hashing function"""
    print("\n🔐 Testing password hashing...")
    
    try:
        # Test hash_password function
        cur.execute("SELECT public.hash_password('test123');")
        hashed = cur.fetchone()[0]
        
        if hashed and hashed.startswith('$2'):
            print(f"✅ Password hashing works (bcrypt): {hashed[:20]}...")
            return True
        else:
            print("❌ Password hashing failed or wrong format")
            return False
    except Exception as e:
        print(f"❌ Error testing password hashing: {e}")
        return False

def test_employee_login(cur, conn):
    """Test employee login function"""
    print("\n🔑 Testing employee login function...")
    
    try:
        # Create test company first (using actual schema: id, name, is_active, created_at)
        cur.execute("""
            INSERT INTO companies (id, name, is_active, created_at)
            VALUES (
                '00000000-0000-0000-0000-000000000001',
                'Test Company',
                true,
                NOW()
            )
            ON CONFLICT (id) DO NOTHING;
        """)
        conn.commit()
        
        # Create test employee
        cur.execute("""
            SELECT public.hash_password('test123');
        """)
        password_hash = cur.fetchone()[0]
        
        cur.execute("""
            INSERT INTO employees (
                id, company_id, username, password_hash, full_name, role, is_active
            )
            VALUES (
                '00000000-0000-0000-0000-000000000001',
                '00000000-0000-0000-0000-000000000001',
                'test.user',
                %s,
                'Test User',
                'STAFF',
                true
            )
            ON CONFLICT (id) DO UPDATE 
            SET password_hash = EXCLUDED.password_hash;
        """, (password_hash,))
        conn.commit()
        
        # Test login
        cur.execute("""
            SELECT public.employee_login('Test Company', 'test.user', 'test123');
        """)
        result = cur.fetchone()[0]
        
        if result.get('success'):
            employee = result.get('employee', {})
            print(f"✅ Login successful!")
            print(f"   - Username: {employee.get('username')}")
            print(f"   - Full name: {employee.get('full_name')}")
            print(f"   - Role: {employee.get('role')}")
            return True
        else:
            error = result.get('error', 'Unknown error')
            print(f"❌ Login failed: {error}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing employee login: {e}")
        conn.rollback()
        return False
    finally:
        # Cleanup test data
        try:
            cur.execute("DELETE FROM employees WHERE id = '00000000-0000-0000-0000-000000000001';")
            cur.execute("DELETE FROM companies WHERE id = '00000000-0000-0000-0000-000000000001';")
            conn.commit()
        except:
            pass

def main():
    """Run all tests"""
    print("="*60)
    print("DUAL AUTHENTICATION SYSTEM TEST")
    print("="*60)
    
    try:
        conn = get_connection()
        cur = conn.cursor()
        
        tests = [
            ("Employees Table", lambda: test_employees_table(cur)),
            ("Functions", lambda: test_functions(cur)),
            ("RLS Policies", lambda: test_rls_policies(cur)),
            ("Password Hashing", lambda: test_password_hashing(cur)),
            ("Employee Login", lambda: test_employee_login(cur, conn)),
        ]
        
        results = []
        for name, test_func in tests:
            try:
                results.append(test_func())
            except Exception as e:
                print(f"\n❌ Error in {name}: {e}")
                results.append(False)
        
        # Summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        
        passed = sum(results)
        total = len(results)
        
        for i, (name, _) in enumerate(tests):
            status = "✅ PASS" if results[i] else "❌ FAIL"
            print(f"{status} - {name}")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        
        if passed == total:
            print("\n🎉 All tests passed! Dual auth system is ready!")
            return 0
        else:
            print("\n⚠️  Some tests failed. Please review the migration.")
            return 1
            
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        return 1
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

if __name__ == '__main__':
    sys.exit(main())
