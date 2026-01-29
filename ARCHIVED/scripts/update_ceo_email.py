#!/usr/bin/env python3
"""
Update CEO email từ longsangsabo1@gmail.com → longsang@sabohub.com
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('UPDATE CEO EMAIL')
print('=' * 80)
print()

# 1. Check current CEO
cursor.execute("""
    SELECT id, full_name, email, role
    FROM users
    WHERE email = 'longsangsabo1@gmail.com'
""")

old_user = cursor.fetchone()

if old_user:
    user_id, full_name, old_email, role = old_user
    print('Tim thay user:')
    print(f'   ID: {user_id}')
    print(f'   Name: {full_name}')
    print(f'   Email: {old_email}')
    print(f'   Role: {role}')
    print()
    
    new_email = 'longsang@sabohub.com'
    
    print(f'Doi email: {old_email} -> {new_email}')
    
    # Update email
    cursor.execute("""
        UPDATE users
        SET email = %s
        WHERE id = %s
        RETURNING id, full_name, email, role
    """, (new_email, user_id))
    
    updated = cursor.fetchone()
    conn.commit()
    
    if updated:
        print()
        print('DA CAP NHAT:')
        print(f'   ID: {updated[0]}')
        print(f'   Name: {updated[1]}')
        print(f'   Email: {updated[2]}')
        print(f'   Role: {updated[3]}')
        print()
        print('=' * 80)
        print('HOAN THANH!')
        print('=' * 80)
        print()
        print('Gio dang nhap voi:')
        print(f'   Email: {new_email}')
        print('   Password: (password cu)')
        print()
        print('LUU Y: Vi da tat Email Auth tren Supabase,')
        print('   ban can dung DEMO USER hoac Custom Auth!')
        print()
        print('Thu DEMO USER:')
        print('   Email: ceo1@sabohub.com')
        print('   Password: demo')
else:
    print('Khong tim thay user voi email longsangsabo1@gmail.com')
    print()
    print('Danh sach users hien tai:')
    cursor.execute("SELECT id, full_name, email, role FROM users ORDER BY created_at")
    for user in cursor.fetchall():
        print(f'   - {user[2]:<40} {user[1]:<30} ({user[3]})')

cursor.close()
conn.close()
