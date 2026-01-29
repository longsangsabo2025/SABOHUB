import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("KIEM TRA TASK MOI TAO")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Tim employee diem
    cur.execute("""
        SELECT id, username, full_name
        FROM employees
        WHERE username = 'diem'
    """)
    
    employee = cur.fetchone()
    if not employee:
        print("KHONG TIM THAY NHAN VIEN DIEM!")
        exit(1)
    
    emp_id, username, name = employee
    print(f"\nNHAN VIEN: {name}")
    print(f"ID: {emp_id}")
    
    # Lay task moi nhat
    print("\n" + "=" * 60)
    print("TASK MOI NHAT TRONG HE THONG:")
    print("=" * 60)
    
    cur.execute("""
        SELECT 
            t.id,
            t.title,
            t.assigned_to,
            t.assigned_to_name,
            t.status,
            t.created_at
        FROM tasks t
        ORDER BY t.created_at DESC
        LIMIT 1
    """)
    
    latest_task = cur.fetchone()
    
    if latest_task:
        task_id, title, assigned_to, assigned_name, status, created = latest_task
        print(f"\nTask: {title}")
        print(f"  ID: {task_id}")
        print(f"  Assigned to ID: {assigned_to}")
        print(f"  Assigned name: {assigned_name}")
        print(f"  Status: {status}")
        print(f"  Created: {created}")
        
        if assigned_to == emp_id:
            print(f"\n  THANH CONG! Task da duoc giao cho {name}!")
        elif assigned_to:
            print(f"\n  CHU Y: Task duoc giao cho ID khac: {assigned_to}")
        else:
            print(f"\n  LOI: Task KHONG duoc giao cho ai (assigned_to = NULL)")
    
    # Dem tasks cua diem
    print("\n" + "=" * 60)
    print(f"TONG SO TASKS CUA {name}:")
    print("=" * 60)
    
    cur.execute("""
        SELECT COUNT(*)
        FROM tasks
        WHERE assigned_to = %s
    """, (emp_id,))
    
    count = cur.fetchone()[0]
    print(f"\nSo luong tasks: {count}")
    
    if count > 0:
        print(f"\nTHANH CONG! {name} co {count} task(s)!")
    else:
        print(f"\nLOI: {name} van KHONG CO task nao!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\nLOI: {str(e)}")
    import traceback
    traceback.print_exc()
