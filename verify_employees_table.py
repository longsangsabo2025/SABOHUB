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
print("🔍 KIỂM TRA BẢNG EMPLOYEES")
print("="*80)

# 1. Check employees table structure
print("\n📋 1. Cấu trúc bảng employees:")
cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'employees'
    ORDER BY ordinal_position;
""")
columns = cursor.fetchall()
for col in columns:
    print(f"  - {col[0]}: {col[1]}")

# 2. Check managers in employees table
print("\n📋 2. Managers trong bảng employees:")
cursor.execute("""
    SELECT id, name, role, company_id, branch_id 
    FROM employees 
    WHERE role = 'manager'
    ORDER BY name;
""")
managers = cursor.fetchall()
print(f"✅ Tìm thấy {len(managers)} managers:")
for m in managers:
    print(f"\n  Manager: {m[1]}")
    print(f"    ID: {m[0]}")
    print(f"    Role: {m[2]}")
    print(f"    Company: {m[3]}")
    print(f"    Branch: {m[4]}")

# 3. Check manager_permissions and join with employees
print("\n📋 3. Manager permissions JOIN với employees:")
cursor.execute("""
    SELECT 
        mp.id as permission_id,
        mp.manager_id,
        e.name as manager_name,
        e.role,
        mp.company_id,
        mp.can_view_overview,
        mp.can_view_employees,
        mp.can_view_tasks,
        mp.can_view_attendance
    FROM manager_permissions mp
    INNER JOIN employees e ON mp.manager_id = e.id
    ORDER BY e.name;
""")
permissions = cursor.fetchall()
print(f"✅ Tìm thấy {len(permissions)} permission records với employee data:")
for p in permissions:
    print(f"\n  Permission ID: {p[0]}")
    print(f"    Manager: {p[2]} (ID: {p[1]})")
    print(f"    Role in employees: {p[3]}")
    print(f"    Company: {p[4]}")
    print(f"    Permissions: Overview={p[5]}, Employees={p[6]}, Tasks={p[7]}, Attendance={p[8]}")

# 4. Check if there are any orphaned permissions
print("\n📋 4. Kiểm tra permissions không có employee tương ứng:")
cursor.execute("""
    SELECT mp.id, mp.manager_id
    FROM manager_permissions mp
    LEFT JOIN employees e ON mp.manager_id = e.id
    WHERE e.id IS NULL;
""")
orphaned = cursor.fetchall()
if len(orphaned) > 0:
    print(f"⚠️ Có {len(orphaned)} permissions không tìm thấy employee:")
    for o in orphaned:
        print(f"  - Permission {o[0]} → Manager ID {o[1]} (NOT FOUND)")
else:
    print("✅ Tất cả permissions đều có employee tương ứng")

cursor.close()
conn.close()

print("\n" + "="*80)
