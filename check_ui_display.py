#!/usr/bin/env python3
"""
Detailed check: What employees should UI show vs what it actually queries
"""

import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))

company_id = 'feef10d3-899d-4554-8107-b2256918213a'

print("=" * 80)
print("🔍 DETAILED EMPLOYEE CHECK")
print("=" * 80)

# What UI should query (exactly what the provider does)
print("\n1️⃣ What UI queries (from employee_provider.dart):")
print("-" * 80)
print("Query: employees table WHERE company_id = X AND is_active = true")
print()

employees = supabase.table('employees')\
    .select('id, full_name, username, role, is_active, created_at')\
    .eq('company_id', company_id)\
    .eq('is_active', True)\
    .execute()

print(f"Result: {len(employees.data)} employees\n")
for idx, e in enumerate(employees.data, 1):
    print(f"{idx}. {e.get('full_name'):25s} | {e.get('role'):15s} | Active: {e.get('is_active')}")
    print(f"   Username: {e.get('username')}")
    print(f"   Created: {e.get('created_at')}")
    print()

# Check if there are inactive employees
print("\n2️⃣ Checking for INACTIVE employees:")
print("-" * 80)
inactive = supabase.table('employees')\
    .select('id, full_name, username, role, is_active')\
    .eq('company_id', company_id)\
    .eq('is_active', False)\
    .execute()

if inactive.data:
    print(f"Found {len(inactive.data)} INACTIVE employees (not shown in UI):\n")
    for e in inactive.data:
        print(f"  ⚠️  {e.get('full_name')} ({e.get('role')})")
        print(f"     Username: {e.get('username')}")
        print()
else:
    print("✅ No inactive employees")

# Check ALL employees regardless of status
print("\n3️⃣ ALL employees (active + inactive):")
print("-" * 80)
all_employees = supabase.table('employees')\
    .select('id, full_name, username, role, is_active')\
    .eq('company_id', company_id)\
    .execute()

print(f"Total: {len(all_employees.data)} employees\n")
active_count = sum(1 for e in all_employees.data if e.get('is_active'))
inactive_count = len(all_employees.data) - active_count

print(f"  Active: {active_count}")
print(f"  Inactive: {inactive_count}")

# Summary
print("\n" + "=" * 80)
print("📊 SUMMARY")
print("=" * 80)
print(f"""
Database Status:
- Total employees in employees table: {len(all_employees.data)}
- Active (will show in UI): {active_count}
- Inactive (hidden from UI): {inactive_count}

Expected UI Display: {active_count} employees

If UI shows different number:
1. Check RLS policies - CEO might not have access
2. Check browser cache - try hard refresh (Ctrl+Shift+R)
3. Check console errors in browser DevTools
4. Provider might be cached - invalidate provider

Employees that SHOULD appear in UI:
""")

for e in employees.data:
    print(f"  ✅ {e.get('full_name')} ({e.get('role')})")
