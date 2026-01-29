#!/usr/bin/env python3
"""
Kiểm tra tại sao nhân viên diem không thấy tasks được giao
"""

import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("=== KIỂM TRA TASKS CỦA NHÂN VIÊN DIEM ===\n")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # 1. Tìm employee diem
    print("1️⃣ THÔNG TIN NHÂN VIÊN DIEM:\n")
    cur.execute("""
        SELECT id, username, email, full_name, company_id, branch_id
        FROM employees
        WHERE username = 'diem' OR email LIKE '%diem%'
    """)
    
    employee = cur.fetchone()
    if not employee:
        print("❌ KHÔNG TÌM THẤY NHÂN VIÊN DIEM!")
        exit(1)
    
    emp_id, username, email, name, company_id, branch_id = employee
    print(f"✅ Tìm thấy: {name}")
    print(f"   ID: {emp_id}")
    print(f"   Username: {username}")
    print(f"   Email: {email}")
    print(f"   Company ID: {company_id}")
    print(f"   Branch ID: {branch_id}")
    print()
    
    # 2. Kiểm tra tasks được giao cho diem
    print("2️⃣ TASKS ĐƯỢC GIAO CHO DIEM:\n")
    cur.execute("""
        SELECT 
            t.id,
            t.title,
            t.assigned_to,
            t.assigned_to_name,
            t.status,
            t.company_id,
            t.branch_id,
            t.created_at
        FROM tasks t
        WHERE t.assigned_to = %s OR t.assigned_to_name LIKE %s
        ORDER BY t.created_at DESC
    """, (emp_id, f'%{name}%'))
    
    tasks = cur.fetchall()
    
    if tasks:
        print(f"✅ Tìm thấy {len(tasks)} task(s):\n")
        for task in tasks:
            task_id, title, assigned_to, assigned_name, status, comp_id, br_id, created = task
            print(f"📋 {title}")
            print(f"   ID: {task_id}")
            print(f"   Assigned to: {assigned_to}")
            print(f"   Assigned name: {assigned_name}")
            print(f"   Status: {status}")
            print(f"   Company: {comp_id}")
            print(f"   Branch: {br_id}")
            print(f"   Created: {created}")
            print()
    else:
        print("❌ KHÔNG CÓ TASK NÀO!")
        print("\n💡 Nguyên nhân có thể:")
        print("   1. assigned_to không khớp với employee ID")
        print("   2. assigned_to_name không khớp với tên nhân viên")
        print()
    
    # 3. Kiểm tra TẤT CẢ tasks trong hệ thống
    print("\n3️⃣ TẤT CẢ TASKS TRONG HỆ THỐNG:\n")
    cur.execute("""
        SELECT 
            id,
            title,
            assigned_to,
            assigned_to_name,
            status,
            company_id,
            branch_id
        FROM tasks
        ORDER BY created_at DESC
        LIMIT 10
    """)
    
    all_tasks = cur.fetchall()
    
    if all_tasks:
        print(f"📊 Có {len(all_tasks)} task(s) trong hệ thống:\n")
        for task in all_tasks:
            task_id, title, assigned_to, assigned_name, status, comp_id, br_id = task
            print(f"📋 {title}")
            print(f"   Assigned to ID: {assigned_to}")
            print(f"   Assigned name: {assigned_name}")
            print(f"   Company: {comp_id}, Branch: {br_id}")
            print()
    
    # 4. Kiểm tra RLS policies cho tasks
    print("\n4️⃣ KIỂM TRA RLS POLICIES CHO TASKS:\n")
    cur.execute("""
        SELECT 
            polname as policy_name,
            polcmd as command,
            polroles::text as roles,
            qual::text as using_expression
        FROM pg_policy
        WHERE polrelid = 'tasks'::regclass
        ORDER BY polname
    """)
    
    policies = cur.fetchall()
    
    if policies:
        print(f"🔒 Có {len(policies)} RLS policies:\n")
        for policy in policies:
            pol_name, cmd, roles, expr = policy
            print(f"📜 {pol_name}")
            print(f"   Command: {cmd}")
            print(f"   Expression: {expr[:100] if expr else 'N/A'}...")
            print()
    
    # 5. Kiểm tra có thể query tasks với employee ID không
    print("\n5️⃣ TEST QUERY VỚI EMPLOYEE ID:\n")
    cur.execute("""
        SELECT COUNT(*) 
        FROM tasks 
        WHERE assigned_to = %s
    """, (emp_id,))
    
    count = cur.fetchone()[0]
    print(f"Tasks với assigned_to = '{emp_id}': {count}")
    
    cur.execute("""
        SELECT COUNT(*) 
        FROM tasks 
        WHERE assigned_to_name LIKE %s
    """, (f'%{name}%',))
    
    count2 = cur.fetchone()[0]
    print(f"Tasks với assigned_to_name LIKE '%{name}%': {count2}")
    
    print("\n" + "="*60)
    print("KẾT LUẬN:")
    print("="*60)
    
    if not tasks:
        print("\n❌ VẤN ĐỀ: Nhân viên diem KHÔNG CÓ tasks nào!")
        print("\n💡 GIẢI PHÁP:")
        print("   1. Khi tạo task, cần set assigned_to = employee.id")
        print(f"      (employee.id của diem = '{emp_id}')")
        print("   2. Kiểm tra RLS policies cho phép employee query tasks của mình")
        print("   3. Kiểm tra code frontend có query đúng không")
    else:
        print(f"\n✅ Nhân viên diem CÓ {len(tasks)} task(s)")
        print("\n🔍 Cần kiểm tra:")
        print("   - Frontend có query đúng employee_id không?")
        print("   - RLS policies có cho phép employee xem tasks không?")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ LỖI: {str(e)}")
    import traceback
    traceback.print_exc()
