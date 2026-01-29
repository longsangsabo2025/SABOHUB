#!/usr/bin/env python3
"""
Fix attendance bằng cách get company_id từ user
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('🔧 FIX ATTENDANCE COMPANY_ID')
print('=' * 80)
print()

# Get attendance without company_id
cursor.execute("""
    SELECT 
        a.id,
        a.user_id,
        a.branch_id,
        u.email,
        c.id as company_id,
        c.name as company_name
    FROM attendance a
    LEFT JOIN users u ON u.id = a.user_id
    LEFT JOIN companies c ON c.ceo_user_id = a.user_id OR c.id IN (
        SELECT company_id FROM employees WHERE id = a.user_id
    )
    WHERE a.deleted_at IS NULL
    AND a.company_id IS NULL
""")

records = cursor.fetchall()

if records:
    print(f'Tìm thấy {len(records)} attendance records cần fix')
    print()
    
    for att_id, user_id, branch_id, email, company_id, company_name in records:
        print(f'Attendance: {att_id[:8]}...')
        print(f'   User: {email}')
        
        if company_id:
            print(f'   → Set company_id = {company_id[:8]}... ({company_name})')
            cursor.execute("""
                UPDATE attendance
                SET company_id = %s, updated_at = NOW()
                WHERE id = %s
            """, (company_id, att_id))
        else:
            # Fallback: get first company
            cursor.execute("SELECT id, name FROM companies LIMIT 1")
            first_company = cursor.fetchone()
            if first_company:
                print(f'   → Set company_id = {first_company[0][:8]}... ({first_company[1]}) [FALLBACK]')
                cursor.execute("""
                    UPDATE attendance
                    SET company_id = %s, updated_at = NOW()
                    WHERE id = %s
                """, (first_company[0], att_id))
        print()
    
    conn.commit()
    print('✅ Đã fix')
else:
    print('✅ Tất cả attendance đã có company_id')

# Verify
print()
print('📊 VERIFY:')
cursor.execute("""
    SELECT COUNT(*) as total,
           COUNT(company_id) as with_company
    FROM attendance
    WHERE deleted_at IS NULL
""")
result = cursor.fetchone()
print(f'   Attendance: {result[1]}/{result[0]} có company_id')

if result[1] == result[0]:
    print()
    print('🎉 100% attendance records có company_id!')

cursor.close()
conn.close()
