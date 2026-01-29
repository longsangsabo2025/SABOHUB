"""
Check CEO company assignment
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("\n" + "="*80)
print("CHECKING CEO COMPANY ASSIGNMENT")
print("="*80)

# Check CEO user
result = supabase.table('users').select('id, full_name, email, role, company_id, branch_id').eq('email', 'longsangsabo1@gmail.com').execute()

if result.data:
    user = result.data[0]
    print(f"\n✅ Found CEO user:")
    print(f"  Name: {user.get('full_name')}")
    print(f"  Email: {user.get('email')}")
    print(f"  Role: {user.get('role')}")
    print(f"  Company ID: {user.get('company_id')}")
    print(f"  Branch ID: {user.get('branch_id')}")
    print(f"  User ID: {user.get('id')}")
    
    # Get company details if exists
    if user.get('company_id'):
        company = supabase.table('companies').select('*').eq('id', user.get('company_id')).execute()
        if company.data:
            print(f"\n✅ Company Details:")
            print(f"  Company Name: {company.data[0].get('name')}")
            print(f"  Company ID: {company.data[0].get('id')}")
            print(f"  Created: {company.data[0].get('created_at')}")
    else:
        print(f"\n❌ CEO has NO company assigned!")
else:
    print(f"\n❌ CEO user not found!")

print("\n" + "="*80 + "\n")
