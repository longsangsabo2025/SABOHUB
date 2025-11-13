#!/usr/bin/env python3
"""
Kiểm tra relationship giữa USERS và EMPLOYEES
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('🔍 KIỂM TRA RELATIONSHIP: USERS vs EMPLOYEES')
print('=' * 80)
print()

# 1. Check users table
print('1️⃣ USERS TABLE (CEO/Manager - login via Auth):')
cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'users' AND table_schema = 'public'
    AND column_name IN ('id', 'email', 'role', 'company_id', 'branch_id')
    ORDER BY ordinal_position
""")
print('   Key columns:')
for row in cursor.fetchall():
    print(f'      ✓ {row[0]:<20} ({row[1]})')

cursor.execute('SELECT COUNT(*), COUNT(DISTINCT role) FROM users')
count, roles = cursor.fetchone()
print(f'   Records: {count} users')
print(f'   Roles: {roles} different roles')
print()

# 2. Check employees table
print('2️⃣ EMPLOYEES TABLE (Staff created by CEO):')
cursor.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'employees' AND table_schema = 'public'
    AND column_name IN ('id', 'user_id', 'name', 'role', 'company_id', 'branch_id')
    ORDER BY ordinal_position
""")
print('   Key columns:')
for row in cursor.fetchall():
    print(f'      ✓ {row[0]:<20} ({row[1]})')

cursor.execute('SELECT COUNT(*) FROM employees')
print(f'   Records: {cursor.fetchone()[0]} employees')
print()

# 3. Check relationship
print('3️⃣ RELATIONSHIP:')
cursor.execute("""
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'employees' AND column_name = 'user_id'
    )
""")
has_user_id = cursor.fetchone()[0]

if has_user_id:
    print('   ✅ employees.user_id exists')
    
    # Check if it's nullable
    cursor.execute("""
        SELECT is_nullable FROM information_schema.columns 
        WHERE table_name = 'employees' AND column_name = 'user_id'
    """)
    nullable = cursor.fetchone()[0]
    print(f'   ✅ employees.user_id nullable: {nullable}')
    
    # Check how many employees have user_id
    cursor.execute('SELECT COUNT(*), COUNT(user_id) FROM employees')
    total, with_user = cursor.fetchone()
    print(f'   📊 {with_user}/{total} employees have user_id')
else:
    print('   ❌ employees.user_id NOT exists')

print()

# 4. Check attendance usage
print('4️⃣ ATTENDANCE TABLE uses:')
cursor.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'attendance' 
    AND column_name IN ('user_id', 'employee_id')
""")
att_cols = [row[0] for row in cursor.fetchall()]
print(f'   user_id: {"✅ YES" if "user_id" in att_cols else "❌ NO"}')
print(f'   employee_id: {"✅ YES" if "employee_id" in att_cols else "❌ NO"}')

# Get sample attendance
cursor.execute('SELECT user_id, employee_name FROM attendance LIMIT 3')
samples = cursor.fetchall()
if samples:
    print('   Sample records:')
    for user_id, name in samples:
        print(f'      user_id={user_id[:8]}... name={name}')

print()
print('=' * 80)
print('📋 KIẾN TRÚC HIỆN TẠI:')
print('=' * 80)
print()
print('┌─ USERS (auth.users)')
print('│  ├─ CEO creates company')
print('│  ├─ Manager manages branch')
print('│  └─ Login via Supabase Auth')
print('│')
print('├─ EMPLOYEES (created by CEO)')
print('│  ├─ Staff, Team Lead, etc.')
print('│  ├─ May have user_id (if they can login)')
print('│  └─ Or just employee record (no login)')
print('│')
print('└─ ATTENDANCE')
if 'user_id' in att_cols:
    print('   └─ Uses user_id (links to auth.users)')
    print('      ⚠️  ISSUE: Staff without login cannot check-in!')
else:
    print('   └─ Uses employee_id (links to employees)')

print()
print('=' * 80)
print('💡 KHUYẾN NGHỊ:')
print('=' * 80)
print()

if has_user_id and 'user_id' in att_cols:
    cursor.execute('SELECT COUNT(*), COUNT(user_id) FROM employees')
    total, with_user = cursor.fetchone()
    
    if with_user < total:
        print('⚠️ VẤN ĐỀ: Attendance dùng user_id nhưng có employees không có user_id!')
        print()
        print('GIẢI PHÁP:')
        print('  Option 1: Tất cả employees phải có user_id (tạo auth account)')
        print('  Option 2: Attendance dùng employee_id thay vì user_id')
        print('  Option 3: employees.user_id luôn bắt buộc (NOT NULL)')
    else:
        print('✅ OK: Tất cả employees có user_id, attendance dùng user_id hợp lý')
else:
    print('ℹ️  Current setup seems OK based on your architecture')

cursor.close()
conn.close()
