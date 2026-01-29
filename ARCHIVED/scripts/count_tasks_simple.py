import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

company_id = 'feef10d3-899d-4554-8107-b2256918213a'
diem_id = '61715a20-dc93-480c-9dab-f21806114887'

print("=" * 80)
print("KIEM TRA TASKS TRONG COMPANY")
print("=" * 80)

# Count total tasks
cur.execute("""
    SELECT COUNT(*) 
    FROM tasks 
    WHERE company_id = %s 
    AND deleted_at IS NULL
""", (company_id,))

total = cur.fetchone()[0]
print(f"\nTong so tasks trong company: {total}")

# Count tasks assigned to Diem
cur.execute("""
    SELECT COUNT(*) 
    FROM tasks 
    WHERE company_id = %s 
    AND assigned_to = %s
    AND deleted_at IS NULL
""", (company_id, diem_id))

diem_tasks = cur.fetchone()[0]
print(f"Tasks duoc giao cho Diem: {diem_tasks}")

# Get all tasks with details
cur.execute("""
    SELECT id, title, status, assigned_to, created_by, created_at
    FROM tasks 
    WHERE company_id = %s 
    AND deleted_at IS NULL
    ORDER BY created_at DESC
    LIMIT 10
""", (company_id,))

tasks = cur.fetchall()

print(f"\n10 tasks gan nhat:")
for i, task in enumerate(tasks, 1):
    print(f"\n{i}. {task[1]}")
    print(f"   Status: {task[2]}")
    print(f"   Assigned to: {task[3]}")
    print(f"   Created by: {task[4]}")
    print(f"   Created at: {task[5]}")
    
    if task[3] == diem_id:
        print("   >>> ✓ Day la task cua DIEM!")

cur.close()
conn.close()
