"""
Create test Shift Leader users and sample attendance records
"""
import os
from supabase import create_client
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("\n🔧 Creating test data...")
print("="*80)

# Get company and branch
companies = supabase.table('companies').select('*').execute()
branches = supabase.table('branches').select('*').execute()

if not companies.data or not branches.data:
    print("❌ Need at least 1 company and 1 branch!")
    exit(1)

company_id = companies.data[0]['id']
branch_id = branches.data[0]['id']
company_name = companies.data[0].get('name')
branch_name = branches.data[0].get('name')

print(f"Company: {company_name} ({company_id})")
print(f"Branch: {branch_name} ({branch_id})")

# Create Shift Leader
print("\n🔧 Creating Shift Leader user...")

shift_leader_data = {
    'full_name': 'Nguyễn Văn A',
    'email': 'shiftleader@test.com',
    'role': 'SHIFT_LEADER',
    'company_id': company_id,
    'branch_id': branch_id,
    'phone': '0901234567',
    'is_active': True
}

try:
    # Check if exists
    existing_sl = supabase.table('users').select('*').eq('email', 'shiftleader@test.com').execute()
    
    if existing_sl.data:
        print(f"✅ Shift Leader already exists: {existing_sl.data[0].get('full_name')}")
        shift_leader = existing_sl.data[0]
    else:
        sl_result = supabase.table('users').insert(shift_leader_data).execute()
        shift_leader = sl_result.data[0]
        print(f"✅ Created Shift Leader: {shift_leader.get('full_name')}")
except Exception as e:
    print(f"❌ Error creating Shift Leader: {e}")
    shift_leader = None

# Create attendance records
print("\n🔧 Creating sample attendance records...")

# Get all active users
users = supabase.table('users').select('*').is_('deleted_at', 'null').execute()

# Use branch as store_id for attendance (since stores table doesn't exist)
store_id = branch_id
print(f"Using branch as store: {branch_name} ({store_id})")

created_attendance = 0

for user in users.data[:3]:  # Create for first 3 users
    user_id = user['id']
    user_name = user.get('full_name') or user.get('name')
    user_role = user.get('role')
    
    # Check if attendance already exists for today
    existing = supabase.table('attendance').select('*').eq('user_id', user_id).eq('store_id', store_id).execute()
    
    if existing.data:
        print(f"  ℹ️  Attendance already exists for {user_name}")
        continue
    
    attendance_data = {
        'user_id': user_id,
        'store_id': store_id,
        'employee_name': user_name,
        'employee_role': user_role,
        'check_in': datetime.now().isoformat(),
        'check_in_location': 'Test Location'
    }
    
    try:
        supabase.table('attendance').insert(attendance_data).execute()
        print(f"✅ Created attendance for {user_name} ({user_role})")
        created_attendance += 1
    except Exception as e:
        print(f"❌ Error creating attendance for {user_name}: {e}")

print("\n" + "="*80)
print("SUMMARY")
print("="*80)
print(f"Shift Leaders: {'✅ Created/Exists' if shift_leader else '❌ Failed'}")
print(f"Attendance records created: {created_attendance}")
print("\n✅ Test data creation complete!\n")
