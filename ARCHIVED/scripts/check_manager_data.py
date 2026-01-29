import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

# Database connection
conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    database="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password=os.getenv('SUPABASE_DB_PASSWORD')
)

cursor = conn.cursor()

print("\n" + "="*80)
print("🔍 KIỂM TRA MANAGER VÀ PERMISSIONS")
print("="*80)

# 1. Check employees with role = manager
print("\n📋 1. Kiểm tra nhân viên có role = 'manager':")
cursor.execute("""
    SELECT id, name, role, company_id, branch_id 
    FROM employees 
    WHERE role = 'manager'
    ORDER BY name;
""")
managers = cursor.fetchall()
print(f"✅ Tìm thấy {len(managers)} managers:")
for m in managers:
    print(f"  - {m[1]} (ID: {m[0]})")
    print(f"    Company: {m[3]}, Branch: {m[4]}")

# 2. Check manager_permissions table
print("\n📋 2. Kiểm tra bảng manager_permissions:")
cursor.execute("""
    SELECT 
        mp.id,
        mp.manager_id,
        e.name as manager_name,
        mp.company_id,
        mp.can_view_overview,
        mp.can_view_employees,
        mp.can_view_tasks,
        mp.can_view_attendance
    FROM manager_permissions mp
    LEFT JOIN employees e ON mp.manager_id = e.id
    ORDER BY e.name;
""")
permissions = cursor.fetchall()
print(f"✅ Tìm thấy {len(permissions)} permission records:")
for p in permissions:
    print(f"  - {p[2]}")
    print(f"    Overview: {p[4]}, Employees: {p[5]}, Tasks: {p[6]}, Attendance: {p[7]}")

# 3. Check if manager_id matches employee.id
print("\n📋 3. Kiểm tra foreign key constraint:")
cursor.execute("""
    SELECT 
        mp.manager_id,
        e.id as employee_id,
        e.name,
        CASE WHEN e.id IS NOT NULL THEN 'OK' ELSE 'MISSING' END as status
    FROM manager_permissions mp
    LEFT JOIN employees e ON mp.manager_id = e.id;
""")
fk_check = cursor.fetchall()
for row in fk_check:
    print(f"  Permission manager_id: {row[0]} → Employee: {row[2]} ({row[3]})")

# 4. Get company info
print("\n📋 4. Thông tin công ty:")
cursor.execute("""
    SELECT DISTINCT c.id, c.name, c.type
    FROM companies c
    INNER JOIN employees e ON e.company_id = c.id
    WHERE e.role = 'manager';
""")
companies = cursor.fetchall()
for c in companies:
    print(f"  - {c[1]} (ID: {c[0]}, Type: {c[2]})")

cursor.close()
conn.close()

print("\n" + "="*80)
