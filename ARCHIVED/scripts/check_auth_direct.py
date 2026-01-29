#!/usr/bin/env python3
"""
Kiểm tra auth.users bằng SQL trực tiếp
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

# Connection string từ .env
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

if not conn_string:
    print("❌ Thiếu SUPABASE_CONNECTION_STRING")
    exit(1)

print("=== KIỂM TRA AUTH.USERS ===\n")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Query auth.users
    cur.execute("""
        SELECT 
            id,
            email,
            email_confirmed_at IS NOT NULL as confirmed,
            created_at,
            raw_user_meta_data
        FROM auth.users
        WHERE email LIKE '%longsang%' OR email LIKE '%sabohub%'
        ORDER BY created_at DESC
    """)
    
    users = cur.fetchall()
    
    if not users:
        print("❌ KHÔNG TÌM THẤY USER NÀO với email chứa 'longsang' hoặc 'sabohub'")
        print("\n=== TẤT CẢ USERS TRONG AUTH.USERS ===\n")
        
        cur.execute("""
            SELECT id, email, email_confirmed_at IS NOT NULL as confirmed
            FROM auth.users
            ORDER BY created_at DESC
            LIMIT 10
        """)
        
        all_users = cur.fetchall()
        
        if all_users:
            for user in all_users:
                print(f"📧 {user[1]} (ID: {user[0][:8]}..., Confirmed: {user[2]})")
        else:
            print("❌ KHÔNG CÓ USER NÀO trong auth.users")
            print("\n💡 Bạn cần tạo user trên Supabase Dashboard:")
            print("   Authentication → Users → Add User")
    else:
        print(f"✅ Tìm thấy {len(users)} user(s):\n")
        
        for user in users:
            user_id, email, confirmed, created, metadata = user
            print(f"👤 Email: {email}")
            print(f"   ID: {user_id}")
            print(f"   Confirmed: {confirmed}")
            print(f"   Created: {created}")
            if metadata:
                print(f"   Metadata: {metadata}")
            print()
    
    # Kiểm tra bảng users (custom)
    print("\n=== BẢNG USERS (CUSTOM) ===\n")
    
    cur.execute("""
        SELECT user_id, email, full_name, role
        FROM users
        WHERE role = 'ceo'
    """)
    
    custom_users = cur.fetchall()
    
    if custom_users:
        for user in custom_users:
            user_id, email, name, role = user
            print(f"👑 CEO: {name}")
            print(f"   Email: {email}")
            print(f"   User ID: {user_id}")
            print()
    
    print("\n=== KẾT LUẬN ===\n")
    
    if users:
        print("✅ Để đăng nhập, dùng email:")
        for user in users:
            print(f"   📧 {user[1]}")
            print(f"      (Cần biết mật khẩu đã đặt khi tạo user này)")
    else:
        print("❌ Không có user CEO trong auth.users")
        print("\n💡 HAI LỰA CHỌN:")
        print("   1. Tạo user mới trên Supabase Dashboard")
        print("      → Authentication → Users → Add User")
        print("      → Email: longsang@sabohub.com")
        print("      → Password: Acookingoil123@")
        print()
        print("   2. Hoặc dùng demo user:")
        print("      → Email: ceo1@sabohub.com")
        print("      → Password: demo")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ LỖI: {str(e)}")
