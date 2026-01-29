import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🗑️  XÓA USER KHỎI BẢNG USERS\n")

try:
    email = 'ngocdiem1112@gmail.com'
    
    # 1. Kiểm tra user trước
    print(f"1️⃣ Tìm user {email}...")
    user_result = supabase.table('users').select('*').eq('email', email).execute()
    
    if not user_result.data:
        print(f"❌ Không tìm thấy user {email}")
        exit(1)
    
    user = user_result.data[0]
    print(f"✅ Tìm thấy:")
    print(f"   Email: {user['email']}")
    print(f"   Role: {user['role']}")
    print(f"   Company ID: {user.get('company_id', 'N/A')}")
    
    # 2. Xóa user
    print(f"\n2️⃣ Xóa user khỏi bảng 'users'...")
    delete_result = supabase.table('users').delete().eq('email', email).execute()
    
    if delete_result.data:
        print(f"✅ Đã xóa user {email} thành công!")
    else:
        print(f"⚠️  Không thể xóa user")
    
    print(f"\n🎉 HOÀN TẤT!")
    print(f"Từ giờ chỉ query từ bảng 'employees'")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
