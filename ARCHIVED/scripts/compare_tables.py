#!/usr/bin/env python3
"""
Compare users vs employees tables
"""

import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

supabase = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_SERVICE_ROLE_KEY'))

company_id = 'feef10d3-899d-4554-8107-b2256918213a'

print("=" * 80)
print("📊 COMPARING TABLES: users vs employees")
print("=" * 80)

# Check users table
print("\n1️⃣ USERS TABLE (CEO uses this):")
print("-" * 80)
users = supabase.table('users')\
    .select('full_name, role')\
    .eq('company_id', company_id)\
    .is_('deleted_at', 'null')\
    .execute()

print(f"Count: {len(users.data)}")
for u in users.data:
    print(f"  ✅ {u.get('full_name')} - {u.get('role')}")

# Check employees table
print("\n2️⃣ EMPLOYEES TABLE (App queries this):")
print("-" * 80)
emps = supabase.table('employees')\
    .select('full_name, role')\
    .eq('company_id', company_id)\
    .eq('is_active', True)\
    .execute()

print(f"Count: {len(emps.data)}")
for e in emps.data:
    print(f"  ✅ {e.get('full_name')} - {e.get('role')}")

print("\n" + "=" * 80)
print("🎯 DIAGNOSIS:")
print("=" * 80)

if len(users.data) != len(emps.data):
    print(f"""
❌ MISMATCH DETECTED!
   users table: {len(users.data)} employees
   employees table: {len(emps.data)} employees
   
🔧 PROBLEM: 
   App is querying from 'employees' table
   But data exists in 'users' table
   
💡 SOLUTION:
   Fix employee_provider.dart to query from 'users' table instead
   OR sync data from users → employees table
    """)
else:
    print(f"✅ Tables match! Both have {len(users.data)} employees")
