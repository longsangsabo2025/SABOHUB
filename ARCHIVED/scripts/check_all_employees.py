from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase = create_client(url, key)

print("=" * 60)
print("CHECK ALL EMPLOYEES")
print("=" * 60)

# Check all employees regardless of company
all_employees = supabase.table('employees').select('*').execute()
print(f"\nTotal employees in database: {len(all_employees.data)}")

# Group by company
from collections import defaultdict
by_company = defaultdict(list)
for emp in all_employees.data:
    company_id = emp.get('company_id', 'NULL')
    by_company[company_id].append(emp)

print("\nEmployees grouped by company:")
for company_id, employees in by_company.items():
    print(f"\nCompany ID: {company_id}")
    
    # Get company name
    if company_id != 'NULL':
        company = supabase.table('companies').select('name').eq('id', company_id).execute()
        if company.data:
            print(f"Company Name: {company.data[0]['name']}")
    
    print(f"Total employees: {len(employees)}")
    for emp in employees:
        print(f"  - {emp.get('full_name', 'NULL')} ({emp.get('username', 'NULL')})")
        print(f"    Role: {emp.get('role', 'NULL')}, Active: {emp.get('is_active', 'NULL')}")

print("\n" + "=" * 60)
print("DONE")
print("=" * 60)
