"""
Check employees relationships using Transaction Pooler
Direct SQL queries to verify foreign keys and data
"""

import psycopg2
from psycopg2.extras import RealDictCursor

# Transaction pooler connection string from .env
conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('=' * 100)
print('🔍 CHECKING EMPLOYEES RELATIONSHIPS - Transaction Pooler')
print('=' * 100)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # 1. Check employees table data
    print('\n1️⃣ EMPLOYEES TABLE DATA')
    print('-' * 100)
    cursor.execute("""
        SELECT id, full_name, email, role, company_id, branch_id, is_active
        FROM employees
        ORDER BY role, full_name
    """)
    employees = cursor.fetchall()
    print(f'   Total: {len(employees)} employees')
    for emp in employees:
        print(f'\n   👤 {emp["full_name"]} ({emp["role"]})')
        print(f'      Email: {emp["email"]}')
        print(f'      Company ID: {emp["company_id"]}')
        print(f'      Branch ID: {emp["branch_id"]}')
        print(f'      Active: {emp["is_active"]}')
    
    # 2. Check foreign keys FROM employees table
    print('\n\n2️⃣ FOREIGN KEYS FROM EMPLOYEES')
    print('-' * 100)
    
    # Check employees → companies
    cursor.execute("""
        SELECT 
            e.full_name,
            e.company_id,
            c.name as company_name
        FROM employees e
        LEFT JOIN companies c ON e.company_id = c.id
        WHERE e.company_id IS NOT NULL
    """)
    emp_companies = cursor.fetchall()
    if emp_companies:
        print(f'\n   ✅ employees.company_id → companies.id: {len(emp_companies)} linked')
        for row in emp_companies:
            print(f'      {row["full_name"]} → {row["company_name"]}')
    else:
        print('   ⚠️  No employees linked to companies')
    
    # Check employees → branches
    cursor.execute("""
        SELECT 
            e.full_name,
            e.branch_id,
            b.name as branch_name
        FROM employees e
        LEFT JOIN branches b ON e.branch_id = b.id
        WHERE e.branch_id IS NOT NULL
    """)
    emp_branches = cursor.fetchall()
    if emp_branches:
        print(f'\n   ✅ employees.branch_id → branches.id: {len(emp_branches)} linked')
        for row in emp_branches:
            print(f'      {row["full_name"]} → {row["branch_name"]}')
    else:
        print('   ⚠️  No employees linked to branches')
    
    # 3. Check foreign keys TO employees table
    print('\n\n3️⃣ FOREIGN KEYS TO EMPLOYEES')
    print('-' * 100)
    
    # Check attendance → employees
    cursor.execute("""
        SELECT 
            COUNT(*) as count,
            COUNT(DISTINCT a.user_id) as unique_employees
        FROM attendance a
        WHERE EXISTS (SELECT 1 FROM employees e WHERE e.id = a.user_id)
    """)
    att_check = cursor.fetchone()
    if att_check and att_check['count'] > 0:
        print(f'\n   ✅ attendance.user_id → employees.id')
        print(f'      {att_check["count"]} attendance records')
        print(f'      {att_check["unique_employees"]} unique employees')
    else:
        print('   ⚠️  No attendance records linked to employees')
    
    # Check tasks → employees (via assigned_to)
    cursor.execute("""
        SELECT 
            COUNT(*) as count,
            COUNT(DISTINCT t.assigned_to) as unique_employees
        FROM tasks t
        WHERE EXISTS (SELECT 1 FROM employees e WHERE e.id = t.assigned_to)
    """)
    task_check = cursor.fetchone()
    if task_check and task_check['count'] > 0:
        print(f'\n   ✅ tasks.assigned_to → employees.id')
        print(f'      {task_check["count"]} tasks assigned to employees')
        print(f'      {task_check["unique_employees"]} unique employees')
    else:
        print('   ⚠️  No tasks assigned to employees')
    
    # 4. Check actual foreign key constraints
    print('\n\n4️⃣ FOREIGN KEY CONSTRAINTS IN DATABASE')
    print('-' * 100)
    cursor.execute("""
        SELECT
            tc.table_name, 
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND tc.table_schema = 'public'
            AND (tc.table_name = 'employees' 
                 OR ccu.table_name = 'employees')
        ORDER BY tc.table_name, kcu.column_name;
    """)
    fk_constraints = cursor.fetchall()
    
    if fk_constraints:
        print(f'\n   Found {len(fk_constraints)} foreign key constraints:')
        for fk in fk_constraints:
            print(f'\n   ✅ {fk["table_name"]}.{fk["column_name"]}')
            print(f'      → {fk["foreign_table_name"]}.{fk["foreign_column_name"]}')
            print(f'      Constraint: {fk["constraint_name"]}')
    else:
        print('   ⚠️  No foreign key constraints found involving employees table')
    
    # 5. Summary statistics
    print('\n\n5️⃣ DATABASE SUMMARY')
    print('-' * 100)
    
    # Count all tables
    cursor.execute("SELECT COUNT(*) as count FROM companies")
    companies_count = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM branches")
    branches_count = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM attendance")
    attendance_count = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM tasks")
    tasks_count = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM users WHERE role = 'CEO'")
    ceo_count = cursor.fetchone()['count']
    
    print(f'\n   🏢 Companies: {companies_count}')
    print(f'   🏪 Branches: {branches_count}')
    print(f'   👤 CEOs (auth.users): {ceo_count}')
    print(f'   👥 Employees: {len(employees)}')
    print(f'   📋 Attendance Records: {attendance_count}')
    print(f'   📝 Tasks: {tasks_count}')
    
    cursor.close()
    conn.close()
    
    # 6. Final conclusion
    print('\n\n' + '=' * 100)
    print('✅ CONCLUSION')
    print('=' * 100)
    
    if len(employees) > 0:
        print(f'\n✅ Employees table HAS DATA ({len(employees)} employees)')
    else:
        print('\n❌ Employees table is EMPTY')
    
    if emp_companies:
        print('✅ employees.company_id foreign keys are working')
    else:
        print('⚠️  employees.company_id may need data or foreign key setup')
    
    if emp_branches:
        print('✅ employees.branch_id foreign keys are working')
    else:
        print('⚠️  employees.branch_id may need data or foreign key setup')
    
    if att_check and att_check['count'] > 0:
        print('✅ attendance → employees relationship is working')
    else:
        print('ℹ️  No attendance data yet (normal for new database)')
    
    if fk_constraints:
        print(f'✅ {len(fk_constraints)} foreign key constraints are properly defined')
    else:
        print('⚠️  No foreign key constraints found - may need to create them')
    
    print('\n' + '=' * 100)
    
except Exception as e:
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
