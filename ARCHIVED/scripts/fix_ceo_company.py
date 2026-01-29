import os
from supabase import create_client, Client
from dotenv import load_dotenv
import uuid

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_KEY")  # Cần service key để update
supabase: Client = create_client(url, key)

print("🔧 FIX: Tạo company và gán cho CEO\n")

# 1. Lấy user CEO
user_email = 'longsangsabo1@gmail.com'
print(f"1️⃣ Lấy thông tin CEO: {user_email}")
user_response = supabase.table('users').select('*').eq('email', user_email).execute()

if not user_response.data:
    print("❌ Không tìm thấy user!")
    exit(1)

user = user_response.data[0]
user_id = user['id']
print(f"✅ User ID: {user_id}")

# 2. Kiểm tra xem đã có company chưa
if user.get('company_id'):
    print(f"✅ User đã có company_id: {user['company_id']}")
    exit(0)

# 3. Tạo company mới
print("\n2️⃣ Tạo company mới...")
company_data = {
    'id': str(uuid.uuid4()),
    'name': 'Nhà hàng Sabo',
    'business_type': 'Restaurant',
    'owner_id': user_id,
    'created_at': 'now()'
}

try:
    company_response = supabase.table('companies').insert(company_data).execute()
    company_id = company_response.data[0]['id']
    print(f"✅ Đã tạo company: {company_id}")
    
    # 4. Update user với company_id
    print("\n3️⃣ Gán company_id cho CEO...")
    update_response = supabase.table('users').update({
        'company_id': company_id
    }).eq('id', user_id).execute()
    
    print(f"✅ Đã gán company_id cho CEO!")
    print(f"\n🎉 HOÀN TẤT!")
    print(f"   Company ID: {company_id}")
    print(f"   Company Name: Nhà hàng Sabo")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
