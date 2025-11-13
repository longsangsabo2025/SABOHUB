import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

task_id = '4b4971a9-78d4-44c7-9f7a-17ab750e27cb'

print("=" * 70)
print(f"KIEM TRA CHI TIET TASK: {task_id}")
print("=" * 70)

cur.execute("""
    SELECT 
        id, title, status, category, priority, recurrence,
        assigned_to, assigned_to_name, assigned_to_role,
        created_by, created_by_name,
        due_date, created_at, deleted_at
    FROM tasks 
    WHERE id = %s;
""", (task_id,))

task = cur.fetchone()

if task:
    print(f"\nTitle: {task[1]}")
    print(f"Status: {task[2]}")
    print(f"Category: {task[3]}")
    print(f"Priority: {task[4]}")
    print(f"Recurrence: {task[5]}")
    print(f"\nassigned_to (ID): {task[6]}")
    print(f"assigned_to_name: {task[7] if task[7] else '❌ NULL'}")
    print(f"assigned_to_role: {task[8] if task[8] else '❌ NULL'}")
    print(f"\ncreated_by (ID): {task[9]}")
    print(f"created_by_name: {task[10] if task[10] else '❌ NULL'}")
    print(f"\ndue_date: {task[11]}")
    print(f"created_at: {task[12]}")
    print(f"deleted_at: {task[13] if task[13] else 'NULL (not deleted)'}")
    
    print("\n" + "=" * 70)
    print("VAN DE:")
    print("=" * 70)
    if not task[7]:
        print("❌ assigned_to_name la NULL!")
        print("   → Can update trigger hoac fix query de populate field nay")
    if not task[10]:
        print("❌ created_by_name la NULL!")
        print("   → Can update trigger hoac fix query de populate field nay")
else:
    print("KHONG TIM THAY TASK!")

cur.close()
conn.close()
