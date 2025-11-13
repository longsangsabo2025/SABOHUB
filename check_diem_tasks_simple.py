import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("KIEM TRA TASKS CUA NHAN VIEN DIEM")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Tim employee diem
    cur.execute("""
        SELECT id, username, full_name, company_id, branch_id
        FROM employees
        WHERE username = 'diem' OR email LIKE '%diem%'
    """)
    
    employee = cur.fetchone()
    if not employee:
        print("KHONG TIM THAY NHAN VIEN DIEM!")
        exit(1)
    
    emp_id, username, name, company_id, branch_id = employee
    print(f"\nNHAN VIEN: {name}")
    print(f"ID: {emp_id}")
    print(f"Username: {username}")
    print(f"Company: {company_id}")
    print(f"Branch: {branch_id}")
    
    # Kiem tra tasks
    print("\n" + "=" * 60)
    print("TAT CA TASKS TRONG HE THONG:")
    print("=" * 60)
    
    cur.execute("""
        SELECT 
            t.id,
            t.title,
            t.assigned_to,
            t.assigned_to_name,
            t.status,
            t.company_id,
            t.branch_id
        FROM tasks t
        ORDER BY t.created_at DESC
        LIMIT 10
    """)
    
    all_tasks = cur.fetchall()
    
    if all_tasks:
        for task in all_tasks:
            task_id, title, assigned_to, assigned_name, status, comp_id, br_id = task
            print(f"\nTask: {title}")
            print(f"  ID: {task_id}")
            print(f"  Assigned to ID: {assigned_to}")
            print(f"  Assigned name: {assigned_name}")
            print(f"  Status: {status}")
            print(f"  Company: {comp_id}, Branch: {br_id}")
    else:
        print("\nKHONG CO TASK NAO!")
    
    # Kiem tra tasks cua diem
    print("\n" + "=" * 60)
    print(f"TASKS CUA {name} (ID: {emp_id}):")
    print("=" * 60)
    
    cur.execute("""
        SELECT 
            t.id,
            t.title,
            t.assigned_to,
            t.assigned_to_name,
            t.status
        FROM tasks t
        WHERE t.assigned_to = %s
    """, (emp_id,))
    
    diem_tasks = cur.fetchall()
    
    if diem_tasks:
        print(f"\nTim thay {len(diem_tasks)} task(s):")
        for task in diem_tasks:
            task_id, title, assigned_to, assigned_name, status = task
            print(f"\n  Task: {title}")
            print(f"  ID: {task_id}")
            print(f"  Assigned to: {assigned_to}")
            print(f"  Assigned name: {assigned_name}")
            print(f"  Status: {status}")
    else:
        print(f"\nKHONG CO TASK NAO CHO {name}!")
        print("\nKiem tra:")
        print(f"  - Employee ID: {emp_id}")
        print("  - Neu ban vua tao task, kiem tra assigned_to co dung employee ID nay khong")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\nLOI: {str(e)}")
    import traceback
    traceback.print_exc()
