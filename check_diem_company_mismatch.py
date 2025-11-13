#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

print("=== KIEM TRA COMPANY MISMATCH ===\n")

# Get all companies
companies = supabase.table('companies').select('*').execute()
print("DANH SACH COMPANIES:")
for c in companies.data:
    print(f"  ID: {c['id']}")
    print(f"  Name: '{c['name']}'")
    print(f"  CEO ID: {c.get('ceo_id')}")
    print()

# Get Diem employee
diem = supabase.table('employees').select('*').eq('username', 'diem').execute()
if diem.data:
    emp = diem.data[0]
    print("NHAN VIEN DIEM:")
    print(f"  ID: {emp['id']}")
    print(f"  Full Name: {emp['full_name']}")
    print(f"  Username: {emp['username']}")
    print(f"  Company ID: {emp.get('company_id')}")
    print(f"  Company Name: '{emp.get('company_name')}'")
    print()
    
    # Check if company_id matches any company
    if emp.get('company_id'):
        matching = [c for c in companies.data if c['id'] == emp['company_id']]
        if matching:
            print(f"COMPANY MATCH: '{matching[0]['name']}'")
        else:
            print("KHONG TIM THAY COMPANY VOI ID NAY!")
    else:
        print("DIEM CHUA CO COMPANY_ID!")

# Get task for Diem
tasks = supabase.table('tasks').select('*').eq('assigned_to', '61715a20-dc93-480c-9dab-f21806114887').execute()
print(f"\nTASKS CUA DIEM: {len(tasks.data)}")
if tasks.data:
    for t in tasks.data:
        print(f"  Task: {t['title']}")
        print(f"  Company ID: {t.get('company_id')}")
        print(f"  Branch ID: {t.get('branch_id')}")
