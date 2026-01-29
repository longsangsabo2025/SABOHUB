#!/usr/bin/env python3
"""
Tạo email cho employees theo format: username@sabohub.com
"""
import os
import psycopg2
from dotenv import load_dotenv
import re

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('📧 TẠO EMAIL CHO EMPLOYEES - format: username@sabohub.com')
print('=' * 80)
print()

# 1. Get all employees without email
cursor.execute("""
    SELECT id, username, full_name, email, role
    FROM employees
    ORDER BY created_at
""")

employees = cursor.fetchall()
print(f'📊 Tìm thấy {len(employees)} employees')
print()

# 2. Generate and update emails
updates = []
for emp_id, username, full_name, current_email, role in employees:
    # Use username for email
    email = f"{username}@sabohub.com"
    
    status = "✅ CREATE" if not current_email else "📝 UPDATE"
    print(f'{status} {username:<20} → {email:<30} ({role})')
    
    updates.append((email, emp_id))

print()
print('=' * 80)
confirm = input(f'🤔 Cập nhật email cho {len(updates)} employees? (yes/no): ')

if confirm.lower() != 'yes':
    print('❌ Đã hủy')
    cursor.close()
    conn.close()
    exit(0)

# 3. Update emails
print()
print('🔄 Đang cập nhật...')

try:
    for email, emp_id in updates:
        cursor.execute("""
            UPDATE employees 
            SET email = %s, updated_at = NOW()
            WHERE id = %s
        """, (email, emp_id))
    
    conn.commit()
    print(f'✅ Đã cập nhật {len(updates)} emails')
    
    # 4. Verify
    print()
    print('📋 Verify:')
    cursor.execute("""
        SELECT username, email, role 
        FROM employees 
        ORDER BY username
    """)
    
    for username, email, role in cursor.fetchall():
        print(f'   ✓ {username:<20} {email:<30} {role}')
    
except Exception as e:
    conn.rollback()
    print(f'❌ Error: {e}')
    
finally:
    cursor.close()
    conn.close()

print()
print('=' * 80)
print('✅ HOÀN THÀNH!')
print('=' * 80)
