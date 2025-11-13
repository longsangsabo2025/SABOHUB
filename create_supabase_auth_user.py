#!/usr/bin/env python3
"""
Script để tạo user trong Supabase Auth (auth.users)
cho CEO longsang@sabohub.com
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase connection
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Thiếu SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY trong .env")
    exit(1)

# Initialize Supabase client with service role key (có quyền admin)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("=== TẠO USER TRONG SUPABASE AUTH ===\n")

# Thông tin user cần tạo
email = "longsang@sabohub.com"
password = "Acookingoil123@"

print(f"📧 Email: {email}")
print(f"🔑 Password: {password}")
print()

try:
    # Sử dụng admin API để tạo user
    # Service role key có quyền tạo user mà không cần email confirmation
    response = supabase.auth.admin.create_user({
        "email": email,
        "password": password,
        "email_confirm": True,  # Auto-confirm email
        "user_metadata": {
            "full_name": "Võ Long Sang",
            "role": "ceo"
        }
    })
    
    print("✅ ĐÃ TẠO USER THÀNH CÔNG!")
    print(f"User ID: {response.user.id}")
    print(f"Email: {response.user.email}")
    print(f"Email confirmed: {response.user.email_confirmed_at is not None}")
    print()
    
    # Cập nhật user_id trong bảng users để link với auth.users
    user_id = response.user.id
    
    # Kiểm tra xem đã có record trong bảng users chưa
    existing = supabase.table('users').select('*').eq('email', email).execute()
    
    if existing.data:
        # Cập nhật user_id
        update_result = supabase.table('users').update({
            'user_id': user_id
        }).eq('email', email).execute()
        
        print("✅ Đã cập nhật user_id trong bảng users")
        print(f"User ID: {user_id}")
    else:
        # Tạo mới record trong bảng users
        insert_result = supabase.table('users').insert({
            'user_id': user_id,
            'email': email,
            'full_name': 'Võ Long Sang',
            'role': 'ceo'
        }).execute()
        
        print("✅ Đã tạo mới record trong bảng users")
    
    print()
    print("🎉 HOÀN TẤT!")
    print(f"Bạn có thể đăng nhập với:")
    print(f"   Email: {email}")
    print(f"   Password: {password}")
    
except Exception as e:
    print(f"❌ LỖI: {str(e)}")
    print()
    
    # Kiểm tra xem user đã tồn tại chưa
    try:
        # Thử lấy user by email
        users = supabase.auth.admin.list_users()
        existing_user = None
        
        for user in users:
            if user.email == email:
                existing_user = user
                break
        
        if existing_user:
            print("ℹ️ User đã tồn tại trong auth.users:")
            print(f"   User ID: {existing_user.id}")
            print(f"   Email: {existing_user.email}")
            print(f"   Created: {existing_user.created_at}")
            print()
            print("💡 Bạn có thể:")
            print("   1. Đăng nhập với mật khẩu hiện tại")
            print("   2. Hoặc reset mật khẩu trên Supabase Dashboard")
        else:
            print("⚠️ Lỗi không xác định khi tạo user")
            
    except Exception as check_error:
        print(f"❌ Không thể kiểm tra user: {str(check_error)}")
