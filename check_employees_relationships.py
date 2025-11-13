"""
Check employees table relationships with other tables
Verify 100% completion of database schema
"""

from supabase import create_client
import json

# Use NEW database credentials from .env
url = 'https://dqddxowyikefqcdiioyh.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y'
supabase = create_client(url, key)

print('=' * 100)
print('🔍 CHECKING EMPLOYEES TABLE RELATIONSHIPS')
print('=' * 100)

# 1. Check if employees table exists
print('\n1️⃣ Checking employees table structure...')
try:
    result = supabase.table('employees').select('*').limit(1).execute()
    if result.data:
        print('   ✅ employees table EXISTS')
        sample = result.data[0]
        print(f'   📋 Sample employee: {sample.get("full_name")} ({sample.get("role")})')
        print(f'   🔑 Fields: {", ".join(sample.keys())}')
    else:
        print('   ⚠️  employees table exists but EMPTY')
except Exception as e:
    print(f'   ❌ ERROR: {e}')

# 2. Check foreign keys FROM employees table
print('\n2️⃣ Checking foreign keys FROM employees...')
fk_fields = ['company_id', 'branch_id', 'store_id']
for field in fk_fields:
    try:
        result = supabase.table('employees').select(field).not_.is_(field, 'null').limit(1).execute()
        if result.data:
            print(f'   ✅ {field}: Has data - {len(result.data)} employees linked')
        else:
            print(f'   ⚠️  {field}: No data found')
    except Exception as e:
        print(f'   ⚠️  {field}: Column may not exist')

# 3. Check tables that SHOULD reference employees
print('\n3️⃣ Checking tables that reference employees...')

tables_to_check = {
    'attendance': {
        'fk_field': 'user_id',
        'description': 'Employee check-in/out records',
        'should_reference': 'employees'
    },
    'tasks': {
        'fk_field': 'assigned_to',
        'description': 'Tasks assigned to employees',
        'should_reference': 'employees OR users (CEO)'
    },
    'employee_documents': {
        'fk_field': 'employee_id',
        'description': 'Documents uploaded by employees',
        'should_reference': 'employees'
    },
}

for table_name, config in tables_to_check.items():
    print(f'\n   📊 Table: {table_name}')
    print(f'      Description: {config["description"]}')
    
    try:
        # Check if table exists
        result = supabase.table(table_name).select('*').limit(1).execute()
        
        if result.data:
            print(f'      ✅ Table EXISTS with data')
            
            # Check if FK field exists
            sample = result.data[0]
            fk_field = config['fk_field']
            
            if fk_field in sample:
                print(f'      ✅ FK field "{fk_field}" EXISTS')
                
                # Try to query with employees join
                try:
                    if table_name == 'attendance':
                        test = supabase.table(table_name).select(f'{fk_field}, employees!attendance_user_id_fkey(full_name)').limit(1).execute()
                        if test.data:
                            print(f'      ✅ JOIN with employees works!')
                        else:
                            print(f'      ⚠️  JOIN works but no data')
                    elif table_name == 'tasks':
                        print(f'      ℹ️  Tasks use cached fields (assigned_to_name)')
                    else:
                        test = supabase.table(table_name).select(f'{fk_field}, employees(full_name)').limit(1).execute()
                        if test.data:
                            print(f'      ✅ JOIN with employees works!')
                except Exception as join_err:
                    print(f'      ⚠️  JOIN failed: {str(join_err)[:80]}')
            else:
                print(f'      ⚠️  FK field "{fk_field}" NOT FOUND')
                print(f'      Available fields: {", ".join(sample.keys())}')
        else:
            print(f'      ⚠️  Table exists but EMPTY')
            
    except Exception as e:
        if 'does not exist' in str(e).lower():
            print(f'      ❌ Table does NOT exist')
        else:
            print(f'      ❌ ERROR: {str(e)[:80]}')

# 4. Check for any remaining references to users table
print('\n4️⃣ Checking for tables still referencing users table...')

potential_employee_tables = ['attendance', 'tasks', 'employee_documents', 'bookings']

for table in potential_employee_tables:
    try:
        # Try to join with users table
        result = supabase.table(table).select('*, users(full_name)').limit(1).execute()
        if result.data and result.data[0].get('users'):
            print(f'   ⚠️  {table}: Still has JOIN to users table')
            print(f'      This may be OK if it references CEOs, not employees')
        else:
            print(f'   ✅ {table}: No active JOIN to users table')
    except Exception as e:
        if 'does not exist' in str(e).lower():
            print(f'   ℹ️  {table}: Table does not exist')
        else:
            continue

# 5. Final summary
print('\n' + '=' * 100)
print('📊 RELATIONSHIP SUMMARY')
print('=' * 100)

# Count employees
try:
    emp_count = supabase.table('employees').select('id', count='exact').execute()
    print(f'\n👥 Total Employees: {emp_count.count}')
except:
    print('\n👥 Total Employees: Unknown')

# Check attendance records linked to employees
try:
    att_count = supabase.table('attendance').select('id', count='exact').execute()
    print(f'📋 Attendance Records: {att_count.count}')
except:
    print(f'📋 Attendance Records: Table not found')

# Check tasks
try:
    task_count = supabase.table('tasks').select('id', count='exact').execute()
    print(f'📝 Tasks: {task_count.count}')
except:
    print(f'📝 Tasks: Table not found')

print('\n' + '=' * 100)
print('✅ CONCLUSION:')
print('=' * 100)
print('''
Expected relationships:
1. employees.company_id → companies.id
2. employees.branch_id → branches.id  
3. employees.store_id → stores.id
4. attendance.user_id → employees.id (FK: attendance_user_id_fkey)
5. tasks.assigned_to → employees.id OR users.id (uses cached fields)
6. employee_documents.employee_id → employees.id
''')
print('=' * 100)
