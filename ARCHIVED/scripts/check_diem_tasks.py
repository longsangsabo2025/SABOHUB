import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

print("=" * 70)
print("KIEM TRA CONG VIEC CUA MANAGER DIEM")
print("=" * 70)

# 1. Get Manager Diem info
cur.execute("""
    SELECT id, full_name, email, company_id, role
    FROM employees
    WHERE email = 'diem@sabohub.com';
""")
diem = cur.fetchone()

if not diem:
    print("\nKHONG TIM THAY MANAGER DIEM!")
    exit()

diem_id, full_name, email, company_id, role = diem
print(f"\nManager: {full_name}")
print(f"Email: {email}")
print(f"Employee ID: {diem_id}")
print(f"Company ID: {company_id}")
print(f"Role: {role}")

# 2. Check ALL tasks in company
print(f"\n{'='*70}")
print("TAT CA CONG VIEC TRONG CONG TY SABO BILLIARDS:")
print("=" * 70)

cur.execute("""
    SELECT 
        t.id,
        t.title,
        t.status,
        t.assigned_to,
        e.full_name as assigned_name,
        t.created_by,
        c.full_name as creator_name,
        t.created_at,
        t.deleted_at
    FROM tasks t
    LEFT JOIN employees e ON t.assigned_to = e.id
    LEFT JOIN employees c ON t.created_by = c.id
    WHERE t.company_id = %s
    ORDER BY t.created_at DESC
    LIMIT 20;
""", (company_id,))

all_tasks = cur.fetchall()

if all_tasks:
    print(f"\nTong so: {len(all_tasks)} tasks")
    for i, task in enumerate(all_tasks, 1):
        task_id, title, status, assigned_to, assigned_name, created_by, creator_name, created_at, deleted_at = task
        deleted_marker = " [DELETED]" if deleted_at else ""
        print(f"\n{i}. {title}{deleted_marker}")
        print(f"   ID: {task_id}")
        print(f"   Status: {status}")
        print(f"   Assigned to: {assigned_name or 'CHUA GIAO'} (ID: {assigned_to})")
        print(f"   Created by: {creator_name} (ID: {created_by})")
        print(f"   Created at: {created_at}")
        if deleted_at:
            print(f"   Deleted at: {deleted_at}")
else:
    print("\n❌ KHONG CO TASK NAO!")

# 3. Check tasks assigned TO Diem
print(f"\n{'='*70}")
print("CONG VIEC DUOC GIAO CHO DIEM:")
print("=" * 70)

cur.execute("""
    SELECT 
        t.id,
        t.title,
        t.status,
        e.full_name as creator_name,
        t.created_at
    FROM tasks t
    LEFT JOIN employees e ON t.created_by = e.id
    WHERE t.company_id = %s 
    AND t.assigned_to = %s
    AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC;
""", (company_id, diem_id))

assigned_tasks = cur.fetchall()

if assigned_tasks:
    print(f"\nCo {len(assigned_tasks)} tasks duoc giao cho Diem:")
    for task in assigned_tasks:
        print(f"\n✅ {task[1]}")
        print(f"   Status: {task[2]}")
        print(f"   Nguoi giao: {task[3]}")
        print(f"   Ngay tao: {task[4]}")
else:
    print("\n❌ KHONG CO TASK NAO DUOC GIAO CHO DIEM!")

# 4. Check tasks created BY Diem
print(f"\n{'='*70}")
print("CONG VIEC DO DIEM TAO RA:")
print("=" * 70)

cur.execute("""
    SELECT 
        t.id,
        t.title,
        t.status,
        e.full_name as assigned_name,
        t.created_at
    FROM tasks t
    LEFT JOIN employees e ON t.assigned_to = e.id
    WHERE t.company_id = %s 
    AND t.created_by = %s
    AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC;
""", (company_id, diem_id))

created_tasks = cur.fetchall()

if created_tasks:
    print(f"\nCo {len(created_tasks)} tasks do Diem tao:")
    for task in created_tasks:
        print(f"\n✅ {task[1]}")
        print(f"   Status: {task[2]}")
        print(f"   Giao cho: {task[3] or 'Chua giao'}")
        print(f"   Ngay tao: {task[4]}")
else:
    print("\n❌ DIEM CHUA TAO TASK NAO!")

# 5. Check WHO is the CEO
print(f"\n{'='*70}")
print("THONG TIN CEO:")
print("=" * 70)

cur.execute("""
    SELECT id, full_name, email, role
    FROM employees
    WHERE company_id = %s AND role = 'CEO'
    LIMIT 1;
""", (company_id,))

ceo = cur.fetchone()
if ceo:
    ceo_id, ceo_name, ceo_email, ceo_role = ceo
    print(f"\nCEO: {ceo_name}")
    print(f"Email: {ceo_email}")
    print(f"CEO ID: {ceo_id}")
    
    # Check tasks CEO assigned to others
    cur.execute("""
        SELECT 
            t.id,
            t.title,
            t.status,
            e.full_name as assigned_name,
            t.assigned_to,
            t.created_at
        FROM tasks t
        LEFT JOIN employees e ON t.assigned_to = e.id
        WHERE t.company_id = %s 
        AND t.created_by = %s
        AND t.deleted_at IS NULL
        ORDER BY t.created_at DESC;
    """, (company_id, ceo_id))
    
    ceo_tasks = cur.fetchall()
    if ceo_tasks:
        print(f"\n\nCEO da giao {len(ceo_tasks)} tasks:")
        for task in ceo_tasks:
            is_for_diem = " ← CHO DIEM!" if task[4] == diem_id else ""
            print(f"\n✅ {task[1]}{is_for_diem}")
            print(f"   Status: {task[2]}")
            print(f"   Giao cho: {task[3] or 'Chua giao'} (ID: {task[4]})")
            print(f"   Ngay tao: {task[5]}")
else:
    print("\n❌ KHONG TIM THAY CEO!")

print("\n" + "=" * 70)
print("KET LUAN:")
print("=" * 70)

if assigned_tasks:
    print(f"✅ Diem CO {len(assigned_tasks)} tasks duoc giao")
    print("\nNEU KHONG HIEN THI TREN UI:")
    print("- Kiem tra query trong TasksTab co dung khong")
    print("- Kiem tra filter (recurrence, status) co bi loi khong")
    print("- Kiem tra RLS tren tasks table")
else:
    print("❌ Diem KHONG CO tasks nao duoc giao")
    print("\nNguyen nhan co the:")
    print("- CEO chua THUC SU giao task cho Diem")
    print("- Task bi soft delete (deleted_at != NULL)")
    print("- assigned_to ID khong khop voi Diem employee ID")

cur.close()
conn.close()
