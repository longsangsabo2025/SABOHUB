import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cur = conn.cursor()

print("=" * 70)
print("VERIFY MANAGER DIEM PERMISSIONS - FINAL CHECK")
print("=" * 70)

# Get Manager Diem info
cur.execute("""
    SELECT id, full_name, email, company_id
    FROM employees
    WHERE email = 'diem@sabohub.com';
""")
diem = cur.fetchone()

if not diem:
    print("\nKHONG TIM THAY MANAGER DIEM!")
    exit()

diem_id, full_name, email, company_id = diem
print(f"\nManager: {full_name}")
print(f"Email: {email}")
print(f"Employee ID: {diem_id}")
print(f"Company ID: {company_id}")

# Get permissions
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

if not perms:
    print("\n❌ KHONG CO PERMISSIONS!")
    exit()

tab_perms = perms[0:10]
action_perms = perms[10:18]

tab_names = [
    'Tong quan (Overview)',
    'Nhan vien (Employees)',
    'Cong viec (Tasks)',
    'Tai lieu (Documents)',
    'AI Assistant',
    'Cham cong (Attendance)',
    'Ke toan (Accounting)',
    'Ho so NV (Employee Docs)',
    'Luat KD (Business Law)',
    'Cai dat (Settings)'
]

print("\n" + "=" * 70)
print(f"TAB PERMISSIONS: {sum(tab_perms)}/10")
print("=" * 70)

for i, (tab_name, has_perm) in enumerate(zip(tab_names, tab_perms)):
    icon = "✅" if has_perm else "❌"
    print(f"{icon} Tab {i}: {tab_name}")

print("\n" + "=" * 70)
print(f"ACTION PERMISSIONS: {sum(action_perms)}/8")
print("=" * 70)

action_names = [
    'Tao nhan vien', 'Sua nhan vien', 'Xoa nhan vien',
    'Tao cong viec', 'Sua cong viec', 'Xoa cong viec',
    'Duyet cham cong', 'Sua thong tin cong ty'
]

for action_name, has_perm in zip(action_names, action_perms):
    icon = "✅" if has_perm else "❌"
    print(f"{icon} {action_name}")

# Summary
print("\n" + "=" * 70)
if sum(tab_perms) == 10:
    print("🎉 PERFECT! Manager Diem co TOAN QUYEN 10/10 tabs!")
    print("\nKhi login vao app, Manager Diem se thay:")
    print("- Tab 'Cong ty' o bottom navigation")
    print("- Tat ca 10 tabs con ben trong:")
    for i, name in enumerate(tab_names):
        print(f"  {i}. {name}")
else:
    print(f"⚠️ WARNING: Chi co {sum(tab_perms)}/10 tabs duoc cap quyen")
    print("\nCac tabs CHUA duoc cap quyen:")
    for i, (name, has) in enumerate(zip(tab_names, tab_perms)):
        if not has:
            print(f"  ❌ {i}. {name}")

print("=" * 70)

cur.close()
conn.close()
