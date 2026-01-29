#!/usr/bin/env python3
"""Check which company has manager_permissions data"""

import os
from supabase import create_client

# Supabase connection
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjk2NjE5NDYsImV4cCI6MjA0NTIzNzk0Nn0.MbZY1vfCC5wkvI6TQKRRIdygvOEPx_Jb4mZp_AecKOU"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print("🔍 Checking manager_permissions table...")
print("=" * 60)

# Get all permissions
result = supabase.table('manager_permissions').select('*').execute()
permissions = result.data

print(f"\n📊 Found {len(permissions)} permission records")

if permissions:
    print("\n📝 Permission details:")
    for i, perm in enumerate(permissions, 1):
        print(f"\n{i}. Permission ID: {perm['id']}")
        print(f"   Manager ID: {perm['manager_id']}")
        print(f"   Company ID: {perm['company_id']}")
        print(f"   Granted At: {perm['granted_at']}")
        
        # Get company name
        company = supabase.table('companies').select('name').eq('id', perm['company_id']).single().execute()
        print(f"   Company Name: {company.data['name'] if company.data else 'Unknown'}")
        
        # Get manager name
        manager = supabase.table('employees').select('name').eq('id', perm['manager_id']).single().execute()
        print(f"   Manager Name: {manager.data['name'] if manager.data else 'Unknown'}")
        
        # Show permissions
        enabled = []
        if perm['can_view_overview']: enabled.append('Overview')
        if perm['can_view_employees']: enabled.append('Employees')
        if perm['can_view_tasks']: enabled.append('Tasks')
        if perm['can_view_attendance']: enabled.append('Attendance')
        print(f"   Enabled: {', '.join(enabled)}")

print("\n" + "=" * 60)
print("\n🔍 Checking CEO's companies...")

# Get CEO user
ceo = supabase.table('users').select('id, full_name, email, company_id').eq('role', 'ceo').execute()
if ceo.data:
    print(f"\n👤 Found {len(ceo.data)} CEO(s):")
    for c in ceo.data:
        print(f"\n   Name: {c['full_name']}")
        print(f"   Email: {c['email']}")
        print(f"   Default Company ID: {c.get('company_id', 'None')}")
        
        # Get all companies owned by this CEO
        companies = supabase.table('companies').select('id, name').eq('owner_id', c['id']).execute()
        print(f"   Owns {len(companies.data)} companies:")
        for comp in companies.data:
            print(f"      - {comp['name']} ({comp['id']})")
            
            # Check if this company has managers
            managers = supabase.table('employees').select('id, name').eq('company_id', comp['id']).eq('role', 'manager').execute()
            print(f"        Managers: {len(managers.data)}")
            if managers.data:
                for m in managers.data:
                    print(f"          • {m['name']} ({m['id']})")
