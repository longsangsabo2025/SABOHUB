"""Quick check employees in NEW database"""
from supabase import create_client

db = create_client(
    'https://dqddxowyikefqcdiioyh.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y'
)

print('=' * 80)
print('✅ NEW DATABASE: dqddxowyikefqcdiioyh')
print('=' * 80)

# Check employees
result = db.table('employees').select('*').execute()
print(f'\n👥 Employees: {len(result.data)}')
for emp in result.data:
    print(f'  - {emp.get("full_name")} ({emp.get("role")})')
    print(f'    Company: {emp.get("company_id")}')
    print(f'    Branch: {emp.get("branch_id")}')

# Check attendance
att = db.table('attendance').select('id', count='exact').execute()
print(f'\n📋 Attendance: {att.count}')

# Check tasks
tasks = db.table('tasks').select('id', count='exact').execute()
print(f'📝 Tasks: {tasks.count}')

# Check companies
comp = db.table('companies').select('id, name').execute()
print(f'\n🏢 Companies: {len(comp.data)}')
for c in comp.data:
    print(f'  - {c.get("name")}')

print('\n' + '=' * 80)
