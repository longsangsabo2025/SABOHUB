from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase = create_client(url, key)

print("=" * 60)
print("UPDATE CEO TO SABO BILLIARDS COMPANY")
print("=" * 60)

# SABO Billiards company ID (where employees are)
sabo_billiards_company_id = 'feef10d3-899d-4554-8107-b2256918213a'
ceo_email = 'longsangsabo1@gmail.com'

print(f"\nUpdating CEO {ceo_email} to SABO Billiards company...")
print(f"Target company ID: {sabo_billiards_company_id}")

# Update CEO's company_id
result = supabase.table('users').update({
    'company_id': sabo_billiards_company_id
}).eq('email', ceo_email).execute()

if result.data:
    print("\nSUCCESS! CEO company_id updated.")
    print(f"   CEO ID: {result.data[0]['id']}")
    print(f"   Company ID: {result.data[0]['company_id']}")
else:
    print("\nERROR: Failed to update CEO!")

# Verify employees are visible now
print("\nVerifying employees...")
employees = supabase.table('employees').select('full_name, username, role').eq('company_id', sabo_billiards_company_id).eq('is_active', True).execute()
print(f"Active employees: {len(employees.data)}")
for emp in employees.data:
    print(f"  - {emp['full_name']} ({emp['username']}) - {emp['role']}")

print("\n" + "=" * 60)
print("DONE - Now CEO should see employees in the app!")
print("=" * 60)
