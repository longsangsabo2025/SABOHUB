import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔍 TÌM COMPANY VÀ GÁN CHO CEO\n")

try:
    # 1. Tìm company "Nhà hàng Sabo"
    print("1️⃣ Tìm company 'Nhà hàng Sabo'...")
    company_result = supabase.table('companies').select('id, name').eq('name', 'Nhà hàng Sabo').execute()
    
    if not company_result.data:
        print("❌ Không tìm thấy company 'Nhà hàng Sabo'")
        exit(1)
    
    company = company_result.data[0]
    company_id = company['id']
    print(f"✅ Tìm thấy company: {company['name']}")
    print(f"   ID: {company_id}")
    
    # 2. Gán company_id cho CEO
    print(f"\n2️⃣ Gán company cho CEO longsangsabo1@gmail.com...")
    update_result = supabase.table('users').update({
        'company_id': company_id
    }).eq('email', 'longsangsabo1@gmail.com').execute()
    
    if update_result.data:
        print(f"✅ Đã gán company_id cho CEO!")
        print(f"\n3️⃣ Kiểm tra kết quả...")
        user_result = supabase.table('users').select('id, email, company_id, role').eq('email', 'longsangsabo1@gmail.com').execute()
        user = user_result.data[0]
        print(f"   Email: {user['email']}")
        print(f"   Role: {user['role']}")
        print(f"   Company ID: {user['company_id']}")
        print(f"\n🎉 HOÀN TẤT! CEO đã có company_id, có thể xem danh sách nhân viên.")
    else:
        print(f"⚠️ Không tìm thấy user với email longsangsabo1@gmail.com")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
