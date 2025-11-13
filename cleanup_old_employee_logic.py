"""
Cleanup old employee logic - Xóa 6 employees sai trong auth.users
Chỉ giữ lại CEO users
"""
import psycopg2

CONN_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 80)
print("🧹 CLEANUP - XÓA EMPLOYEES SAI TRONG AUTH.USERS")
print("=" * 80)

conn = psycopg2.connect(CONN_STRING)
cur = conn.cursor()

print("\n1️⃣ KIỂM TRA EMPLOYEES TRONG AUTH.USERS (SAI)")
print("-" * 80)

cur.execute("""
    SELECT 
        id,
        email,
        raw_user_meta_data->>'full_name' as full_name,
        raw_user_meta_data->>'role' as role
    FROM auth.users
    WHERE raw_user_meta_data->>'role' NOT IN ('CEO', 'ceo')
    ORDER BY created_at DESC;
""")
wrong_employees = cur.fetchall()

if not wrong_employees:
    print("✅ Không có employees sai trong auth.users")
    cur.close()
    conn.close()
    exit(0)

print(f"❌ Tìm thấy {len(wrong_employees)} employees SAI trong auth.users:")
for emp_id, email, full_name, role in wrong_employees:
    print(f"  • {email} - {full_name} - {role}")

print("\n2️⃣ KIỂM TRA EMPLOYEES TRONG EMPLOYEES TABLE (ĐÚNG)")
print("-" * 80)

cur.execute("""
    SELECT email, full_name, role
    FROM employees
    WHERE is_active = true
    ORDER BY created_at DESC;
""")
correct_employees = cur.fetchall()

print(f"✅ Có {len(correct_employees)} employees ĐÚNG trong employees table:")
for email, full_name, role in correct_employees:
    print(f"  • {email or 'N/A'} - {full_name} - {role}")

print("\n3️⃣ XÓA EMPLOYEES SAI TRONG AUTH.USERS")
print("-" * 80)

response = input("\n⚠️  Bạn có chắc muốn XÓA employees trong auth.users? (yes/no): ")

if response.lower() != 'yes':
    print("❌ Hủy bỏ cleanup")
    cur.close()
    conn.close()
    exit(0)

print("\n🗑️  Đang xóa...")

for emp_id, email, full_name, role in wrong_employees:
    try:
        # Delete from auth.users
        cur.execute("DELETE FROM auth.users WHERE id = %s", (emp_id,))
        print(f"  ✅ Deleted: {email} ({role})")
    except Exception as e:
        print(f"  ❌ Error deleting {email}: {e}")

conn.commit()

print("\n4️⃣ VERIFY CLEANUP")
print("-" * 80)

# Check remaining users in auth.users
cur.execute("""
    SELECT 
        raw_user_meta_data->>'role' as role,
        COUNT(*) as count
    FROM auth.users
    GROUP BY raw_user_meta_data->>'role';
""")
remaining = cur.fetchall()

print("Remaining users in auth.users:")
for role, count in remaining:
    print(f"  {role}: {count}")

cur.close()
conn.close()

print("\n" + "=" * 80)
print("✅ CLEANUP COMPLETE")
print("=" * 80)
print("""
📊 FINAL STATE:
  - auth.users: Chỉ có CEO users
  - employees table: Có tất cả employees (Manager/Shift Leader/Staff)
  
🎯 ARCHITECTURE CLEAN:
  CEO → auth.users (Supabase Auth)
  Employees → employees table (Custom Auth)
""")
