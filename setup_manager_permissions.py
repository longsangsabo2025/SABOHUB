"""
Create manager_permissions table in database
Allows CEO to grant granular permissions to each Manager
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

def create_manager_permissions_table():
    """Create manager_permissions table using SQL file"""
    print("🔧 Creating manager_permissions table...")
    
    # Read SQL file
    with open('database/create_manager_permissions.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    try:
        # Execute SQL
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print("✅ Table created successfully!")
        return True
    except Exception as e:
        # If RPC doesn't exist, try direct execution
        print(f"⚠️ RPC method failed, trying direct execution...")
        print(f"Error: {e}")
        print("\n📝 Please run the SQL file manually in Supabase SQL Editor:")
        print("   database/create_manager_permissions.sql")
        return False

def create_default_permissions_for_existing_managers():
    """Create default permissions for existing managers"""
    print("\n🔍 Finding existing managers...")
    
    # Get all managers
    managers = supabase.table('employees').select('id, full_name, company_id').eq('role', 'MANAGER').is_('deleted_at', 'null').execute()
    
    if not managers.data:
        print("ℹ️ No managers found")
        return
    
    print(f"📋 Found {len(managers.data)} managers")
    
    for manager in managers.data:
        manager_id = manager['id']
        company_id = manager['company_id']
        name = manager['full_name']
        
        if not company_id:
            print(f"⚠️ Manager {name} has no company_id, skipping...")
            continue
        
        # Check if permissions already exist
        existing = supabase.table('manager_permissions').select('id').eq('manager_id', manager_id).eq('company_id', company_id).execute()
        
        if existing.data:
            print(f"   ✓ {name} - permissions already exist")
            continue
        
        # Create default permissions
        try:
            supabase.table('manager_permissions').insert({
                'manager_id': manager_id,
                'company_id': company_id,
                'can_view_overview': True,
                'can_view_employees': True,
                'can_view_tasks': True,
                'can_view_attendance': True,
                'can_create_task': True,
                'can_edit_task': True,
                'can_approve_attendance': True,
                'notes': 'Default permissions created by migration script'
            }).execute()
            print(f"   ✅ {name} - default permissions created")
        except Exception as e:
            print(f"   ❌ {name} - error: {e}")

def test_permissions_query():
    """Test querying permissions"""
    print("\n🧪 Testing permissions query...")
    
    try:
        # Get all permissions with manager names
        result = supabase.table('manager_permissions').select('''
            *,
            employees:manager_id (
                id,
                full_name,
                username
            ),
            companies:company_id (
                id,
                name
            )
        ''').execute()
        
        if result.data:
            print(f"✅ Query successful! Found {len(result.data)} permission records")
            for perm in result.data:
                manager_name = perm['employees']['full_name'] if perm.get('employees') else 'Unknown'
                company_name = perm['companies']['name'] if perm.get('companies') else 'Unknown'
                print(f"   📋 {manager_name} @ {company_name}")
                print(f"      Tabs: Overview={perm['can_view_overview']}, Employees={perm['can_view_employees']}, Tasks={perm['can_view_tasks']}")
        else:
            print("ℹ️ No permission records found yet")
            
    except Exception as e:
        print(f"❌ Query failed: {e}")

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 MANAGER PERMISSIONS SYSTEM SETUP")
    print("=" * 60)
    
    # Step 1: Create table
    table_created = create_manager_permissions_table()
    
    if not table_created:
        print("\n⚠️ Please create the table manually first, then run this script again")
        exit(1)
    
    # Step 2: Create default permissions for existing managers
    create_default_permissions_for_existing_managers()
    
    # Step 3: Test query
    test_permissions_query()
    
    print("\n" + "=" * 60)
    print("✅ SETUP COMPLETE")
    print("=" * 60)
    print("\n📝 Next steps:")
    print("1. Create ManagerCompanyInfoPage in Flutter")
    print("2. Create ManagerPermissionsService to query permissions")
    print("3. Create CEO UI to manage manager permissions")
    print("4. Update Manager layout to show Company Info tab")
