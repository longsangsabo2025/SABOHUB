import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("=" * 60)
print("CHECKING MANAGER DIỄM - USER_ID")
print("=" * 60)

# Get Manager Diễm
result = supabase.table('employees').select(
    'id, full_name, email, user_id, role'
).eq('id', '61715a20-dc93-480c-9dab-f21806114887').execute()

if result.data:
    emp = result.data[0]
    print(f"\n✅ Employee found:")
    print(f"   ID: {emp['id']}")
    print(f"   Name: {emp['full_name']}")
    print(f"   Email: {emp.get('email', 'NULL')}")
    print(f"   USER_ID: {emp.get('user_id', 'NULL')}")
    print(f"   Role: {emp['role']}")
    
    if not emp.get('user_id'):
        print(f"\n❌ CRITICAL: user_id is NULL!")
        print(f"   Manager Diễm CANNOT login because no auth user exists!")
        print(f"\n💡 SOLUTION: Need to create auth.users record and link to this employee")
else:
    print("\n❌ Employee NOT FOUND")

print("\n" + "=" * 60)
