import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔧 Fixing company owner_id...")
print("=" * 60)

# Get the CEO user
ceo_email = "longsang@sabohub.com"
ceo_user = supabase.table('users').select('*').eq('email', ceo_email).eq('role', 'ceo').execute()

if not ceo_user.data:
    print(f"❌ CEO user with email {ceo_email} not found!")
    exit(1)

ceo_id = ceo_user.data[0]['id']
print(f"✅ Found CEO: {ceo_email}")
print(f"   ID: {ceo_id}")

# Get the company
company = supabase.table('companies').select('*').eq('name', 'SABO Billiards').execute()

if not company.data:
    print("❌ Company 'SABO Billiards' not found!")
    exit(1)

company_id = company.data[0]['id']
print(f"\n✅ Found company: SABO Billiards")
print(f"   ID: {company_id}")
print(f"   Current owner_id: {company.data[0].get('owner_id')}")

# Update the company with owner_id
print(f"\n🔄 Setting owner_id = {ceo_id}...")
result = supabase.table('companies').update({
    'owner_id': ceo_id
}).eq('id', company_id).execute()

print(f"\n✅ DONE! Company owner_id updated successfully!")
print(f"\nVerification:")
verify = supabase.table('companies').select('*').eq('id', company_id).execute()
print(f"   Company: {verify.data[0]['name']}")
print(f"   Owner ID: {verify.data[0]['owner_id']}")
