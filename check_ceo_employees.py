from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
supabase = create_client(url, key)

print("=" * 60)
print("🔍 KIỂM TRA CEO VÀ NHÂN VIÊN")
print("=" * 60)

# 1. Kiểm tra CEO
print("\n1️⃣ Thông tin CEO (longsangsabo1@gmail.com):")
ceo = supabase.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()
if ceo.data:
    ceo_data = ceo.data[0]
    print(f"   ✅ ID: {ceo_data['id']}")
    print(f"   ✅ Email: {ceo_data['email']}")
    print(f"   ✅ Company ID: {ceo_data.get('company_id', 'NULL')}")
    print(f"   ✅ Role: {ceo_data['role']}")
    
    company_id = ceo_data.get('company_id')
    
    if company_id:
        # 2. Kiểm tra công ty
        print(f"\n2️⃣ Thông tin công ty:")
        company = supabase.table('companies').select('*').eq('id', company_id).execute()
        if company.data:
            print(f"   ✅ Tên công ty: {company.data[0]['name']}")
            print(f"   ✅ ID: {company.data[0]['id']}")
        
        # 3. Kiểm tra nhân viên trong bảng employees
        print(f"\n3️⃣ Nhân viên trong bảng 'employees':")
        employees = supabase.table('employees').select('*').eq('company_id', company_id).execute()
        
        if employees.data:
            print(f"   ✅ Tìm thấy {len(employees.data)} nhân viên:")
            for emp in employees.data:
                print(f"      - {emp['full_name']} (@{emp['username']}) - Role: {emp['role']} - Active: {emp['is_active']}")
        else:
            print(f"   ❌ KHÔNG có nhân viên nào trong company_id = {company_id}")
            
        # 4. Kiểm tra nhân viên ACTIVE
        print(f"\n4️⃣ Nhân viên ACTIVE:")
        active_employees = supabase.table('employees').select('*').eq('company_id', company_id).eq('is_active', True).execute()
        
        if active_employees.data:
            print(f"   ✅ Tìm thấy {len(active_employees.data)} nhân viên active:")
            for emp in active_employees.data:
                print(f"      - {emp['full_name']} (@{emp['username']}) - Role: {emp['role']}")
        else:
            print(f"   ❌ KHÔNG có nhân viên ACTIVE nào")
            
    else:
        print("\n❌ CEO chưa có company_id!")
else:
    print("❌ Không tìm thấy CEO!")

print("\n" + "=" * 60)
