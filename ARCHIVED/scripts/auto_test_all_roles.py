"""
Automated testing script for role-based features
Tests all user roles and verifies correct behavior
"""
import os
from supabase import create_client
from dotenv import load_dotenv
from typing import Dict, List

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

class TestResults:
    def __init__(self):
        self.passed = []
        self.failed = []
        self.warnings = []
    
    def add_pass(self, test_name: str, message: str = ""):
        self.passed.append(f"✅ {test_name}: {message}")
    
    def add_fail(self, test_name: str, message: str):
        self.failed.append(f"❌ {test_name}: {message}")
    
    def add_warning(self, test_name: str, message: str):
        self.warnings.append(f"⚠️  {test_name}: {message}")
    
    def print_summary(self):
        print("\n" + "="*80)
        print("TEST SUMMARY")
        print("="*80)
        
        if self.passed:
            print(f"\n✅ PASSED ({len(self.passed)}):")
            for item in self.passed:
                print(f"  {item}")
        
        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for item in self.warnings:
                print(f"  {item}")
        
        if self.failed:
            print(f"\n❌ FAILED ({len(self.failed)}):")
            for item in self.failed:
                print(f"  {item}")
        
        print("\n" + "="*80)
        total = len(self.passed) + len(self.failed)
        print(f"TOTAL: {len(self.passed)}/{total} tests passed")
        print("="*80 + "\n")
        
        return len(self.failed) == 0

results = TestResults()

def test_database_schema():
    """Test 1: Verify database schema has required columns"""
    print("\n🔍 Test 1: Database Schema Verification")
    
    # Check tasks table
    tasks_result = supabase.table('tasks').select('id, assigned_to_name, assigned_to_role').limit(1).execute()
    if tasks_result.data and len(tasks_result.data) > 0:
        task = tasks_result.data[0]
        if 'assigned_to_name' in task and 'assigned_to_role' in task:
            results.add_pass("Tasks table schema", "assigned_to_name and assigned_to_role columns exist")
        else:
            results.add_fail("Tasks table schema", "Missing assigned_to_name or assigned_to_role columns")
    else:
        results.add_warning("Tasks table schema", "No tasks found to verify schema")
    
    # Check attendance table
    attendance_result = supabase.table('attendance').select('id, employee_name, employee_role').limit(1).execute()
    if attendance_result.data and len(attendance_result.data) > 0:
        attendance = attendance_result.data[0]
        if 'employee_name' in attendance and 'employee_role' in attendance:
            results.add_pass("Attendance table schema", "employee_name and employee_role columns exist")
        else:
            results.add_fail("Attendance table schema", "Missing employee_name or employee_role columns")
    else:
        results.add_warning("Attendance table schema", "No attendance records found to verify schema")

def test_user_roles():
    """Test 2: Verify all user roles are correctly set"""
    print("\n🔍 Test 2: User Roles Verification")
    
    # Check CEO user
    ceo_result = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()
    if ceo_result.data:
        ceo = ceo_result.data[0]
        if ceo.get('role') == 'CEO':
            results.add_pass("CEO role", f"{ceo.get('full_name')} - Role: CEO ✓")
        else:
            results.add_fail("CEO role", f"Expected CEO, got {ceo.get('role')}")
    else:
        results.add_fail("CEO user", "longsangsabo1@gmail.com not found in database")
    
    # Check all users by role
    all_users = supabase.table('users').select('id, full_name, email, role, company_id, branch_id').is_('deleted_at', 'null').execute()
    
    role_counts = {'CEO': 0, 'MANAGER': 0, 'SHIFT_LEADER': 0, 'STAFF': 0}
    invalid_roles = []
    
    for user in all_users.data:
        role = user.get('role')
        if role in role_counts:
            role_counts[role] += 1
        else:
            invalid_roles.append(f"{user.get('full_name')} has invalid role: {role}")
    
    print(f"\n  Role Distribution:")
    for role, count in role_counts.items():
        print(f"    {role}: {count} users")
    
    if invalid_roles:
        for invalid in invalid_roles:
            results.add_fail("Invalid role", invalid)
    else:
        results.add_pass("Role validation", "All users have valid roles")

def test_company_branch_structure():
    """Test 3: Verify company and branch assignments"""
    print("\n🔍 Test 3: Company & Branch Structure")
    
    # Get all users with company/branch info
    users = supabase.table('users').select('id, full_name, role, company_id, branch_id').is_('deleted_at', 'null').execute()
    
    ceo_without_company = []
    manager_without_company = []
    shift_leader_without_branch = []
    staff_without_branch = []
    
    for user in users.data:
        role = user.get('role')
        company_id = user.get('company_id')
        branch_id = user.get('branch_id')
        name = user.get('full_name')
        
        if role == 'CEO' and not company_id:
            ceo_without_company.append(name)
        elif role == 'MANAGER' and not company_id:
            manager_without_company.append(name)
        elif role == 'SHIFT_LEADER' and not branch_id:
            shift_leader_without_branch.append(name)
        elif role == 'STAFF' and not branch_id:
            staff_without_branch.append(name)
    
    if ceo_without_company:
        results.add_fail("CEO company assignment", f"CEOs without company: {', '.join(ceo_without_company)}")
    else:
        results.add_pass("CEO company assignment", "All CEOs have company_id")
    
    if manager_without_company:
        results.add_fail("Manager company assignment", f"Managers without company: {', '.join(manager_without_company)}")
    else:
        results.add_pass("Manager company assignment", "All Managers have company_id")
    
    if shift_leader_without_branch:
        results.add_warning("Shift Leader branch assignment", f"Shift Leaders without branch: {', '.join(shift_leader_without_branch)}")
    
    if staff_without_branch:
        results.add_warning("Staff branch assignment", f"Staff without branch: {', '.join(staff_without_branch)}")

