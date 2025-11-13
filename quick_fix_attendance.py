#!/usr/bin/env python3
"""
Fix attendance company_id - simple approach
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('🔧 Fix attendance company_id')
print()

# Get first company (fallback)
cursor.execute("SELECT id, name FROM companies LIMIT 1")
company = cursor.fetchone()

if company:
    company_id, company_name = company
    
    # Update all attendance without company_id
    cursor.execute("""
        UPDATE attendance
        SET company_id = %s
        WHERE company_id IS NULL
        AND deleted_at IS NULL
        RETURNING id
    """, (company_id,))
    
    updated = cursor.fetchall()
    conn.commit()
    
    print(f'✅ Đã set company_id = "{company_name}" cho {len(updated)} records')
    print()
    
    # Verify
    cursor.execute("""
        SELECT COUNT(*) as total,
               COUNT(company_id) as with_company
        FROM attendance
        WHERE deleted_at IS NULL
    """)
    result = cursor.fetchone()
    print(f'📊 Attendance: {result[1]}/{result[0]} có company_id')
    
    if result[1] == result[0]:
        print()
        print('🎉 100% attendance records có company_id!')

cursor.close()
conn.close()
