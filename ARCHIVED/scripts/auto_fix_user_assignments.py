"""
Auto-fix all user company and branch assignments
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("\n🔧 AUTO-FIX: Assigning company_id and branch_id to users")
print("="*80)

# Get all users
all_users = supabase.table('users').select('*').is_('deleted_at', 'null').execute()

# Get all companies
companies = supabase.table('companies').select('*').execute()
if not companies.data:
    print("❌ No companies found! Please create a company first.")
    exit(1)

# Get all branches
branches = supabase.table('branches').select('*').execute()

print(f"\nFound {len(all_users.data)} users")
print(f"Found {len(companies.data)} companies")
print(f"Found {len(branches.data)} branches")

# Use first company as default
default_company = companies.data[0]
default_company_id = default_company['id']
print(f"\nDefault company: {default_company.get('name')} ({default_company_id})")

# Use first branch as default (if exists)
default_branch_id = None
if branches.data:
    default_branch = branches.data[0]
    default_branch_id = default_branch['id']
    print(f"Default branch: {default_branch.get('name')} ({default_branch_id})")

print("\n" + "="*80)
print("FIXING USERS...")
print("="*80 + "\n")

fixed_count = 0
ceo_fixed = 0
manager_fixed = 0
shift_leader_created = 0
staff_fixed = 0

for user in all_users.data:
    user_id = user['id']
    name = user.get('full_name') or user.get('name') or 'Unknown'
    role = user.get('role')
    company_id = user.get('company_id')
    branch_id = user.get('branch_id')
    
    updates = {}
    
    # Fix CEO and Manager: need company_id
    if role in ['CEO', 'MANAGER'] and not company_id:
        updates['company_id'] = default_company_id
        if role == 'CEO':
            ceo_fixed += 1
        else:
            manager_fixed += 1
        print(f"✅ {role} - {name}: Adding company_id")
    
    # Fix SHIFT_LEADER and STAFF: need both company_id and branch_id
    if role in ['SHIFT_LEADER', 'STAFF']:
        if not company_id:
            updates['company_id'] = default_company_id
        if not branch_id and default_branch_id:
            updates['branch_id'] = default_branch_id
        
        if updates:
            if role == 'SHIFT_LEADER':
                shift_leader_created += 1
            else:
                staff_fixed += 1
            print(f"✅ {role} - {name}: Adding company_id and/or branch_id")
    
    # Apply updates
    if updates:
        try:
            supabase.table('users').update(updates).eq('id', user_id).execute()
            fixed_count += 1
        except Exception as e:
            print(f"❌ Failed to update {name}: {e}")

print("\n" + "="*80)
print("SUMMARY")
print("="*80)
print(f"Total users fixed: {fixed_count}")
print(f"  - CEOs fixed: {ceo_fixed}")
print(f"  - Managers fixed: {manager_fixed}")
print(f"  - Shift Leaders fixed: {shift_leader_created}")
print(f"  - Staff fixed: {staff_fixed}")
print("\n✅ Auto-fix complete!\n")
