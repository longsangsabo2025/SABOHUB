import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

print("=" * 70)
print("🔍 KIỂM TRA TOÀN DIỆN MANAGER DIỄM")
print("=" * 70)

# 1. Kiểm tra thông tin Manager Diễm
print("\n1️⃣ Thông tin Manager Diễm:")
cur.execute("""
    SELECT id, full_name, email, role, company_id, user_id
    FROM employees
    WHERE email = 'diem@sabohub.com';
""")
diem = cur.fetchone()
if diem:
    print(f"   ✅ Tên: {diem[1]}")
    print(f"   📧 Email: {diem[2]}")
    print(f"   👔 Role: {diem[3]}")
    print(f"   🏢 Company ID: {diem[4]}")
    print(f"   🆔 Employee ID: {diem[0]}")
    print(f"   👤 User ID: {diem[5]}")
    diem_id = diem[0]
    company_id = diem[4]
else:
    print("   ❌ Không tìm thấy Manager Diễm!")
    exit()

# 2. Kiểm tra permissions của Manager Diễm
print(f"\n2️⃣ Permissions của Manager Diễm:")
cur.execute("""
    SELECT 
        can_view_overview, can_view_employees, can_view_tasks, 
        can_view_documents, can_view_ai_assistant, can_view_attendance,
        can_view_accounting, can_view_employee_docs, can_view_business_law,
        can_view_settings,
        can_create_employee, can_edit_employee, can_delete_employee,
        can_create_task, can_edit_task, can_delete_task,
        can_approve_attendance, can_edit_company_info
    FROM manager_permissions
    WHERE manager_id = %s AND company_id = %s;
""", (diem_id, company_id))
perms = cur.fetchone()

if perms:
    tab_permissions = perms[0:10]
    action_permissions = perms[10:18]
    
    tab_names = [
        'Tổng quan', 'Nhân viên', 'Công việc', 'Tài liệu', 'AI Assistant',
        'Chấm công', 'Kế toán', 'Hồ sơ NV', 'Luật KD', 'Cài đặt'
    ]
    
    print(f"   📋 TAB PERMISSIONS ({sum(tab_permissions)}/10):")
    for i, (tab_name, has_perm) in enumerate(zip(tab_names, tab_permissions)):
        icon = "✅" if has_perm else "❌"
        print(f"      {icon} {i}. {tab_name}")
    
    action_names = [
        'Tạo NV', 'Sửa NV', 'Xóa NV', 'Tạo CV', 
        'Sửa CV', 'Xóa CV', 'Duyệt CC', 'Sửa TT công ty'
    ]
    
    print(f"\n   ⚡ ACTION PERMISSIONS ({sum(action_permissions)}/8):")
    for action_name, has_perm in zip(action_names, action_permissions):
        icon = "✅" if has_perm else "❌"
        print(f"      {icon} {action_name}")
else:
    print("   ❌ KHÔNG TÌM THẤY PERMISSIONS!")

# 3. Kiểm tra tasks của công ty
print(f"\n3️⃣ Kiểm tra tasks của công ty SABO Billiards:")
cur.execute("""
    SELECT COUNT(*) 
    FROM tasks
    WHERE company_id = %s AND deleted_at IS NULL;
""", (company_id,))
task_count = cur.fetchone()[0]
print(f"   📊 Tổng số tasks: {task_count}")

if task_count > 0:
    cur.execute("""
        SELECT id, title, status, assigned_to, created_at
        FROM tasks
        WHERE company_id = %s AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 5;
    """, (company_id,))
    tasks = cur.fetchall()
    print(f"   📝 5 tasks gần nhất:")
    for task in tasks:
        print(f"      - {task[1]} (status: {task[2]})")

# 4. Kiểm tra attendance records
print(f"\n4️⃣ Kiểm tra attendance của công ty:")
cur.execute("""
    SELECT COUNT(*)
    FROM attendance
    WHERE company_id = %s AND deleted_at IS NULL;
""", (company_id,))
att_count = cur.fetchone()[0]
print(f"   📊 Tổng số attendance records: {att_count}")

if att_count > 0:
    cur.execute("""
        SELECT id, employee_id, check_in_time, check_out_time, status
        FROM attendance
        WHERE company_id = %s AND deleted_at IS NULL
        ORDER BY check_in_time DESC
        LIMIT 5;
    """, (company_id,))
    attendances = cur.fetchall()
    print(f"   📝 5 attendance gần nhất:")
    for att in attendances:
        print(f"      - Employee: {att[1]}, Status: {att[4]}")

# 5. Kiểm tra RLS trên các bảng
print(f"\n5️⃣ Kiểm tra RLS status:")
tables = ['tasks', 'attendance', 'companies', 'employees']
for table in tables:
    cur.execute("""
        SELECT relrowsecurity 
        FROM pg_class 
        WHERE relname = %s;
    """, (table,))
    rls_status = cur.fetchone()
    if rls_status:
        status = "🔒 ENABLED" if rls_status[0] else "🔓 DISABLED"
        print(f"   {status} - {table}")

# 6. Kiểm tra employees của công ty
print(f"\n6️⃣ Nhân viên trong công ty:")
cur.execute("""
    SELECT COUNT(*)
    FROM employees
    WHERE company_id = %s AND deleted_at IS NULL;
""", (company_id,))
emp_count = cur.fetchone()[0]
print(f"   👥 Tổng số nhân viên: {emp_count}")

cur.close()
conn.close()

print("\n" + "=" * 70)
print("✅ KIỂM TRA HOÀN TẤT")
print("=" * 70)
