"""
SCRIPT TỰ ĐỘNG CHẠY MIGRATION - FIX CRITICAL ISSUES
Chạy file này để tự động fix các vấn đề critical trong database
"""

import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get connection string
CONN_STRING = os.getenv('SUPABASE_CONNECTION_STRING')

print("=" * 80)
print("🚀 CHẠY MIGRATION TỰ ĐỘNG - FIX CRITICAL ISSUES")
print("=" * 80)
print()

# Read migration file
migration_file = 'supabase/migrations/20251112_fix_critical_simple.sql'

print(f"📄 Đọc file migration: {migration_file}")

try:
    with open(migration_file, 'r', encoding='utf-8') as f:
        migration_sql = f.read()
    print(f"✅ Đọc thành công ({len(migration_sql)} characters)")
except FileNotFoundError:
    print(f"❌ Không tìm thấy file: {migration_file}")
    print("   Hãy chắc chắn file migration đã được tạo.")
    exit(1)

print()
print("🔗 Kết nối vào Supabase...")
print(f"   Database: {CONN_STRING.split('@')[1].split('/')[0]}")

try:
    # Connect to database
    conn = psycopg2.connect(CONN_STRING)
    cursor = conn.cursor()
    print("✅ Kết nối thành công!")
    
    print()
    print("⚠️  CẢNH BÁO: Sắp chạy migration. Đây là những gì sẽ thay đổi:")
    print("-" * 80)
    print("1. Attendance: store_id → branch_id")
    print("2. Attendance: Thêm company_id và GPS columns")
    print("3. Tasks: Sửa RLS policies (profiles → users)")
    print("4. Storage: Sửa bucket policies (profiles → users)")
    print("5. Companies: Thêm các cột thiếu")
    print("6. Branches: Thêm manager_id và code")
    print("-" * 80)
    print()
    
    confirm = input("Bạn có chắc muốn tiếp tục? (yes/no): ")
    
    if confirm.lower() not in ['yes', 'y']:
        print("❌ Đã hủy migration.")
        exit(0)
    
    print()
    print("🔄 Đang chạy migration...")
    print()
    
    # Execute migration
    cursor.execute(migration_sql)
    conn.commit()
    
    print()
    print("=" * 80)
    print("✅ MIGRATION HOÀN THÀNH THÀNH CÔNG!")
    print("=" * 80)
    print()
    
    # Verify changes
    print("🔍 Kiểm tra kết quả...")
    print()
    
    # Check attendance columns
    cursor.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'attendance' 
        ORDER BY column_name
    """)
    att_columns = [row[0] for row in cursor.fetchall()]
    
    print("📊 Attendance columns sau khi migrate:")
    for col in att_columns:
        icon = "✅" if col in ['branch_id', 'company_id', 'check_in_latitude', 'check_in_longitude'] else "  "
        print(f"   {icon} {col}")
    
    print()
    
    # Check tasks policies
    cursor.execute("""
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'tasks'
        ORDER BY policyname
    """)
    task_policies = [row[0] for row in cursor.fetchall()]
    
    print(f"🔒 Tasks policies ({len(task_policies)}):")
    for policy in task_policies[:5]:  # Show first 5
        print(f"   ✓ {policy}")
    if len(task_policies) > 5:
        print(f"   ... và {len(task_policies) - 5} policies khác")
    
    print()
    print("=" * 80)
    print("📋 NEXT STEPS:")
    print("=" * 80)
    print("1. ✅ Test attendance check-in/check-out với GPS")
    print("2. ✅ Test task creation cho CEO/Manager")
    print("3. ✅ Test file upload (AI files)")
    print("4. ✅ Cập nhật frontend models theo báo cáo")
    print("5. ✅ Đọc file BAO-CAO-SUPABASE-THUC-TE.md để biết chi tiết")
    print()
    print("🎉 Migration thành công! Database đã được fix.")
    print()
    
except psycopg2.Error as e:
    print(f"❌ LỖI KHI CHẠY MIGRATION:")
    print(f"   {e}")
    print()
    print("💡 Gợi ý khắc phục:")
    print("   1. Kiểm tra connection string trong .env")
    print("   2. Kiểm tra quyền truy cập database")
    print("   3. Xem file migration có lỗi syntax không")
    conn.rollback()
    
except Exception as e:
    print(f"❌ LỖI KHÔNG XÁC ĐỊNH:")
    print(f"   {e}")
    
finally:
    if conn:
        cursor.close()
        conn.close()
        print("🔌 Đã đóng kết nối database.")

