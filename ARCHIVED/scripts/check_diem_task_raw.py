#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

print("=== KIEM TRA TASK CHO DIEM ===\n")

# Get Diem's employee ID
diem_id = "61715a20-dc93-480c-9dab-f21806114887"

# Get latest task
result = supabase.table('tasks').select('*').order('created_at', desc=True).limit(1).execute()
if result.data:
    task = result.data[0]
    print(f"TASK MOI NHAT:")
    print(f"  ID: {task.get('id')}")
    print(f"  Title: {task.get('title')}")
    print(f"  Assigned To: {task.get('assigned_to')}")
    print(f"  Assigned To Name: {task.get('assigned_to_name')}")
    print(f"  Created At: {task.get('created_at')}")
    
    if task.get('assigned_to') == diem_id:
        print("\n✓ TASK DA DUOC GIAO CHO DIEM!")
    else:
        print(f"\n✗ Task assigned to: {task.get('assigned_to')}")

# Count tasks for Diem
count_result = supabase.table('tasks').select('*', count='exact').eq('assigned_to', diem_id).execute()
print(f"\nTONG SO TASK CUA DIEM: {count_result.count}")
