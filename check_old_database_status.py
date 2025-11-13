"""
Check if OLD database still has data and is accessible
"""

from supabase import create_client

print('=' * 100)
print('🔍 CHECKING OLD DATABASE STATUS')
print('=' * 100)

# Old database credentials
old_url = 'https://gweiqezmyvydqtlhuksp.supabase.co'
old_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3ZWlxZXpteXZ5ZHF0bGh1a3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY2NzcxNzcsImV4cCI6MjA1MjI1MzE3N30.9N0hEZmRb10p0g6g9Kl3xv8dWzA9uT-nMCvT7jGTM8s'

try:
    old_db = create_client(old_url, old_key)
    
    print('\n✅ OLD DATABASE IS ACCESSIBLE!')
    print(f'   URL: {old_url}')
    
    # Check employees
    emp_result = old_db.table('employees').select('id, full_name, role', count='exact').execute()
    print(f'\n👥 Employees: {emp_result.count}')
    if emp_result.data:
        for emp in emp_result.data[:5]:
            print(f'   - {emp["full_name"]} ({emp["role"]})')
    
    # Check companies
    comp_result = old_db.table('companies').select('id, name', count='exact').execute()
    print(f'\n🏢 Companies: {comp_result.count}')
    if comp_result.data:
        for comp in comp_result.data[:3]:
            print(f'   - {comp["name"]}')
    
    # Check attendance
    att_result = old_db.table('attendance').select('id', count='exact').execute()
    print(f'\n📋 Attendance Records: {att_result.count}')
    
    # Check tasks
    task_result = old_db.table('tasks').select('id', count='exact').execute()
    print(f'\n📝 Tasks: {task_result.count}')
    
    print('\n' + '=' * 100)
    print('✅ OLD DATABASE IS STILL WORKING!')
    print('=' * 100)
    print('\n💡 RECOMMENDATION:')
    print('   RESTORE old database credentials to .env file')
    print('   All your migration work is still there!')
    
except Exception as e:
    print(f'\n❌ OLD DATABASE ERROR: {e}')
    print('\n⚠️  Old database may be deleted or inaccessible')
    print('   You will need to setup the NEW database from scratch')

print('\n' + '=' * 100)
