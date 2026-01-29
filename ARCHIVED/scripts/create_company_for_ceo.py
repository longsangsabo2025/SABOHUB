import os
from supabase import create_client, Client
from dotenv import load_dotenv
import uuid
from datetime import datetime

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")  # Dùng SERVICE_ROLE_KEY để có quyền ghi
supabase: Client = create_client(url, key)

print("🏢 TẠO COMPANY MỚI CHO CEO\n")

# Dữ liệu company mới
company_id = str(uuid.uuid4())
company_data = {
    'id': company_id,
    'name': 'Nhà hàng Sabo',
    'business_type': 'RESTAURANT',
    'address': '123 Nguyễn Huệ, Quận 1, TP.HCM',
    'phone': '0901234567',
    'created_at': datetime.now().isoformat()
}

try:
    # 1. Tạo company
    print(f"1️⃣ Tạo company mới...")
    result = supabase.table('companies').insert(company_data).execute()
    print(f"✅ Đã tạo company: {company_data['name']}")
    print(f"   ID: {company_id}")
    
    # 2. Update user với company_id
    print(f"\n2️⃣ Gán company cho CEO longsangsabo1@gmail.com...")
    update_result = supabase.table('users').update({
        'company_id': company_id
    }).eq('email', 'longsangsabo1@gmail.com').execute()
    
    if update_result.data:
        print(f"✅ Đã gán company_id cho CEO!")
    else:
        print(f"⚠️  Không tìm thấy user với email longsangsabo1@gmail.com")
    
    print(f"\n🎉 HOÀN TẤT!")
    print(f"CEO có thể xem danh sách nhân viên của công ty này.")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
