import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔍 KIỂM TRA SABO BILLIARDS (FIX)\n")

try:
    company_id = 'feef10d3-899d-4554-8107-b2256918213a'  # SABO Billiards ID
    
    print("✅ Company: SABO Billiards")
    print(f"   ID: {company_id}\n")
    
    # 1. Tìm nhân viên trong bảng 'users'
    print("1️⃣ Nhân viên trong bảng 'users':")
    users_result = supabase.table('users').select('*').eq('company_id', company_id).execute()
    
    print(f"   Tìm thấy {len(users_result.data)} nhân viên:")
    for user in users_result.data:
        print(f"   - Email: {user['email']}")
        print(f"     Role: {user['role']}")
        print(f"     ID: {user['id']}")
        print()
    
    # 2. Tìm nhân viên trong bảng 'employees' (tất cả columns)
    print("2️⃣ Nhân viên trong bảng 'employees':")
    employees_result = supabase.table('employees').select('*').eq('company_id', company_id).execute()
    
    print(f"   Tìm thấy {len(employees_result.data)} nhân viên:")
    if employees_result.data:
        # In ra tất cả columns của record đầu tiên
        print(f"   Columns available: {list(employees_result.data[0].keys())}")
        for emp in employees_result.data:
            print(f"   - {emp}")
    
    # 3. Tổng kết
    print(f"\n3️⃣ Tổng kết:")
    print(f"   - Số user: {len(users_result.data)}")
    print(f"   - Số employee: {len(employees_result.data)}")
    
    if len(users_result.data) == 0 and len(employees_result.data) == 0:
        print(f"\n⚠️  KHÔNG CÓ NHÂN VIÊN NÀO CHO COMPANY NÀY!")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