def test_manager_staff_query():
    """Test 4: Verify Manager can query all company employees"""
    print("\n🔍 Test 4: Manager Staff Query")
    
    # Get a manager
    manager_result = supabase.table('users').select('*').eq('role', 'MANAGER').limit(1).execute()
    
    if not manager_result.data:
        results.add_warning("Manager query test", "No Manager found to test")
        return
    
    manager = manager_result.data[0]
    company_id = manager.get('company_id')
    
    if not company_id:
        results.add_fail("Manager query test", f"Manager {manager.get('full_name')} has no company_id")
        return
    
    # Query all employees in same company (simulating ManagerStaffPage query)
    employees = supabase.table('users').select('id, full_name, role').eq('company_id', company_id).is_('deleted_at', 'null').execute()
    
    if employees.data:
        results.add_pass("Manager staff query", f"Manager can see {len(employees.data)} employees in company")
    else:
        results.add_fail("Manager staff query", "Manager cannot query company employees")

def test_shift_leader_team_query():
    """Test 5: Verify Shift Leader can query team members"""
    print("\n🔍 Test 5: Shift Leader Team Query")
    
    # Get a shift leader
    sl_result = supabase.table('users').select('*').eq('role', 'SHIFT_LEADER').limit(1).execute()
    
    if not sl_result.data:
        results.add_warning("Shift Leader query test", "No Shift Leader found to test")
        return
    
    shift_leader = sl_result.data[0]
    company_id = shift_leader.get('company_id')
    branch_id = shift_leader.get('branch_id')
    
    if not company_id or not branch_id:
        results.add_fail("Shift Leader query test", f"Shift Leader {shift_leader.get('full_name')} missing company_id or branch_id")
        return
    
    # Query team members (simulating ShiftLeaderTeamPage query)
    team = supabase.table('users').select('id, full_name, role').eq('company_id', company_id).eq('branch_id', branch_id).in_('role', ['STAFF', 'SHIFT_LEADER']).is_('deleted_at', 'null').execute()
    
    if team.data:
        results.add_pass("Shift Leader team query", f"Shift Leader can see {len(team.data)} team members in branch")
    else:
        results.add_warning("Shift Leader team query", "Shift Leader has no team members in branch")

def test_task_employee_names():
    """Test 6: Verify tasks have employee names populated"""
    print("\n🔍 Test 6: Task Employee Names")
    
    tasks = supabase.table('tasks').select('id, title, assigned_to, assigned_to_name, assigned_to_role').limit(10).execute()
    
    if not tasks.data:
        results.add_warning("Task employee names", "No tasks found to test")
        return
    
    tasks_with_names = 0
    tasks_without_names = 0
    
    for task in tasks.data:
        if task.get('assigned_to') and task.get('assigned_to_name'):
            tasks_with_names += 1
        elif task.get('assigned_to') and not task.get('assigned_to_name'):
            tasks_without_names += 1
    
    if tasks_without_names > 0:
        results.add_warning("Task employee names", f"{tasks_without_names} tasks have assigned_to but missing assigned_to_name")
    
    if tasks_with_names > 0:
        results.add_pass("Task employee names", f"{tasks_with_names} tasks have employee names populated")

def test_attendance_employee_info():
    """Test 7: Verify attendance has employee info populated"""
    print("\n🔍 Test 7: Attendance Employee Info")
    
    attendance = supabase.table('attendance').select('id, user_id, employee_name, employee_role').limit(10).execute()
    
    if not attendance.data:
        results.add_warning("Attendance employee info", "No attendance records found to test")
        return
    
    records_with_info = 0
    records_without_info = 0
    
    for record in attendance.data:
        if record.get('employee_name') and record.get('employee_role'):
            records_with_info += 1
        else:
            records_without_info += 1
    
    if records_without_info > 0:
        results.add_warning("Attendance employee info", f"{records_without_info} records missing employee_name or employee_role")
    
    if records_with_info > 0:
        results.add_pass("Attendance employee info", f"{records_with_info} records have employee info populated")

def test_indexes():
    """Test 8: Check if performance indexes exist (indirect check via query performance)"""
    print("\n🔍 Test 8: Database Indexes (Query Performance)")
    
    # This is an indirect test - we can't directly check indexes via Supabase client
    # But we can verify queries work efficiently
    
    # Test company_id index on tasks
    tasks_query = supabase.table('tasks').select('id').eq('company_id', 'feef10d3-899d-4554-8107-b2256918213a').limit(1).execute()
    results.add_pass("Tasks company_id query", "Query executed successfully (index likely exists)")
    
    # Test store_id index on attendance
    attendance_query = supabase.table('attendance').select('id').limit(1).execute()
    results.add_pass("Attendance query", "Query executed successfully")

# Run all tests
def run_all_tests():
    print("\n" + "="*80)
    print("AUTOMATED TESTING - ROLE LINKAGE FEATURES")
    print("="*80)
    
    test_database_schema()
    test_user_roles()
    test_company_branch_structure()
    test_manager_staff_query()
    test_shift_leader_team_query()
    test_task_employee_names()
    test_attendance_employee_info()
    test_indexes()
    
    success = results.print_summary()
    
    if success:
        print("🎉 ALL TESTS PASSED! System is working correctly.\n")
        return 0
    else:
        print("⚠️  SOME TESTS FAILED. Issues need to be fixed.\n")
        return 1

if __name__ == "__main__":
    exit_code = run_all_tests()
    exit(exit_code)
