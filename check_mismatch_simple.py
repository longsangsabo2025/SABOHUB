#!/usr/bin/env python3

import os
from supabase import create_client
from dotenv import load_dotenv
import json

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, key)

# Get company
company = supabase.table('companies').select('id, name').eq('name', 'SABO Billiards').execute()
print("COMPANY:")
print(json.dumps(company.data, indent=2, ensure_ascii=False))

# Get Diem
diem = supabase.table('employees').select('id, username, company_id').eq('username', 'diem').execute()
print("\nDIEM:")
print(json.dumps(diem.data, indent=2, ensure_ascii=False))

# Get task
task = supabase.table('tasks').select('id, title, company_id, assigned_to').eq('assigned_to', '61715a20-dc93-480c-9dab-f21806114887').execute()
print("\nTASK:")
print(json.dumps(task.data, indent=2, ensure_ascii=False))
