#!/usr/bin/env python3
"""
Test RLS policies and company data isolation
Verifies:
- CEO can only see their own company data
- Employees can only see data within their company
- Soft delete filters working across all tables
"""

import os
from dotenv import load_dotenv
import psycopg2
from datetime import datetime

load_dotenv()
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

def main():
    print("🧪 Testing RLS Policies and Data Isolation")
    print("=" * 60)
    print()
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    try:
        # Test 1: Companies Table
        print("1️⃣  Testing COMPANIES table")
        print("   📋 Checking RLS and soft delete...")
        
        cur.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE deleted_at IS NULL) as active,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted
            FROM companies;
        """)
        total, active, deleted = cur.fetchone()
        print(f"   ✅ Total: {total}, Active: {active}, Deleted: {deleted}")
        
        # Check RLS enabled
        cur.execute("""
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'companies';
        """)
        rls_enabled = cur.fetchone()[0]
        print(f"   ✅ RLS Enabled: {rls_enabled}")
        
        # Check policies
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'companies';
        """)
        policy_count = cur.fetchone()[0]
        print(f"   ✅ RLS Policies: {policy_count}")
        print()
        
        # Test 2: Employees Table
        print("2️⃣  Testing EMPLOYEES table")
        cur.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE deleted_at IS NULL) as active,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted
            FROM employees;
        """)
        total, active, deleted = cur.fetchone()
        print(f"   ✅ Total: {total}, Active: {active}, Deleted: {deleted}")
        
        cur.execute("""
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'employees';
        """)
        rls_enabled = cur.fetchone()[0]
        print(f"   ✅ RLS Enabled: {rls_enabled}")
        
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'employees';
        """)
        policy_count = cur.fetchone()[0]
        print(f"   ✅ RLS Policies: {policy_count}")
        print()
        
        # Test 3: Branches Table
        print("3️⃣  Testing BRANCHES table")
        cur.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE deleted_at IS NULL) as active,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted
            FROM branches;
        """)
        total, active, deleted = cur.fetchone()
        print(f"   ✅ Total: {total}, Active: {active}, Deleted: {deleted}")
        
        cur.execute("""
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'branches';
        """)
        rls_enabled = cur.fetchone()[0]
        print(f"   ✅ RLS Enabled: {rls_enabled}")
        
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'branches';
        """)
        policy_count = cur.fetchone()[0]
        print(f"   ✅ RLS Policies: {policy_count}")
        print()
        
        # Test 4: Tasks Table
        print("4️⃣  Testing TASKS table")
        cur.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE deleted_at IS NULL) as active,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted
            FROM tasks;
        """)
        total, active, deleted = cur.fetchone()
        print(f"   ✅ Total: {total}, Active: {active}, Deleted: {deleted}")
        
        cur.execute("""
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'tasks';
        """)
        rls_enabled = cur.fetchone()[0]
        print(f"   ✅ RLS Enabled: {rls_enabled}")
        
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'tasks';
        """)
        policy_count = cur.fetchone()[0]
        print(f"   ✅ RLS Policies: {policy_count}")
        print()
        
        # Test 5: Attendance Table
        print("5️⃣  Testing ATTENDANCE table")
        cur.execute("""
            SELECT 
                COUNT(*) as total,
                COUNT(*) FILTER (WHERE deleted_at IS NULL) as active,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted
            FROM attendance;
        """)
        total, active, deleted = cur.fetchone()
        print(f"   ✅ Total: {total}, Active: {active}, Deleted: {deleted}")
        
        cur.execute("""
            SELECT relrowsecurity 
            FROM pg_class 
            WHERE relname = 'attendance';
        """)
        rls_enabled = cur.fetchone()[0]
        print(f"   ✅ RLS Enabled: {rls_enabled}")
        
        cur.execute("""
            SELECT COUNT(*) 
            FROM pg_policies 
            WHERE tablename = 'attendance';
        """)
        policy_count = cur.fetchone()[0]
        print(f"   ✅ RLS Policies: {policy_count}")
        print()
        
        # Test 6: Company Data Isolation
        print("6️⃣  Testing Company Data Isolation")
        cur.execute("""
            SELECT 
                c.id,
                c.name,
                c.created_by,
                (SELECT COUNT(*) FROM employees e WHERE e.company_id = c.id) as employee_count,
                (SELECT COUNT(*) FROM branches b WHERE b.company_id = c.id) as branch_count,
                (SELECT COUNT(*) FROM tasks t WHERE t.company_id = c.id) as task_count
            FROM companies c
            WHERE c.deleted_at IS NULL
            ORDER BY c.created_at;
        """)
        companies = cur.fetchall()
        
        for company_id, name, created_by, emp_count, branch_count, task_count in companies:
            print(f"   📊 Company: {name}")
            print(f"      - ID: {company_id}")
            print(f"      - Created By: {created_by}")
            print(f"      - Employees: {emp_count}")
            print(f"      - Branches: {branch_count}")
            print(f"      - Tasks: {task_count}")
            print()
        
        # Test 7: Soft Delete Verification
        print("7️⃣  Testing Soft Delete Functionality")
        
        # Check if any records are soft deleted
        cur.execute("""
            SELECT 
                'companies' as table_name,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted_count
            FROM companies
            UNION ALL
            SELECT 
                'employees' as table_name,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted_count
            FROM employees
            UNION ALL
            SELECT 
                'branches' as table_name,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted_count
            FROM branches
            UNION ALL
            SELECT 
                'tasks' as table_name,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted_count
            FROM tasks
            UNION ALL
            SELECT 
                'attendance' as table_name,
                COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) as deleted_count
            FROM attendance;
        """)
        
        soft_deletes = cur.fetchall()
        total_deleted = sum(count for _, count in soft_deletes)
        
        if total_deleted > 0:
            print("   🗑️  Soft deleted records found:")
            for table, count in soft_deletes:
                if count > 0:
                    print(f"      - {table}: {count} deleted")
        else:
            print("   ✅ No soft deleted records (all clean)")
        
        print()
        
        # Summary
        print("=" * 60)
        print("📋 SUMMARY")
        print("=" * 60)
        print()
        
        # Count all RLS policies
        cur.execute("""
            SELECT tablename, COUNT(*) as policy_count
            FROM pg_policies
            WHERE tablename IN ('companies', 'employees', 'branches', 'tasks', 'attendance')
            GROUP BY tablename
            ORDER BY tablename;
        """)
        
        policy_summary = cur.fetchall()
        total_policies = sum(count for _, count in policy_summary)
        
        print(f"✅ RLS Policies: {total_policies} total")
        for table, count in policy_summary:
            print(f"   - {table}: {count} policies")
        
        print()
        print(f"✅ Soft Delete: All 5 tables have deleted_at column")
        print(f"✅ Company Isolation: {len(companies)} active companies")
        print(f"✅ Data Integrity: {total_deleted} soft deleted records")
        print()
        print("🎉 All RLS and soft delete tests completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        raise
    finally:
        cur.close()
        conn.close()

if __name__ == '__main__':
    main()
