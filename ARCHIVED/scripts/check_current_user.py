import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

# Connect to Supabase
url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase = create_client(url, key)

# Get Manager Diễm employee record
print("=" * 60)
print("CHECKING MANAGER DIỄM AUTH INFO")
print("=" * 60)

employee_id = '61715a20-dc93-480c-9dab-f21806114887'

# Get employee info
result = supabase.table('employees').select('*').eq('id', employee_id).execute()

if result.data:
    emp = result.data[0]
    print(f"\n✅ Employee found:")
    print(f"   ID: {emp['id']}")
    print(f"   Name: {emp['full_name']}")
    print(f"   Email: {emp.get('email', 'N/A')}")
    print(f"   User ID (auth): {emp.get('user_id', 'N/A')}")
    print(f"   Role: {emp['role']}")
    print(f"   Company: {emp['company_id']}")
    
    # Check if user_id exists in auth.users
    user_id = emp.get('user_id')
    if user_id:
        print(f"\n📧 Login credentials:")
        print(f"   Email: {emp.get('email', 'N/A')}")
        print(f"   User Auth ID: {user_id}")
        print(f"\n🔑 Use this email to login as Manager Diễm")
    else:
        print(f"\n⚠️  WARNING: No user_id found! Manager Diễm cannot login.")
        print(f"   Need to create auth user for this employee.")
else:
    print(f"\n❌ Employee not found with ID: {employee_id}")

print("\n" + "=" * 60)
