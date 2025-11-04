"""
Test script để kiểm tra tích hợp chấm công với dữ liệu thực

Script này sẽ:
1. Kiểm tra schema của bảng attendance
2. Kiểm tra bảng users có cột company_id
3. Tạo dữ liệu test nếu chưa có
4. Query dữ liệu như trong app
"""

import os
from datetime import datetime, timedelta
from supabase import create_client, Client

# Khởi tạo Supabase client
url: str = os.environ.get("SUPABASE_URL", "")
key: str = os.environ.get("SUPABASE_ANON_KEY", "")

if not url or not key:
    print("❌ Vui lòng set SUPABASE_URL và SUPABASE_ANON_KEY trong environment variables")
    exit(1)

supabase: Client = create_client(url, key)

print("=" * 60)
print("🔍 KIỂM TRA TÍCH HỢP CHẤM CÔNG")
print("=" * 60)

# 1. Kiểm tra bảng attendance
print("\n1️⃣  Kiểm tra cấu trúc bảng attendance...")
try:
    # Lấy 1 record để xem cấu trúc
    result = supabase.table('attendance').select('*').limit(1).execute()
    print("   ✅ Bảng attendance tồn tại")
    if result.data:
        print(f"   📊 Có {len(result.data)} bản ghi (sample)")
        print(f"   📋 Columns: {', '.join(result.data[0].keys())}")
except Exception as e:
    print(f"   ❌ Lỗi: {e}")

# 2. Kiểm tra bảng users có company_id
print("\n2️⃣  Kiểm tra bảng users có cột company_id...")
try:
    result = supabase.table('users').select('id, name, company_id').limit(1).execute()
    print("   ✅ Bảng users có cột company_id")
    if result.data:
        print(f"   👤 Sample user: {result.data[0]}")
except Exception as e:
    print(f"   ❌ Lỗi: {e}")

# 3. Đếm số lượng attendance records
print("\n3️⃣  Đếm số lượng bản ghi chấm công...")
try:
    result = supabase.table('attendance').select('id', count='exact').execute()
    total = result.count
    print(f"   📊 Tổng số bản ghi: {total}")
    
    if total == 0:
        print("   ⚠️  Chưa có dữ liệu chấm công")
        print("   💡 Hãy tạo dữ liệu test bằng cách thêm vào Supabase Dashboard")
except Exception as e:
    print(f"   ❌ Lỗi: {e}")

# 4. Kiểm tra query như trong app (JOIN với users và stores)
print("\n4️⃣  Test query như trong Flutter app...")
try:
    today = datetime.now()
    start_of_day = datetime(today.year, today.month, today.day)
    end_of_day = start_of_day + timedelta(days=1)
    
    result = supabase.table('attendance').select('''
        id,
        user_id,
        store_id,
        check_in,
        check_out,
        total_hours,
        is_late,
        is_early_leave,
        notes,
        users!inner(
            id,
            name,
            email,
            company_id
        ),
        stores(
            id,
            name
        )
    ''').gte('check_in', start_of_day.isoformat()).lt('check_in', end_of_day.isoformat()).limit(5).execute()
    
    print(f"   ✅ Query thành công")
    print(f"   📊 Số bản ghi hôm nay: {len(result.data)}")
    
    if result.data:
        print("\n   📋 Sample data:")
        for record in result.data[:3]:  # Hiển thị 3 bản ghi đầu
            user_name = record.get('users', {}).get('name', 'N/A')
            check_in = record.get('check_in', 'N/A')
            check_out = record.get('check_out', 'N/A')
            is_late = record.get('is_late', False)
            print(f"      • {user_name}")
            print(f"        Check-in: {check_in}")
            print(f"        Check-out: {check_out}")
            print(f"        Late: {'Yes' if is_late else 'No'}")
    else:
        print("   ⚠️  Không có dữ liệu chấm công hôm nay")
        
except Exception as e:
    print(f"   ❌ Lỗi: {e}")
    print(f"   💡 Error details: {str(e)}")

# 5. Kiểm tra companies
print("\n5️⃣  Kiểm tra danh sách công ty...")
try:
    result = supabase.table('companies').select('id, name').limit(5).execute()
    print(f"   ✅ Có {len(result.data)} công ty")
    
    if result.data:
        print("\n   🏢 Danh sách công ty:")
        for company in result.data:
            company_id = company.get('id')
            company_name = company.get('name', 'N/A')
            print(f"      • {company_name} (ID: {company_id})")
            
            # Đếm số nhân viên trong công ty
            try:
                users_result = supabase.table('users').select('id', count='exact').eq('company_id', company_id).execute()
                user_count = users_result.count
                print(f"        👥 Số nhân viên: {user_count}")
                
                # Đếm số attendance hôm nay
                today = datetime.now()
                start_of_day = datetime(today.year, today.month, today.day)
                end_of_day = start_of_day + timedelta(days=1)
                
                attendance_result = supabase.table('attendance').select('''
                    id,
                    users!inner(company_id)
                ''', count='exact').eq('users.company_id', company_id).gte('check_in', start_of_day.isoformat()).lt('check_in', end_of_day.isoformat()).execute()
                
                attendance_count = attendance_result.count
                print(f"        ✅ Chấm công hôm nay: {attendance_count}")
            except Exception as e:
                print(f"        ⚠️  Không thể đếm: {str(e)}")
                
except Exception as e:
    print(f"   ❌ Lỗi: {e}")

# 6. Tổng kết
print("\n" + "=" * 60)
print("📊 TỔNG KẾT")
print("=" * 60)
print("""
✅ Các bảng cần thiết:
   - attendance (chấm công)
   - users (nhân viên, có company_id)
   - stores (chi nhánh)
   - companies (công ty)

🔗 Quan hệ:
   attendance.user_id → users.id
   attendance.store_id → stores.id
   users.company_id → companies.id

📱 Trong Flutter app:
   1. Mở trang chi tiết công ty
   2. Click tab "Chấm công"
   3. Dữ liệu sẽ được load từ Supabase
   4. Có thể filter theo ngày và trạng thái

💡 Nếu không có dữ liệu:
   - Thêm bản ghi vào bảng attendance qua Supabase Dashboard
   - Hoặc dùng tính năng check-in/check-out trong app
""")

print("\n✨ Kiểm tra hoàn tất!")
