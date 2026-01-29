"""
Quick setup - Create manager_permissions table directly
"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("=" * 60)
print("🚀 CREATING MANAGER_PERMISSIONS TABLE")
print("=" * 60)

# Check if table exists
print("\n🔍 Checking if table already exists...")
try:
    existing = supabase.table('manager_permissions').select('id').limit(1).execute()
    print("✅ Table already exists!")
    print(f"   Found {len(existing.data)} records")
except Exception as e:
    print(f"❌ Table does not exist yet: {e}")
    print("\n📝 Please run this SQL in Supabase SQL Editor:")
    print("=" * 60)
    
    with open('database/create_manager_permissions.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    print(sql)
    print("=" * 60)
    print("\n⚠️  Copy the SQL above and run it in Supabase Dashboard")
    print("    Then run this script again")
    exit(1)

# Create default permissions for existing managers
print("\n🔍 Finding existing managers...")
managers = supabase.table('employees').select('id, full_name, company_id').eq('role', 'MANAGER').is_('deleted_at', 'null').execute()

if not managers.data:
    print("ℹ️  No managers found")
else:
    print(f"📋 Found {len(managers.data)} managers")
    
    for manager in managers.data:
        manager_id = manager['id']
        company_id = manager['company_id']
        name = manager['full_name']
        
        if not company_id:
            print(f"   ⚠️  {name} has no company_id, skipping...")
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
                'notes': 'Default permissions created by setup script'
            }).execute()
            print(f"   ✅ {name} - default permissions created")
        except Exception as e:
            print(f"   ❌ {name} - error: {e}")

# Test query
print("\n🧪 Testing permissions query...")
try:
    result = supabase.table('manager_permissions').select('*').execute()
    if result.data:
        print(f"✅ Query successful! Found {len(result.data)} permission records")
    else:
        print("ℹ️  No permission records found yet")
except Exception as e:
    print(f"❌ Query failed: {e}")

print("\n" + "=" * 60)
print("✅ SETUP COMPLETE")
print("=" * 60)
