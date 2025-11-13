"""
Fix duplicate CEO users - keep only longsangsabo1@gmail.com
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("\n🔍 Finding duplicate CEOs...")

# Get all CEOs
ceos = supabase.table('users').select('*').eq('role', 'CEO').is_('deleted_at', 'null').execute()

print(f"Found {len(ceos.data)} CEOs:")
for ceo in ceos.data:
    print(f"  - {ceo.get('full_name')} ({ceo.get('email')}) - ID: {ceo['id']}")

# Keep only longsangsabo1@gmail.com
primary_ceo_email = 'longsangsabo1@gmail.com'
primary_ceo = None
duplicates = []

for ceo in ceos.data:
    if ceo.get('email') == primary_ceo_email:
        primary_ceo = ceo
    else:
        duplicates.append(ceo)

if not primary_ceo:
    print(f"\n❌ Primary CEO ({primary_ceo_email}) not found!")
    exit(1)

print(f"\n✅ Primary CEO: {primary_ceo.get('full_name')} ({primary_ceo.get('email')})")
print(f"   ID: {primary_ceo['id']}")

if duplicates:
    print(f"\n🗑️  Deleting {len(duplicates)} duplicate CEOs...")
    
    for dup in duplicates:
        print(f"  Deleting: {dup.get('full_name')} (ID: {dup['id']})")
        try:
            # Soft delete by setting deleted_at
            supabase.table('users').update({
                'deleted_at': 'now()'
            }).eq('id', dup['id']).execute()
            print(f"    ✅ Deleted")
        except Exception as e:
            print(f"    ❌ Error: {e}")
    
    print("\n✅ Duplicate CEOs removed!")
else:
    print("\n✅ No duplicates found!")

# Ensure primary CEO has company_id
print(f"\n🔧 Ensuring primary CEO has company assignment...")
companies = supabase.table('companies').select('*').execute()

if companies.data:
    company = companies.data[0]
    company_id = company['id']
    company_name = company.get('name')
    
    if not primary_ceo.get('company_id'):
        print(f"  Assigning to company: {company_name}")
        supabase.table('users').update({
            'company_id': company_id
        }).eq('id', primary_ceo['id']).execute()
        print("  ✅ Company assigned!")
    else:
        print(f"  ✅ Already assigned to company: {company_name}")
else:
    print("  ⚠️  No companies found!")

print("\n✅ CEO cleanup complete!\n")
