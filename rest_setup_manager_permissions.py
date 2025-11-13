"""
Create manager_permissions table using Supabase REST API
This bypasses the need for direct PostgreSQL connection
"""
import os
import requests
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def run_sql_via_rest(sql):
    """Execute SQL using Supabase REST API"""
    # Supabase REST API doesn't support arbitrary SQL execution for security
    # We need to use the PostgREST API instead
    print("⚠️  Cannot execute arbitrary SQL via Supabase REST API")
    return False

def check_table_exists():
    """Check if manager_permissions table exists"""
    url = f"{SUPABASE_URL}/rest/v1/manager_permissions"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    
    try:
        response = requests.get(url, headers=headers, params={'limit': 1})
        return response.status_code == 200
    except:
        return False

def create_permission_record(manager_id, company_id, manager_name):
    """Create a permission record via REST API"""
    url = f"{SUPABASE_URL}/rest/v1/manager_permissions"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    data = {
        'manager_id': manager_id,
        'company_id': company_id,
        'can_view_overview': True,
        'can_view_employees': True,
        'can_view_tasks': True,
        'can_view_attendance': True,
        'can_create_task': True,
        'can_edit_task': True,
        'can_approve_attendance': True,
        'notes': 'Default permissions created by REST API script'
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        if response.status_code in [200, 201]:
            print(f"   ✅ {manager_name} - permissions created")
            return True
        else:
            print(f"   ❌ {manager_name} - error: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ {manager_name} - error: {e}")
        return False

def get_managers():
    """Get all managers from database"""
    url = f"{SUPABASE_URL}/rest/v1/employees"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    params = {
        'role': 'eq.MANAGER',
        'deleted_at': 'is.null',
        'select': 'id,full_name,company_id'
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"❌ Failed to get managers: {response.text}")
            return []
    except Exception as e:
        print(f"❌ Error getting managers: {e}")
        return []

def get_existing_permissions(manager_id, company_id):
    """Check if permissions already exist"""
    url = f"{SUPABASE_URL}/rest/v1/manager_permissions"
    headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}'
    }
    params = {
        'manager_id': f'eq.{manager_id}',
        'company_id': f'eq.{company_id}'
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return len(response.json()) > 0
        return False
    except:
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 MANAGER PERMISSIONS SETUP VIA REST API")
    print("=" * 60)
    
    # Check if table exists
    print("\n🔍 Checking if manager_permissions table exists...")
    if not check_table_exists():
        print("❌ Table does not exist!")
        print("\n📝 Please create the table manually:")
        print("1. Open Supabase Dashboard → SQL Editor")
        print("2. Copy and run: database/create_manager_permissions.sql")
        print("\n📄 SQL file content:")
        print("=" * 60)
        with open('database/create_manager_permissions.sql', 'r', encoding='utf-8') as f:
            print(f.read())
        print("=" * 60)
        exit(1)
    
    print("✅ Table exists!")
    
    # Get all managers
    print("\n🔍 Finding existing managers...")
    managers = get_managers()
    
    if not managers:
        print("ℹ️  No managers found")
        exit(0)
    
    print(f"📋 Found {len(managers)} managers")
    
    # Create permissions for each manager
    created_count = 0
    skipped_count = 0
    
    for manager in managers:
        manager_id = manager['id']
        company_id = manager.get('company_id')
        name = manager['full_name']
        
        if not company_id:
            print(f"   ⚠️  {name} has no company_id, skipping...")
            skipped_count += 1
            continue
        
        # Check if permissions already exist
        if get_existing_permissions(manager_id, company_id):
            print(f"   ✓ {name} - permissions already exist")
            skipped_count += 1
            continue
        
        # Create permissions
        if create_permission_record(manager_id, company_id, name):
            created_count += 1
    
    print("\n" + "=" * 60)
    print("✅ SETUP COMPLETE!")
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"   ✅ Created: {created_count}")
    print(f"   ⏭️  Skipped: {skipped_count}")
    print(f"   📋 Total managers: {len(managers)}")
    
    print("\n📝 Next steps:")
    print("1. ✅ Permissions created in database")
    print("2. 🔜 Create ManagerCompanyInfoPage in Flutter")
    print("3. 🔜 Add Company Info tab to Manager navigation")
    print("4. 🔜 Create CEO UI to manage permissions")
