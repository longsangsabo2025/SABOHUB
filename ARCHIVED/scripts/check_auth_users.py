#!/usr/bin/env python3
"""
Kiểm tra các user trong Supabase Auth (auth.users)
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("=== KIỂM TRA USERS TRONG SUPABASE AUTH ===\n")

try:
    # Lấy danh sách tất cả users trong auth.users
    users_response = supabase.auth.admin.list_users()
    
    if not users_response:
        print("❌ Không có user nào trong auth.users")
        print("\n💡 Bạn cần tạo user trên Supabase Dashboard:")
        print("   Authentication → Users → Add User")
        exit(0)
    
    print(f"📊 Tổng số users: {len(users_response)}\n")
    
    # Tìm CEO
    ceo_emails = ['longsangsabo1@gmail.com', 'longsang@sabohub.com']
    
    for user in users_response:
        email = user.email
        is_ceo = email in ceo_emails
        
        if is_ceo:
            print(f"👑 CEO FOUND:")
        else:
            print(f"👤 User:")
        
        print(f"   Email: {email}")
        print(f"   ID: {user.id}")
        print(f"   Confirmed: {user.email_confirmed_at is not None}")
        print(f"   Created: {user.created_at}")
        
        if hasattr(user, 'user_metadata') and user.user_metadata:
            print(f"   Metadata: {user.user_metadata}")
        
        print()
    
    # Kiểm tra trong bảng users
    print("\n=== KIỂM TRA BẢNG USERS (custom) ===\n")
    
    custom_users = supabase.table('users').select('*').eq('role', 'ceo').execute()
    
    if custom_users.data:
        for user in custom_users.data:
            print(f"👤 User in custom table:")
            print(f"   Email: {user.get('email')}")
            print(f"   User ID: {user.get('user_id')}")
            print(f"   Full Name: {user.get('full_name')}")
            print(f"   Role: {user.get('role')}")
            print()
    
    print("\n=== KẾT LUẬN ===\n")
    print("Để đăng nhập được, email phải tồn tại trong auth.users")
    print("Hiện tại các email CEO trong auth.users:")
    
    found_ceo = False
    for user in users_response:
        if user.email in ceo_emails:
            print(f"   ✅ {user.email}")
            found_ceo = True
    
    if not found_ceo:
        print("   ❌ KHÔNG CÓ")
        print("\n💡 Bạn cần:")
        print("   1. Tạo user trên Supabase Dashboard")
        print("   2. Hoặc dùng demo user: ceo1@sabohub.com / demo")

except Exception as e:
    print(f"❌ LỖI: {str(e)}")
