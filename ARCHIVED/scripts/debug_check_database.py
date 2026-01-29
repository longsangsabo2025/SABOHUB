#!/usr/bin/env python3
"""Debug script to check database structure and find the issue"""

from supabase import create_client

# Use the correct keys from .env
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

TARGET_COMPANY_ID = "feef10d3-899d-4554-8107-b2256918213a"

print("=" * 80)
print("🔍 DATABASE DEBUG REPORT")
print("=" * 80)

# 1. Check company info
print("\n📍 STEP 1: Check Company Info")
print("-" * 80)
try:
    company = supabase.table('companies').select('*').eq('id', TARGET_COMPANY_ID).execute()
    if company.data:
        comp = company.data[0]
        print(f"✅ Company Found:")
        print(f"   ID: {comp['id']}")
        print(f"   Name: {comp.get('name', 'N/A')}")
        print(f"   Owner ID: {comp.get('owner_id', 'N/A')}")
        print(f"   Created At: {comp.get('created_at', 'N/A')}")
    else:
        print(f"❌ Company NOT found with ID: {TARGET_COMPANY_ID}")
except Exception as e:
    print(f"❌ Error querying companies: {e}")

# 2. Check all employees in this company
print("\n👥 STEP 2: Check ALL Employees in Company")
print("-" * 80)
try:
    employees = supabase.table('employees').select('*').eq('company_id', TARGET_COMPANY_ID).execute()
    print(f"Total employees: {len(employees.data)}")
    
    if employees.data:
        for emp in employees.data:
            print(f"\n   Employee:")
            print(f"   - ID: {emp['id']}")
            print(f"   - Name/Full Name: {emp.get('name', emp.get('full_name', 'N/A'))}")
            print(f"   - Role: {emp.get('role', 'N/A')}")
            print(f"   - Company ID: {emp.get('company_id', 'N/A')}")
            print(f"   - Branch ID: {emp.get('branch_id', 'N/A')}")
    else:
        print("   ⚠️ NO employees found in this company!")
except Exception as e:
    print(f"❌ Error querying employees: {e}")

# 3. Check employees table structure
print("\n📋 STEP 3: Check Employees Table Columns")
print("-" * 80)
try:
    # Get a sample record to see structure
    sample = supabase.table('employees').select('*').limit(1).execute()
    if sample.data:
        print("   Available columns:")
        for key in sample.data[0].keys():
            print(f"   - {key}")
    else:
        print("   ⚠️ No sample data available")
except Exception as e:
    print(f"❌ Error checking table structure: {e}")

# 4. Check managers specifically with different role values
print("\n🔍 STEP 4: Search for Managers (trying different role values)")
print("-" * 80)
role_variants = ['manager', 'Manager', 'MANAGER', 'quản lý', 'quan-ly']
for role in role_variants:
    try:
        managers = supabase.table('employees').select('*').eq('company_id', TARGET_COMPANY_ID).eq('role', role).execute()
        if managers.data:
            print(f"✅ Found {len(managers.data)} employees with role='{role}':")
            for m in managers.data:
                print(f"   - {m.get('name', m.get('full_name', 'N/A'))} (ID: {m['id']})")
        else:
            print(f"   ❌ No employees with role='{role}'")
    except Exception as e:
        print(f"   ❌ Error with role='{role}': {e}")

# 5. Check all companies the CEO owns
print("\n🏢 STEP 5: Check ALL Companies (to find which one has managers)")
print("-" * 80)
try:
    all_companies = supabase.table('companies').select('*').limit(10).execute()
    print(f"Total companies (limited to 10): {len(all_companies.data)}")
    
    for comp in all_companies.data:
        print(f"\n   Company: {comp.get('name', 'N/A')} ({comp['id']})")
        
        # Check employees in this company
        emps = supabase.table('employees').select('id, role').eq('company_id', comp['id']).execute()
        print(f"   - Total employees: {len(emps.data)}")
        
        # Count by role
        roles = {}
        for emp in emps.data:
            role = emp.get('role', 'unknown')
            roles[role] = roles.get(role, 0) + 1
        
        if roles:
            print(f"   - Roles breakdown: {roles}")
        
        # Highlight if has managers
        if any('manager' in str(r).lower() for r in roles.keys()):
            print(f"   ✨ THIS COMPANY HAS MANAGERS! ✨")
except Exception as e:
    print(f"❌ Error checking companies: {e}")

# 6. Check manager_permissions table
print("\n🔐 STEP 6: Check manager_permissions Table")
print("-" * 80)
try:
    all_perms = supabase.table('manager_permissions').select('*').execute()
    print(f"Total permission records: {len(all_perms.data)}")
    
    if all_perms.data:
        for perm in all_perms.data:
            print(f"\n   Permission Record:")
            print(f"   - ID: {perm['id']}")
            print(f"   - Manager ID: {perm['manager_id']}")
            print(f"   - Company ID: {perm['company_id']}")
            
            # Try to get manager name
            try:
                mgr = supabase.table('employees').select('*').eq('id', perm['manager_id']).single().execute()
                if mgr.data:
                    print(f"   - Manager Name: {mgr.data.get('name', mgr.data.get('full_name', 'N/A'))}")
            except:
                print(f"   - Manager Name: (could not fetch)")
    else:
        print("   ⚠️ No permission records found!")
except Exception as e:
    print(f"❌ Error checking permissions: {e}")

print("\n" + "=" * 80)
print("✅ DEBUG COMPLETE")
print("=" * 80)
