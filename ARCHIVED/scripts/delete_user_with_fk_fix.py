import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🗑️  XÓA USER VÀ FIX FOREIGN KEYS\n")

try:
    email = 'ngocdiem1112@gmail.com'
    
    # 1. Tìm user
    print(f"1️⃣ Tìm user {email}...")
    user_result = supabase.table('users').select('*').eq('email', email).execute()
    
    if not user_result.data:
        print(f"❌ Không tìm thấy user {email}")
        exit(1)
    
    user = user_result.data[0]
    user_id = user['id']
    print(f"✅ Tìm thấy user ID: {user_id}")
    
    # 2. Tìm business_documents liên quan
    print(f"\n2️⃣ Kiểm tra business_documents...")
    docs_result = supabase.table('business_documents').select('id').eq('uploaded_by', user_id).execute()
    print(f"   Tìm thấy {len(docs_result.data)} documents")
    
    if docs_result.data:
        # Tìm CEO để gán lại documents
        ceo_result = supabase.table('users').select('id').eq('email', 'longsangsabo1@gmail.com').execute()
        if ceo_result.data:
            ceo_id = ceo_result.data[0]['id']
            print(f"   Đang chuyển documents sang CEO {ceo_id}...")
            for doc in docs_result.data:
                supabase.table('business_documents').update({'uploaded_by': ceo_id}).eq('id', doc['id']).execute()
            print(f"   ✅ Đã chuyển {len(docs_result.data)} documents sang CEO")
        else:
            print(f"   ⚠️  Không tìm thấy CEO, không thể xóa user")
            exit(1)
    
    # 3. Kiểm tra các foreign keys khác
    print(f"\n3️⃣ Kiểm tra các foreign keys khác...")
    
    # Check employees table (created_by_ceo_id)
    employees_result = supabase.table('employees').select('id').eq('created_by_ceo_id', user_id).execute()
    if employees_result.data:
        print(f"   - employees.created_by_ceo_id: {len(employees_result.data)} records")
        for emp in employees_result.data:
            supabase.table('employees').update({'created_by_ceo_id': None}).eq('id', emp['id']).execute()
        print(f"   ✅ Đã update employees")
    
    # Check other tables...
    # Có thể có nhiều bảng khác, tôi sẽ thử xóa và xem lỗi gì
    
    # 4. Xóa user
    print(f"\n4️⃣ Xóa user...")
    delete_result = supabase.table('users').delete().eq('email', email).execute()
    
    if delete_result.data:
        print(f"✅ Đã xóa user {email}!")
    else:
        print(f"⚠️  Không thể xóa")
    
    print(f"\n🎉 HOÀN TẤT! Chỉ dùng bảng 'employees' từ giờ.")
    
except Exception as e:
    print(f"❌ Lỗi: {e}")
