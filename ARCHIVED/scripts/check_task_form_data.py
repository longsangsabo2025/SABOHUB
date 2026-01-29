#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Check if there are managers and companies in the database
"""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

print("Checking data for Task Creation form...\n")

# Check Managers
try:
    managers = supabase.table('users').select('id, full_name, role').eq('role', 'BRANCH_MANAGER').execute()
    print(f"MANAGERS (role='BRANCH_MANAGER'): {len(managers.data)}")
    if managers.data:
        for m in managers.data[:3]:  # Show first 3
            print(f"   - {m['full_name']}")
    else:
        print("   WARNING: NO MANAGERS FOUND!")
        print("   Need to create users with role='BRANCH_MANAGER'")
except Exception as e:
    print(f"   ERROR: {e}")

print()

# Check Companies
try:
    companies = supabase.table('companies').select('id, name').execute()
    print(f"COMPANIES: {len(companies.data)}")
    if companies.data:
        for c in companies.data[:5]:  # Show first 5
            print(f"   - {c['name']}")
    else:
        print("   WARNING: NO COMPANIES FOUND!")
        print("   Need to create companies first")
except Exception as e:
    print(f"   ERROR: {e}")

print()

# Check all user roles
try:
    users = supabase.table('users').select('role').execute()
    roles = {}
    for u in users.data:
        role = u['role']
        roles[role] = roles.get(role, 0) + 1
    
    print("USER ROLES SUMMARY:")
    for role, count in roles.items():
        print(f"   - {role}: {count}")
except Exception as e:
    print(f"   ERROR: {e}")
