#!/usr/bin/env python3
"""
Fix các warnings còn lại:
1. Attendance: 2 records missing company_id
2. Tasks: 1 record missing assigned_to_name
"""
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

print('=' * 80)
print('🔧 FIX REMAINING DATA ISSUES')
print('=' * 80)
print()

# ============================================================================
# FIX 1: Attendance missing company_id
# ============================================================================
print('📋 FIX 1: Attendance records missing company_id')
print('-' * 80)

cursor.execute("""
    SELECT 
        a.id,
        a.user_id,
        a.branch_id,
        a.company_id,
        b.company_id as branch_company_id
    FROM attendance a
    LEFT JOIN branches b ON b.id = a.branch_id
    WHERE a.deleted_at IS NULL
    AND a.company_id IS NULL
""")

missing_company = cursor.fetchall()

if missing_company:
    print(f'Tìm thấy {len(missing_company)} attendance records thiếu company_id')
    print()
    
    for att_id, user_id, branch_id, company_id, branch_company_id in missing_company:
        if branch_company_id:
            print(f'   🔧 Attendance {att_id[:8]}... → company_id = {branch_company_id[:8]}...')
            cursor.execute("""
                UPDATE attendance
                SET company_id = %s, updated_at = NOW()
                WHERE id = %s
            """, (branch_company_id, att_id))
        else:
            print(f'   ⚠️ Attendance {att_id[:8]}... - không tìm thấy company_id từ branch')
    
    conn.commit()
    print()
    print(f'✅ Đã fix {len(missing_company)} records')
else:
    print('✅ Tất cả attendance records đã có company_id')

print()

# ============================================================================
# FIX 2: Tasks missing assigned_to_name
# ============================================================================
print('📋 FIX 2: Tasks missing assigned_to_name')
print('-' * 80)

cursor.execute("""
    SELECT 
        t.id,
        t.assigned_to,
        t.assigned_to_name,
        u.email as user_email,
        u.full_name as user_full_name,
        e.full_name as employee_full_name
    FROM tasks t
    LEFT JOIN users u ON u.id = t.assigned_to
    LEFT JOIN employees e ON e.id = t.assigned_to
    WHERE t.deleted_at IS NULL
    AND t.assigned_to_name IS NULL
""")

missing_names = cursor.fetchall()

if missing_names:
    print(f'Tìm thấy {len(missing_names)} tasks thiếu assigned_to_name')
    print()
    
    for task_id, assigned_to, assigned_to_name, user_email, user_full_name, emp_full_name in missing_names:
        # Ưu tiên: employee full_name > user full_name > user email > "Unknown"
        name = emp_full_name or user_full_name or user_email or "Unknown User"
        
        print(f'   🔧 Task {task_id[:8]}... → assigned_to_name = "{name}"')
        cursor.execute("""
            UPDATE tasks
            SET assigned_to_name = %s, updated_at = NOW()
            WHERE id = %s
        """, (name, task_id))
    
    conn.commit()
    print()
    print(f'✅ Đã fix {len(missing_names)} tasks')
else:
    print('✅ Tất cả tasks đã có assigned_to_name')

print()

# ============================================================================
# VERIFY
# ============================================================================
print('=' * 80)
print('📊 VERIFICATION')
print('=' * 80)
print()

# Check attendance
cursor.execute("""
    SELECT COUNT(*) as total,
           COUNT(company_id) as with_company
    FROM attendance
    WHERE deleted_at IS NULL
""")
att_count = cursor.fetchone()
print(f'✅ Attendance: {att_count[1]}/{att_count[0]} có company_id')

# Check tasks
cursor.execute("""
    SELECT COUNT(*) as total,
           COUNT(assigned_to_name) as with_name
    FROM tasks
    WHERE deleted_at IS NULL
""")
task_count = cursor.fetchone()
print(f'✅ Tasks: {task_count[1]}/{task_count[0]} có assigned_to_name')

print()
print('=' * 80)
print('✅ HOÀN THÀNH!')
print('=' * 80)

cursor.close()
conn.close()
