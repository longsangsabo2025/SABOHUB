from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase = create_client(url, key)

print("=" * 60)
print("CHECK CEO AND EMPLOYEES")
print("=" * 60)

# 1. Check CEO
print("\n1. CEO Info (longsangsabo1@gmail.com):")
ceo = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()
if ceo.data:
    ceo_data = ceo.data[0]
    print(f"   ID: {ceo_data['id']}")
    print(f"   Email: {ceo_data.get('email', 'NULL')}")
    print(f"   Company ID: {ceo_data.get('company_id', 'NULL')}")
    print(f"   Role: {ceo_data.get('role', 'NULL')}")
    company_id = ceo_data.get('company_id')
else:
    print("   ERROR: CEO not found!")
    exit(1)

# 2. Check company info
if company_id:
    print(f"\n2. Company Info:")
    company = supabase.table('companies').select('*').eq('id', company_id).execute()
    if company.data:
        company_data = company.data[0]
        print(f"   ID: {company_data['id']}")
        print(f"   Name: {company_data.get('name', 'NULL')}")
    else:
        print("   ERROR: Company not found!")
else:
    print("\n2. Company Info: CEO has no company_id!")

# 3. Check all employees
if company_id:
    print(f"\n3. All Employees in company:")
    all_employees = supabase.table('employees').select('*').eq('company_id', company_id).execute()
    print(f"   Total: {len(all_employees.data)} employees")
    for emp in all_employees.data:
        print(f"   - ID: {emp['id']}")
        print(f"     Name: {emp.get('full_name', 'NULL')}")
        print(f"     Username: {emp.get('username', 'NULL')}")
        print(f"     Role: {emp.get('role', 'NULL')}")
        print(f"     Active: {emp.get('is_active', 'NULL')}")
        print(f"     Company ID: {emp.get('company_id', 'NULL')}")
        print()
    
    # 4. Check active employees only
    print(f"\n4. Active Employees Only:")
    active_employees = supabase.table('employees').select('*').eq('company_id', company_id).eq('is_active', True).execute()
    print(f"   Total: {len(active_employees.data)} active employees")
    for emp in active_employees.data:
        print(f"   - {emp.get('full_name', 'NULL')} ({emp.get('username', 'NULL')})")
else:
    print("\n3. Cannot check employees - CEO has no company_id!")
    print("4. Cannot check active employees - CEO has no company_id!")

print("\n" + "=" * 60)
print("DONE")
print("=" * 60)
