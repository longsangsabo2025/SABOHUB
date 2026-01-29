#!/usr/bin/env python3

import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

print("=== AUDIT MANAGER DATA ===\n")

# Get manager Diem
diem = supabase.table('employees').select('*').eq('username', 'diem').execute()

if diem.data:
    manager = diem.data[0]
    print("MANAGER DIEM:")
    print(f"  ID: {manager['id']}")
    print(f"  Full Name: {manager.get('full_name')}")
    print(f"  Role: {manager.get('role')}")
    print(f"  Company ID: {manager.get('company_id')}")
    print(f"  Branch ID: {manager.get('branch_id')}")
    print(f"  Is Active: {manager.get('is_active')}")
    
    company_id = manager.get('company_id')
    branch_id = manager.get('branch_id')
    
    if company_id:
        # Get all employees in same company
        employees = supabase.table('employees').select('id, full_name, role').eq('company_id', company_id).eq('is_active', True).execute()
        print(f"\n  EMPLOYEES IN COMPANY: {len(employees.data)}")
        for emp in employees.data:
            print(f"    - {emp.get('full_name')} ({emp.get('role')})")
        
        # Get branches in company
        branches = supabase.table('branches').select('id, name').eq('company_id', company_id).execute()
        print(f"\n  BRANCHES IN COMPANY: {len(branches.data)}")
        for b in branches.data:
            print(f"    - {b.get('name')} (ID: {b['id']})")
    
    if branch_id:
        # Get employees in same branch
        branch_employees = supabase.table('employees').select('id, full_name, role').eq('branch_id', branch_id).eq('is_active', True).execute()
        print(f"\n  EMPLOYEES IN BRANCH: {len(branch_employees.data)}")
        for emp in branch_employees.data:
            print(f"    - {emp.get('full_name')} ({emp.get('role')})")
    else:
        print("\n  ⚠️ MANAGER HAS NO BRANCH_ID!")
