#!/usr/bin/env python3
"""Create manager permissions for the CORRECT company that CEO is viewing"""

import os
from supabase import create_client

# Supabase connection
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
# Using service_role key to bypass RLS
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyOTY2MTk0NiwiZXhwIjoyMDQ1MjM3OTQ2fQ.s0vTF5zshuffzUWLZmxb_dLJNF1ha-5wlFnGIzP6GcI"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# The company ID that CEO is currently viewing
COMPANY_ID = "feef10d3-899d-4554-8107-b2256918213a"

print("🔍 Finding managers for company:", COMPANY_ID)
print("=" * 60)

# Get company info
company = supabase.table('companies').select('*').eq('id', COMPANY_ID).single().execute()
print(f"\n📍 Company: {company.data['name']}")
print(f"   Owner ID: {company.data.get('owner_id', 'N/A')}")

# Get all managers in this company
managers = supabase.table('employees').select('*').eq('company_id', COMPANY_ID).eq('role', 'manager').execute()

print(f"\n👥 Found {len(managers.data)} managers:")
for m in managers.data:
    print(f"   - {m['name']} (ID: {m['id']})")

if not managers.data:
    print("\n⚠️ No managers found! Cannot create permissions.")
    exit(1)

print("\n" + "=" * 60)
print("🛠️ Creating default permissions for each manager...")
print("=" * 60)

for manager in managers.data:
    print(f"\n📝 Processing: {manager['name']}")
    
    # Check if permission already exists
    existing = supabase.table('manager_permissions').select('*').eq('manager_id', manager['id']).eq('company_id', COMPANY_ID).execute()
    
    if existing.data:
        print(f"   ⏭️ Permission already exists (ID: {existing.data[0]['id']})")
        continue
    
    # Create default permission
    new_perm = {
        'manager_id': manager['id'],
        'company_id': COMPANY_ID,
        'can_view_overview': True,
        'can_view_employees': True,
        'can_view_tasks': True,
        'can_view_documents': False,
        'can_view_ai_assistant': False,
        'can_view_attendance': True,
        'can_view_accounting': False,
        'can_view_employee_docs': False,
        'can_view_business_law': False,
        'can_view_settings': False,
        'can_create_task': True,
        'can_edit_task': True,
        'can_delete_task': False,
        'can_assign_task': True,
        'can_approve_attendance': True,
        'can_manage_employees': False,
        'can_view_reports': False,
        'granted_by': company.data.get('owner_id'),
        'notes': 'Auto-created default permissions'
    }
    
    result = supabase.table('manager_permissions').insert(new_perm).execute()
    print(f"   ✅ Created permission (ID: {result.data[0]['id']})")
    print(f"      Default tabs: Overview, Employees, Tasks, Attendance")

print("\n" + "=" * 60)
print("✅ DONE! Verifying...")
print("=" * 60)

# Verify
all_perms = supabase.table('manager_permissions').select('*').eq('company_id', COMPANY_ID).execute()
print(f"\n📊 Total permissions for company: {len(all_perms.data)}")
for perm in all_perms.data:
    # Get manager name
    mgr = supabase.table('employees').select('name').eq('id', perm['manager_id']).single().execute()
    enabled = []
    if perm['can_view_overview']: enabled.append('Overview')
    if perm['can_view_employees']: enabled.append('Employees')
    if perm['can_view_tasks']: enabled.append('Tasks')
    if perm['can_view_attendance']: enabled.append('Attendance')
    
    print(f"\n   Manager: {mgr.data['name']}")
    print(f"   Permission ID: {perm['id']}")
    print(f"   Enabled: {', '.join(enabled)}")

print("\n" + "=" * 60)
print("🎉 Now hot restart Flutter and check the Phân quyền tab!")
print("=" * 60)
