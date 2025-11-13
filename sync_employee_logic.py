"""
Kiểm tra và đồng bộ logic:
- CEO trong bảng users (auth.users)
- Employees (Manager/Shift Leader/Staff) trong bảng employees (custom auth)
"""
import psycopg2
from datetime import datetime

# Transaction pooler connection
CONN_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 80)
print("🔍 KIỂM TRA VÀ ĐỒNG BỘ EMPLOYEE LOGIC")
print("=" * 80)

conn = psycopg2.connect(CONN_STRING)
cur = conn.cursor()

print("\n1️⃣ KIỂM TRA BẢNG USERS (chỉ CEO)")
print("-" * 80)

cur.execute("""
    SELECT 
        id, 
        email, 
        raw_user_meta_data->>'full_name' as full_name,
        raw_user_meta_data->>'role' as role,
        raw_user_meta_data->>'company_id' as company_id
    FROM auth.users
    ORDER BY created_at DESC;
""")
users = cur.fetchall()

ceo_count = 0
employee_in_users = 0

for user in users:
    user_id, email, full_name, role, company_id = user
    print(f"  • {email} - {full_name} - Role: {role}")
    if role == 'CEO' or role == 'ceo':
        ceo_count += 1
    else:
        employee_in_users += 1
        print(f"    ⚠️  WARNING: Employee found in users table!")

print(f"\n✅ CEO users: {ceo_count}")
if employee_in_users > 0:
    print(f"❌ Employee trong users table (SAI): {employee_in_users}")
else:
    print(f"✅ Không có employee trong users table")

print("\n2️⃣ KIỂM TRA BẢNG EMPLOYEES (Manager/Shift Leader/Staff)")
print("-" * 80)

cur.execute("""
    SELECT 
        id,
        email,
        full_name,
        role,
        company_id,
        is_active,
        password_hash IS NOT NULL as has_password
    FROM employees
    WHERE is_active = true
    ORDER BY created_at DESC;
""")
employees = cur.fetchall()

manager_count = 0
shift_leader_count = 0
staff_count = 0

for emp in employees:
    emp_id, email, full_name, role, company_id, is_active, has_password = emp
    print(f"  • {email} - {full_name} - {role} - Password: {has_password}")
    
    if role == 'MANAGER':
        manager_count += 1
    elif role == 'SHIFT_LEADER':
        shift_leader_count += 1
    elif role == 'STAFF':
        staff_count += 1

print(f"\n📊 Employee Stats:")
print(f"  Managers: {manager_count}")
print(f"  Shift Leaders: {shift_leader_count}")
print(f"  Staff: {staff_count}")
print(f"  Total: {len(employees)}")

print("\n3️⃣ KIỂM TRA RLS POLICIES")
print("-" * 80)

# Check employees table RLS
cur.execute("""
    SELECT 
        schemaname,
        tablename,
        policyname,
        cmd,
        qual,
        with_check
    FROM pg_policies
    WHERE tablename = 'employees'
    ORDER BY policyname;
""")
employee_policies = cur.fetchall()

print("📋 Employees Table RLS Policies:")
for policy in employee_policies:
    schema, table, name, cmd, qual, with_check = policy
    print(f"  • {name} - {cmd}")

# Check users table access
cur.execute("""
    SELECT 
        schemaname,
        tablename,
        policyname,
        cmd
    FROM pg_policies
    WHERE tablename = 'users' AND schemaname = 'public'
    ORDER BY policyname;
""")
user_policies = cur.fetchall()

print("\n📋 Users Table RLS Policies:")
for policy in user_policies:
    schema, table, name, cmd = policy
    print(f"  • {name} - {cmd}")

print("\n4️⃣ KIỂM TRA FLUTTER CODE ĐANG QUERY TỪ ĐÂU")
print("-" * 80)
print("""
❌ CÁC FILE SAI (đang query users thay vì employees):
  1. lib/services/staff_service.dart
     - getAllStaff() -> from('users')
     - getStaffById() -> from('users')
     - getStaffByRole() -> from('users')
     
  2. lib/services/employee_service.dart
     - createEmployeeAccount() -> Tạo vào auth.users
     
  3. lib/services/manager_kpi_service.dart
     - Query từ users để đếm STAFF
     
✅ FILE ĐÚNG:
  1. lib/providers/employee_provider.dart
     - Query từ 'employees' table
""")

print("\n5️⃣ ĐỀ XUẤT SỬA CHỮA")
print("-" * 80)
print("""
🔧 CẦN SỬA:

1️⃣ staff_service.dart:
   - getAllStaff() -> from('employees')
   - getStaffById() -> from('employees')
   - getStaffByRole() -> from('employees')
   - subscribeToStaff() -> from('employees').stream()

2️⃣ employee_service.dart:
   - createEmployeeAccount() -> INSERT vào 'employees' table
   - KHÔNG tạo auth.users cho employees
   - Employees login qua custom auth với email/password

3️⃣ manager_kpi_service.dart:
   - Query từ 'employees' thay vì 'users'

📝 KIẾN TRÚC ĐÚNG:
   
   ┌─────────────────────────────────────────┐
   │  AUTHENTICATION                         │
   ├─────────────────────────────────────────┤
   │                                         │
   │  CEO:                                   │
   │    - Bảng: auth.users (Supabase Auth)  │
   │    - Login: Supabase signInWithPassword│
   │    - Role: 'CEO'                        │
   │                                         │
   │  Employees (Manager/Shift Leader/Staff):│
   │    - Bảng: employees (Custom Table)     │
   │    - Login: Custom email/password check │
   │    - Roles: MANAGER, SHIFT_LEADER, STAFF│
   │    - Password: bcrypt hash in DB        │
   │                                         │
   └─────────────────────────────────────────┘
""")

print("\n6️⃣ TEST EMPLOYEE LOGIN")
print("-" * 80)

cur.execute("""
    SELECT 
        email,
        full_name,
        role,
        password_hash IS NOT NULL as can_login
    FROM employees
    WHERE is_active = true
    LIMIT 5;
""")
test_employees = cur.fetchall()

print("🧪 Sample Employees (có thể login):")
for emp in test_employees:
    email, name, role, can_login = emp
    status = "✅ Có password" if can_login else "❌ Chưa có password"
    print(f"  • {email} ({role}) - {status}")

cur.close()
conn.close()

print("\n" + "=" * 80)
print("✅ KIỂM TRA HOÀN TẤT")
print("=" * 80)
