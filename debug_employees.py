import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_ANON_KEY")
supabase: Client = create_client(url, key)

print("🔍 KIỂM TRA DANH SÁCH NHÂN VIÊN\n")

# Lấy company_id của longsangsabo1@gmail.com
print("1️⃣ Lấy thông tin user longsangsabo1@gmail.com...")
try:
    user_response = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()
    
    if user_response.data:
        user = user_response.data[0]
        print(f"✅ User ID: {user['id']}")
        print(f"✅ Company ID: {user.get('company_id', 'NONE')}")
        company_id = user.get('company_id')
        
        if company_id:
            print(f"\n2️⃣ Lấy danh sách nhân viên trong company {company_id}...")
            
            # Query từ bảng users
            print("\n📋 Từ bảng USERS:")
            users_emp = supabase.table('users').select('*').eq('company_id', company_id).execute()
            print(f"   Số lượng: {len(users_emp.data)}")
            for emp in users_emp.data:
                print(f"   - {emp.get('full_name', emp.get('name', 'N/A'))} ({emp.get('role', 'N/A')})")
            
            # Query từ bảng employees
            print("\n📋 Từ bảng EMPLOYEES:")
            try:
                emp_response = supabase.table('employees').select('*').eq('company_id', company_id).eq('is_active', True).execute()
                print(f"   Số lượng: {len(emp_response.data)}")
                for emp in emp_response.data:
                    print(f"   - {emp.get('full_name', 'N/A')} ({emp.get('role', 'N/A')})")
            except Exception as e:
                print(f"   ❌ Lỗi: {e}")
            
            print(f"\n✅ TỔNG SỐ NHÂN VIÊN: {len(users_emp.data) + (len(emp_response.data) if 'emp_response' in locals() else 0)}")
        else:
            print("❌ User không có company_id!")
    else:
        print("❌ Không tìm thấy user!")
        
except Exception as e:
    print(f"❌ Lỗi: {e}")
