"""
Test tạo task từ backend để kiểm tra lỗi
"""
import os
from supabase import create_client, Client
from datetime import datetime, timedelta
import json

# Supabase credentials - từ .env
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print("🔍 Bắt đầu test tạo task từ backend...")
print("=" * 60)

# Bước 1: Lấy thông tin user hiện tại
print("\n1️⃣ Lấy thông tin user...")
try:
    # Đăng nhập với email test (hoặc dùng user hiện có)
    auth_response = supabase.auth.get_user()
    if auth_response and auth_response.user:
        user = auth_response.user
        print(f"✅ User ID: {user.id}")
        print(f"✅ Email: {user.email}")
    else:
        print("❌ Chưa đăng nhập. Cần đăng nhập trước.")
        print("Thử lấy user từ database...")
        users = supabase.table('users').select('*').limit(1).execute()
        if users.data and len(users.data) > 0:
            user_data = users.data[0]
            user_id = user_data['id']
            user_email = user_data['email']
            user_name = user_data.get('name') or user_email
            print(f"✅ Dùng user: {user_id} - {user_email}")
        else:
            print("❌ Không tìm thấy user nào trong database")
            exit(1)
except Exception as e:
    print(f"❌ Lỗi khi lấy user: {e}")
    print("Thử lấy user từ database...")
    users = supabase.table('users').select('*').limit(1).execute()
    if users.data and len(users.data) > 0:
        user_data = users.data[0]
        user_id = user_data['id']
        user_email = user_data['email']
        user_name = user_data.get('name') or user_email
        print(f"✅ Dùng user: {user_id} - {user_email}")
    else:
        print("❌ Không tìm thấy user nào trong database")
        exit(1)

# Bước 2: Lấy company để test
print("\n2️⃣ Lấy company...")
try:
    companies = supabase.table('companies').select('*').limit(1).execute()
    if companies.data and len(companies.data) > 0:
        company = companies.data[0]
        company_id = company['id']
        print(f"✅ Company ID: {company_id}")
        print(f"✅ Company Name: {company.get('name', 'N/A')}")
    else:
        print("⚠️ Không tìm thấy company nào. Tạo company mới...")
        new_company = supabase.table('companies').insert({
            'name': 'Test Company',
            'email': user_email,
            'created_by': user_id
        }).execute()
        company_id = new_company.data[0]['id']
        print(f"✅ Đã tạo company mới: {company_id}")
except Exception as e:
    print(f"❌ Lỗi khi lấy company: {e}")
    exit(1)

# Bước 3: Kiểm tra cấu trúc bảng tasks
print("\n3️⃣ Kiểm tra cấu trúc bảng tasks...")
try:
    # Thử query để xem cấu trúc
    test_query = supabase.table('tasks').select('*').limit(1).execute()
    print(f"✅ Bảng tasks tồn tại")
    if test_query.data:
        print(f"✅ Có {len(test_query.data)} task mẫu")
        print(f"   Columns: {list(test_query.data[0].keys())}")
except Exception as e:
    print(f"❌ Lỗi khi kiểm tra bảng tasks: {e}")

# Bước 4: Tạo task với branch_id = NULL
print("\n4️⃣ Test tạo task với branch_id = NULL...")
try:
    due_date = (datetime.now() + timedelta(days=7)).isoformat()
    
    task_data = {
        'branch_id': None,  # NULL - không dùng chi nhánh
        'company_id': company_id,
        'title': 'Test Task - Backend',
        'description': 'Task test từ backend script',
        'category': 'other',
        'priority': 'medium',
        'status': 'pending',
        'assigned_to': None,  # Không assign cho ai
        'assigned_to_name': None,
        'due_date': due_date,
        'created_by': user_id,
        'created_by_name': user_name,
        'notes': 'Test notes',
    }
    
    print(f"📤 Gửi data:")
    print(json.dumps(task_data, indent=2, default=str))
    
    response = supabase.table('tasks').insert(task_data).execute()
    
    if response.data:
        print(f"✅ TẠO TASK THÀNH CÔNG!")
        created_task = response.data[0]
        print(f"   Task ID: {created_task['id']}")
        print(f"   Title: {created_task['title']}")
        print(f"   Branch ID: {created_task.get('branch_id', 'NULL')}")
        print(f"   Company ID: {created_task.get('company_id', 'NULL')}")
        print(f"   Status: {created_task['status']}")
    else:
        print(f"⚠️ Không có data trả về nhưng không có lỗi")
        
except Exception as e:
    print(f"❌ LỖI KHI TẠO TASK:")
    print(f"   {type(e).__name__}: {str(e)}")
    
    # Phân tích lỗi
    error_str = str(e).lower()
    if 'uuid' in error_str:
        print("\n🔍 Phát hiện lỗi UUID:")
        print("   - Có thể một trong các ID không đúng định dạng UUID")
        print("   - Kiểm tra lại user_id, company_id")
    if 'foreign key' in error_str:
        print("\n🔍 Phát hiện lỗi Foreign Key:")
        print("   - Company ID hoặc User ID không tồn tại trong DB")
    if 'not null' in error_str or 'null value' in error_str:
        print("\n🔍 Phát hiện lỗi NOT NULL:")
        print("   - Có column bắt buộc nhưng đang truyền NULL")

# Bước 5: Test tạo task với branch_id = "" (empty string)
print("\n5️⃣ Test tạo task với branch_id = '' (empty string)...")
try:
    task_data_empty = {
        'branch_id': '',  # Empty string
        'company_id': company_id,
        'title': 'Test Task - Empty Branch',
        'description': 'Task test với branch_id empty string',
        'category': 'other',
        'priority': 'medium',
        'status': 'pending',
        'due_date': due_date,
        'created_by': user_id,
        'created_by_name': user_name,
    }
    
    print(f"📤 Gửi data với branch_id = ''")
    response = supabase.table('tasks').insert(task_data_empty).execute()
    
    if response.data:
        print(f"✅ TẠO TASK THÀNH CÔNG (với empty string)!")
        print(f"   Task ID: {response.data[0]['id']}")
    else:
        print(f"⚠️ Không có data trả về")
        
except Exception as e:
    print(f"❌ LỖI (expected - empty string không hợp lệ cho UUID):")
    print(f"   {type(e).__name__}: {str(e)}")
    print("   ✅ Đây là lỗi mong đợi - empty string không thể convert sang UUID")

print("\n" + "=" * 60)
print("🏁 KẾT THÚC TEST")
