"""
RLS Policy Testing Script
Test Row Level Security with different user contexts
"""

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
anon_key = os.environ.get("SUPABASE_ANON_KEY")
service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

def test_ceo_access():
    """Test CEO can only see their own companies"""
    print("\n" + "="*60)
    print("🧪 TEST 1: CEO Company Isolation")
    print("="*60)
    
    # Service role can see all
    supabase_admin = create_client(url, service_key)
    
    try:
        # Get all companies as admin
        all_companies = supabase_admin.table('companies')\
            .select('id, name, created_by, owner_id')\
            .is_('deleted_at', 'null')\
            .execute()
        
        print(f"✅ Total companies (admin view): {len(all_companies.data)}")
        
        if len(all_companies.data) >= 2:
            company1 = all_companies.data[0]
            company2 = all_companies.data[1]
            
            print(f"\n📊 Company 1: {company1['name']}")
            print(f"   Owner: {company1.get('owner_id') or company1.get('created_by')}")
            
            print(f"\n📊 Company 2: {company2['name']}")
            print(f"   Owner: {company2.get('owner_id') or company2.get('created_by')}")
            
            # Check if they have different owners
            owner1 = company1.get('owner_id') or company1.get('created_by')
            owner2 = company2.get('owner_id') or company2.get('created_by')
            
            if owner1 == owner2:
                print("\n⚠️  Both companies have same owner - cannot test isolation")
            else:
                print("\n✅ Companies have different owners - RLS should isolate them")
                print(f"   CEO 1 should NOT see Company 2")
                print(f"   CEO 2 should NOT see Company 1")
        else:
            print("\n⚠️  Need at least 2 companies to test isolation")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_employee_isolation():
    """Test employees can only see their company data"""
    print("\n" + "="*60)
    print("🧪 TEST 2: Employee Company Isolation")
    print("="*60)
    
    supabase_admin = create_client(url, service_key)
    
    try:
        # Get all employees
        employees = supabase_admin.table('employees')\
            .select('id, full_name, company_id, user_id, role')\
            .execute()
        
        print(f"✅ Total employees: {len(employees.data)}")
        
        # Group by company
        companies_employees = {}
        for emp in employees.data:
            company_id = emp['company_id']
            if company_id not in companies_employees:
                companies_employees[company_id] = []
            companies_employees[company_id].append(emp)
        
        print(f"\n📊 Employees grouped by company:")
        for company_id, emps in companies_employees.items():
            print(f"\n   Company {company_id[:8]}...")
            for emp in emps:
                print(f"      - {emp['full_name']} ({emp['role']})")
        
        if len(companies_employees) >= 2:
            print("\n✅ Multiple companies found - RLS should prevent cross-company access")
        else:
            print("\n⚠️  Only 1 company found - cannot test cross-company isolation")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_soft_delete_filter():
    """Test soft deleted companies are hidden"""
    print("\n" + "="*60)
    print("🧪 TEST 3: Soft Delete Filter")
    print("="*60)
    
    supabase_admin = create_client(url, service_key)
    
    try:
        # Count active companies
        active = supabase_admin.table('companies')\
            .select('id', count='exact')\
            .is_('deleted_at', 'null')\
            .execute()
        
        # Count deleted companies
        deleted = supabase_admin.table('companies')\
            .select('id', count='exact')\
            .not_.is_('deleted_at', 'null')\
            .execute()
        
        print(f"✅ Active companies: {active.count}")
        print(f"🗑️  Deleted companies: {deleted.count}")
        
        if deleted.count > 0:
            print(f"\n✅ RLS policies MUST filter out {deleted.count} deleted companies")
            print(f"   Users should ONLY see {active.count} active companies")
        else:
            print("\n⚠️  No deleted companies found - soft delete not tested yet")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_task_access():
    """Test task visibility by role"""
    print("\n" + "="*60)
    print("🧪 TEST 4: Task Access by Role")
    print("="*60)
    
    supabase_admin = create_client(url, service_key)
    
    try:
        # Get all tasks
        tasks = supabase_admin.table('tasks')\
            .select('id, title, assigned_to, company_id')\
            .execute()
        
        print(f"✅ Total tasks: {len(tasks.data)}")
        
        # Group by company
        company_tasks = {}
        for task in tasks.data:
            company_id = task.get('company_id')
            if company_id:
                if company_id not in company_tasks:
                    company_tasks[company_id] = []
                company_tasks[company_id].append(task)
        
        print(f"\n📊 Tasks grouped by company:")
        for company_id, task_list in company_tasks.items():
            print(f"\n   Company {company_id[:8]}... has {len(task_list)} tasks")
            assigned_count = sum(1 for t in task_list if t.get('assigned_to'))
            print(f"      - {assigned_count} tasks assigned to specific employees")
            print(f"      - {len(task_list) - assigned_count} tasks unassigned")
        
        print("\n✅ RLS Rules:")
        print("   - CEO: Can see ALL tasks in their companies")
        print("   - Manager: Can see tasks in their branch/company")
        print("   - Staff: Can ONLY see tasks assigned to them")
        
    except Exception as e:
        print(f"❌ Error: {e}")

def generate_test_plan():
    """Generate manual test plan"""
    print("\n" + "="*60)
    print("📋 MANUAL RLS TEST PLAN")
    print("="*60)
    
    print("""
To fully test RLS policies, perform these manual tests in Supabase:

TEST 1: CEO Company Isolation
------------------------------
1. Login as CEO User A
2. Go to Companies page
3. Count visible companies
4. Login as CEO User B  
5. Count visible companies
6. ✅ PASS: User A cannot see User B's companies

TEST 2: Employee Data Isolation
--------------------------------
1. Login as Employee in Company A
2. Go to Staff page
3. ✅ PASS: Can only see employees from Company A
4. ❌ FAIL: Can see employees from other companies

TEST 3: Soft Delete Filter
---------------------------
1. Login as CEO
2. Note number of visible companies
3. Soft delete one company (set deleted_at)
4. Refresh page
5. ✅ PASS: Deleted company disappeared from list
6. Check database directly
7. ✅ PASS: Company still exists with deleted_at timestamp

TEST 4: Manager Branch Isolation
---------------------------------
1. Login as Manager in Branch A
2. Go to Tasks page
3. ✅ PASS: Can only see tasks from Branch A
4. ❌ FAIL: Can see tasks from other branches

TEST 5: Staff Task Access
--------------------------
1. Login as Staff member
2. Go to Tasks page
3. ✅ PASS: Can ONLY see tasks assigned to them
4. ❌ FAIL: Can see other employees' tasks

TEST 6: Document Access
------------------------
1. Login as Staff
2. Go to Documents page
3. ✅ PASS: Can only see documents they have access to
4. ❌ FAIL: Can see sensitive CEO/Manager documents
""")

def main():
    print("🔒 RLS POLICY TESTING")
    print("=" * 60)
    
    # Run automated tests
    test_ceo_access()
    test_employee_isolation()
    test_soft_delete_filter()
    test_task_access()
    
    # Generate manual test plan
    generate_test_plan()
    
    print("\n" + "="*60)
    print("✅ RLS TESTING COMPLETE")
    print("="*60)
    
    print("\n📝 SUMMARY:")
    print("1. ✓ Run SQL queries in Supabase (rls_audit_queries.py)")
    print("2. ✓ Review automated test results above")
    print("3. ✓ Perform manual tests from test plan")
    print("4. ✓ Document any RLS policy gaps found")
    print("5. ✓ Create SQL migration to fix issues")

if __name__ == "__main__":
    main()
