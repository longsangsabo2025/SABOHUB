import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔍 Checking companies table...")
print("=" * 60)

# Get all companies
companies = supabase.table('companies').select('*').execute()
print(f"\n📊 Total companies: {len(companies.data)}")
print("\nCompanies data:")
for company in companies.data:
    print(f"  - ID: {company.get('id')}")
    print(f"    Name: {company.get('name')}")
    print(f"    Owner ID: {company.get('owner_id')}")
    print(f"    CEO User ID: {company.get('ceo_user_id', 'N/A')}")
    print(f"    CEO ID: {company.get('ceo_id', 'N/A')}")
    print()

# Get all users
print("\n👥 Checking users...")
users = supabase.table('users').select('*').execute()
print(f"Total users: {len(users.data)}")
for user in users.data:
    print(f"  - ID: {user.get('id')}")
    print(f"    Email: {user.get('email')}")
    print(f"    Role: {user.get('role')}")
    print()

# Check auth users
print("\n🔐 Checking auth.users (first 5)...")
try:
    auth_users = supabase.auth.admin.list_users()
    print(f"Total auth users: {len(auth_users)}")
    for i, user in enumerate(auth_users[:5]):
        print(f"  - ID: {user.id}")
        print(f"    Email: {user.email}")
        print()
except Exception as e:
    print(f"Cannot list auth users: {e}")
