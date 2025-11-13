"""
Test getCompanyEmployees query directly
"""
import psycopg2
from psycopg2.extras import RealDictCursor

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('=' * 80)
print('🔍 TEST EMPLOYEES QUERY')
print('=' * 80)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # 1. Check all employees
    print('\n1️⃣ ALL EMPLOYEES IN DATABASE')
    cursor.execute("""
        SELECT id, full_name, email, role, company_id, branch_id, is_active
        FROM employees
        ORDER BY role, full_name
    """)
    all_employees = cursor.fetchall()
    print(f'   Total: {len(all_employees)} employees\n')
    for emp in all_employees:
        print(f'   📝 {emp["full_name"]} ({emp["role"]})')
        print(f'      Email: {emp["email"]}')
        print(f'      Company ID: {emp["company_id"]}')
        print(f'      Branch ID: {emp["branch_id"]}')
        print(f'      Active: {emp["is_active"]}\n')
    
    # 2. Check companies
    print('\n2️⃣ ALL COMPANIES')
    cursor.execute("SELECT id, name FROM companies")
    companies = cursor.fetchall()
    print(f'   Total: {len(companies)} companies\n')
    for comp in companies:
        print(f'   🏢 {comp["name"]}')
        print(f'      ID: {comp["id"]}\n')
    
    # 3. Test the exact query from employee_service.dart
    if companies:
        company_id = companies[0]['id']
        print(f'\n3️⃣ TEST QUERY (company_id = {company_id})')
        print('   Query: SELECT * FROM employees WHERE company_id = ? AND is_active = true')
        
        cursor.execute("""
            SELECT id, full_name, email, role, phone, avatar_url, 
                   branch_id, company_id, is_active, created_at, updated_at
            FROM employees
            WHERE company_id = %s AND is_active = true
            ORDER BY created_at DESC
        """, (company_id,))
        
        filtered_employees = cursor.fetchall()
        print(f'\n   ✅ Result: {len(filtered_employees)} employees')
        
        if filtered_employees:
            for emp in filtered_employees:
                print(f'\n   👤 {emp["full_name"]} ({emp["role"]})')
                print(f'      Email: {emp["email"]}')
        else:
            print('\n   ⚠️  NO EMPLOYEES FOUND FOR THIS COMPANY!')
            print('\n   Possible issues:')
            print('   1. company_id in employees table does not match')
            print('   2. is_active = false')
            print('   3. RLS policy blocking query')
    
    # 4. Check RLS policies
    print('\n\n4️⃣ RLS POLICIES ON EMPLOYEES TABLE')
    cursor.execute("""
        SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
        FROM pg_policies
        WHERE tablename = 'employees'
    """)
    policies = cursor.fetchall()
    
    if policies:
        print(f'   Found {len(policies)} RLS policies:\n')
        for policy in policies:
            print(f'   📋 {policy["policyname"]}')
            print(f'      Command: {policy["cmd"]}')
            print(f'      Roles: {policy["roles"]}')
            print(f'      Condition: {policy["qual"]}\n')
    else:
        print('   ⚠️  NO RLS POLICIES FOUND!')
        print('   This means anyone can query, but data might not match\n')
    
    cursor.close()
    conn.close()
    
    print('=' * 80)
    print('✅ DIAGNOSIS:')
    print('=' * 80)
    
    if len(all_employees) == 0:
        print('\n❌ NO EMPLOYEES in database')
        print('   Need to create employees first')
    elif len(companies) == 0:
        print('\n❌ NO COMPANIES in database')
        print('   Need to create company first')
    elif len(filtered_employees) == 0:
        print('\n⚠️  EMPLOYEES EXIST but query returns EMPTY')
        print('\n   Possible fixes:')
        print('   1. Check if employees.company_id matches companies.id')
        print('   2. Check if employees.is_active = true')
        print('   3. Check RLS policies allow CEO to query employees')
        print('\n   Run this SQL to fix company_id:')
        if companies and all_employees:
            print(f"\n   UPDATE employees SET company_id = '{company_id}' WHERE company_id IS NULL;")
    else:
        print('\n✅ QUERY WORKS! CEO should see employees')
        print(f'   Found {len(filtered_employees)} employees for company')
    
    print('=' * 80)
    
except Exception as e:
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
