import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔍 KIỂM TRA SABO BILLIARDS\n")

try:
    # 1. Tìm company SABO Billiards
    print("1️⃣ Tìm company 'SABO Billiards'...")
    company_result = supabase.table('companies').select('*').ilike('name', '%SABO%Billiards%').execute()
    
    if not company_result.data:
        print("❌ Không tìm thấy company 'SABO Billiards'")
        # Thử tìm tất cả companies
        print("\n📋 Danh sách tất cả companies:")
        all_companies = supabase.table('companies').select('id, name').execute()
        for comp in all_companies.data:
            print(f"   - {comp['name']} (ID: {comp['id']})")
        exit(1)
    
    company = company_result.data[0]
    company_id = company['id']
    print(f"✅ Tìm thấy company: {company['name']}")
    print(f"   ID: {company_id}")
    print(f"   Business Type: {company.get('business_type', 'N/A')}")
    print(f"   Address: {company.get('address', 'N/A')}")
    
    # 2. Tìm nhân viên thuộc company này trong bảng 'users'
    print(f"\n2️⃣ Tìm nhân viên trong bảng 'users'...")
    users_result = supabase.table('users').select('id, email, role, company_id').eq('company_id', company_id).execute()
    
    print(f"   Tìm thấy {len(users_result.data)} nhân viên trong bảng 'users':")
    for user in users_result.data:
        print(f"   - {user['email']} (Role: {user['role']})")
    
    # 3. Tìm nhân viên trong bảng 'employees'
    print(f"\n3️⃣ Tìm nhân viên trong bảng 'employees'...")
    employees_result = supabase.table('employees').select('id, name, email, company_id').eq('company_id', company_id).execute()
    
    print(f"   Tìm thấy {len(employees_result.data)} nhân viên trong bảng 'employees':")
    for emp in employees_result.data:
        print(f"   - {emp['name']} ({emp['email']})")
    
    # 4. Kiểm tra RLS policies
    print(f"\n4️⃣ Tổng kết:")
    print(f"   - Company ID: {company_id}")
    print(f"   - Số nhân viên trong 'users': {len(users_result.data)}")
    print(f"   - Số nhân viên trong 'employees': {len(employees_result.data)}")
    
    if len(users_result.data) == 0 and len(employees_result.data) == 0:
        print(f"\n⚠️  KHÔNG CÓ NHÂN VIÊN NÀO!")
        print(f"   Cần tạo nhân viên mẫu cho company này.")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
