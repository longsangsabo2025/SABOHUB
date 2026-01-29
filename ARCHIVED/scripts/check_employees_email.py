#!/usr/bin/env python3
"""
Check employees table structure - có email để tạo auth không?
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('🔍 KIỂM TRA EMPLOYEES TABLE - CÓ EMAIL KHÔNG?')
print('=' * 80)
print()

# Check all columns
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'employees' AND table_schema = 'public'
    ORDER BY ordinal_position
""")

print('📋 Tất cả columns trong EMPLOYEES table:')
print()

cols = cursor.fetchall()
has_email = False
has_phone = False
has_user_id = False

for col, dtype, nullable in cols:
    icon = '✅' if col in ['email', 'phone', 'user_id', 'name'] else '  '
    print(f'{icon} {col:<25} {dtype:<20} nullable={nullable}')
    if col == 'email':
        has_email = True
    if col == 'phone':
        has_phone = True
    if col == 'user_id':
        has_user_id = True

print()
print('=' * 80)
print('📊 PHÂN TÍCH:')
print('=' * 80)
print()
print(f'email column: {"✅ CÓ" if has_email else "❌ KHÔNG"}')
print(f'phone column: {"✅ CÓ" if has_phone else "❌ KHÔNG"}')
print(f'user_id column: {"✅ CÓ" if has_user_id else "❌ KHÔNG"}')
print()

if has_email:
    # Check how many have email
    cursor.execute('SELECT COUNT(*), COUNT(email) FROM employees')
    total, with_email = cursor.fetchone()
    print(f'📧 {with_email}/{total} employees có email')
    print()
    
    # Show samples
    cursor.execute('SELECT name, email, role FROM employees LIMIT 5')
    samples = cursor.fetchall()
    if samples:
        print('Samples:')
        for name, email, role in samples:
            email_str = email if email else '(no email)'
            print(f'   {name:<20} {email_str:<30} {role}')
else:
    print('⚠️  Employees table KHÔNG có email column!')
    print()
    print('📋 Điều này có nghĩa:')
    print('   1. Staff KHÔNG thể có auth account (cần email để đăng ký)')
    print('   2. Staff KHÔNG thể login vào app')
    print('   3. Chỉ CEO/Manager (có trong users table) mới login được')
    print()
    print('💡 KIẾN TRÚC HIỆN TẠI:')
    print('   ┌─ USERS (auth.users) - Login được')
    print('   │  └─ CEO, Manager')
    print('   │')
    print('   └─ EMPLOYEES - KHÔNG login')
    print('      └─ Staff, Team Lead')
    print()
    print('🎯 Attendance workflow:')
    print('   - Manager login vào app')
    print('   - Manager chấm công CHO staff (thay mặt họ)')
    print('   - Staff không tự check-in')

print()
print('=' * 80)
print('💡 GIẢI PHÁP NẾU MUỐN STAFF LOGIN:')
print('=' * 80)
print()
print('Option 1: Add email to employees')
print('   ALTER TABLE employees ADD COLUMN email TEXT UNIQUE;')
print('   → Staff có thể được tạo auth account')
print()
print('Option 2: Keep current (Manager check-in for staff)')
print('   → Đơn giản hơn, không cần staff login')
print('   → Attendance dùng user_id của Manager')
print()

cursor.close()
conn.close()
