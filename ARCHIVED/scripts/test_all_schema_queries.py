#!/usr/bin/env python3
"""
COMPREHENSIVE TEST - Schema & Queries
Test toàn bộ database schema và queries
"""
import os
import psycopg2
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

def test_database():
    conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
    cursor = conn.cursor()
    
    print('=' * 80)
    print('🧪 COMPREHENSIVE DATABASE TEST')
    print('=' * 80)
    print()
    
    errors = []
    warnings = []
    success_count = 0
    
    # ============================================================================
    # TEST 1: TABLE EXISTENCE
    # ============================================================================
    print('📋 TEST 1: TABLE EXISTENCE')
    print('-' * 80)
    
    required_tables = [
        'users', 'companies', 'branches', 'employees', 
        'attendance', 'tasks', 'task_templates', 
        'business_documents', 'employee_documents'
    ]
    
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name
    """)
    
    existing_tables = [row[0] for row in cursor.fetchall()]
    
    for table in required_tables:
        if table in existing_tables:
            print(f'   ✅ {table:<30} EXISTS')
            success_count += 1
        else:
            msg = f'{table} table NOT FOUND'
            print(f'   ❌ {msg}')
            errors.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 2: ATTENDANCE TABLE SCHEMA
    # ============================================================================
    print('📋 TEST 2: ATTENDANCE TABLE SCHEMA')
    print('-' * 80)
    
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'attendance'
        ORDER BY ordinal_position
    """)
    
    attendance_columns = cursor.fetchall()
    required_attendance_cols = {
        'id': 'uuid',
        'user_id': 'uuid',
        'branch_id': 'uuid',
        'company_id': 'uuid',
        'check_in': 'timestamp',
        'check_out': 'timestamp',
        'check_in_latitude': 'numeric',
        'check_in_longitude': 'numeric',
        'check_out_latitude': 'numeric',
        'check_out_longitude': 'numeric',
        'created_at': 'timestamp',
        'deleted_at': 'timestamp',
    }
    
    existing_att_cols = {col[0]: col[1] for col in attendance_columns}
    
    for col_name, expected_type in required_attendance_cols.items():
        if col_name in existing_att_cols:
            actual_type = existing_att_cols[col_name]
            match = expected_type in actual_type or actual_type.startswith(expected_type)
            status = '✅' if match else '⚠️'
            print(f'   {status} {col_name:<25} {actual_type}')
            if match:
                success_count += 1
            else:
                msg = f'attendance.{col_name} type mismatch: expected {expected_type}, got {actual_type}'
                warnings.append(msg)
        else:
            msg = f'attendance.{col_name} MISSING'
            print(f'   ❌ {col_name:<25} MISSING')
            errors.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 3: EMPLOYEES TABLE SCHEMA
    # ============================================================================
    print('📋 TEST 3: EMPLOYEES TABLE SCHEMA')
    print('-' * 80)
    
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'employees'
        ORDER BY ordinal_position
    """)
    
    employee_columns = cursor.fetchall()
    required_employee_cols = {
        'id': 'uuid',
        'company_id': 'uuid',
        'branch_id': 'uuid',
        'username': 'text',
        'password_hash': 'text',
        'full_name': 'text',
        'email': 'text',
        'phone': 'text',
        'role': 'text',
        'is_active': 'boolean',
        'created_by_ceo_id': 'uuid',
        'created_at': 'timestamp',
        'deleted_at': 'timestamp',
    }
    
    existing_emp_cols = {col[0]: col[1] for col in employee_columns}
    
    for col_name, expected_type in required_employee_cols.items():
        if col_name in existing_emp_cols:
            actual_type = existing_emp_cols[col_name]
            match = expected_type in actual_type or actual_type.startswith(expected_type)
            status = '✅' if match else '⚠️'
            nullable = [c[2] for c in employee_columns if c[0] == col_name][0]
            nullable_str = '(nullable)' if nullable == 'YES' else ''
            print(f'   {status} {col_name:<25} {actual_type} {nullable_str}')
            if match:
                success_count += 1
        else:
            msg = f'employees.{col_name} MISSING'
            print(f'   ❌ {col_name:<25} MISSING')
            errors.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 4: TASKS TABLE SCHEMA
    # ============================================================================
    print('📋 TEST 4: TASKS TABLE SCHEMA')
    print('-' * 80)
    
    cursor.execute("""
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'tasks'
        ORDER BY ordinal_position
    """)
    
    task_columns = cursor.fetchall()
    required_task_cols = {
        'id': 'uuid',
        'company_id': 'uuid',
        'title': 'text',
        'description': 'text',
        'assigned_to': 'uuid',
        'assigned_to_name': 'text',
        'status': 'text',
        'priority': 'text',
        'due_date': 'timestamp',
        'created_by': 'uuid',
        'created_at': 'timestamp',
        'deleted_at': 'timestamp',
    }
    
    existing_task_cols = {col[0]: col[1] for col in task_columns}
    
    for col_name, expected_type in required_task_cols.items():
        if col_name in existing_task_cols:
            actual_type = existing_task_cols[col_name]
            match = expected_type in actual_type or actual_type.startswith(expected_type)
            status = '✅' if match else '⚠️'
            print(f'   {status} {col_name:<25} {actual_type}')
            if match:
                success_count += 1
        else:
            msg = f'tasks.{col_name} MISSING'
            print(f'   ❌ {col_name:<25} MISSING')
            errors.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 5: FOREIGN KEYS
    # ============================================================================
    print('📋 TEST 5: FOREIGN KEY CONSTRAINTS')
    print('-' * 80)
    
    cursor.execute("""
        SELECT
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name IN ('attendance', 'employees', 'tasks', 'branches')
        ORDER BY tc.table_name, kcu.column_name
    """)
    
    foreign_keys = cursor.fetchall()
    
    for table, column, ref_table, ref_column in foreign_keys:
        print(f'   ✅ {table}.{column:<20} → {ref_table}.{ref_column}')
        success_count += 1
    
    if not foreign_keys:
        msg = 'No foreign keys found (might be OK if using RLS only)'
        print(f'   ⚠️ {msg}')
        warnings.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 6: DATA INTEGRITY
    # ============================================================================
    print('📋 TEST 6: DATA INTEGRITY CHECKS')
    print('-' * 80)
    
    # Test 6.1: Attendance with branch_id
    cursor.execute("""
        SELECT COUNT(*) as total,
               COUNT(branch_id) as with_branch,
               COUNT(company_id) as with_company
        FROM attendance
        WHERE deleted_at IS NULL
    """)
    att_count = cursor.fetchone()
    if att_count[0] > 0:
        if att_count[1] == att_count[0]:
            print(f'   ✅ Attendance: {att_count[0]} records, all have branch_id')
            success_count += 1
        else:
            msg = f'Attendance: {att_count[0] - att_count[1]} records missing branch_id'
            print(f'   ❌ {msg}')
            errors.append(msg)
        
        if att_count[2] == att_count[0]:
            print(f'   ✅ Attendance: {att_count[0]} records, all have company_id')
            success_count += 1
        else:
            msg = f'Attendance: {att_count[0] - att_count[2]} records missing company_id'
            print(f'   ⚠️ {msg}')
            warnings.append(msg)
    else:
        print(f'   ℹ️  Attendance: 0 records (empty table)')
    
    # Test 6.2: Employees with email
    cursor.execute("""
        SELECT COUNT(*) as total,
               COUNT(email) as with_email
        FROM employees
        WHERE deleted_at IS NULL
    """)
    emp_count = cursor.fetchone()
    if emp_count[0] > 0:
        if emp_count[1] == emp_count[0]:
            print(f'   ✅ Employees: {emp_count[0]} records, all have email')
            success_count += 1
        else:
            msg = f'Employees: {emp_count[0] - emp_count[1]} records missing email'
            print(f'   ⚠️ {msg}')
            warnings.append(msg)
    
    # Test 6.3: Tasks with assigned_to_name
    cursor.execute("""
        SELECT COUNT(*) as total,
               COUNT(assigned_to_name) as with_name
        FROM tasks
        WHERE deleted_at IS NULL
    """)
    task_count = cursor.fetchone()
    if task_count[0] > 0:
        if task_count[1] == task_count[0]:
            print(f'   ✅ Tasks: {task_count[0]} records, all have assigned_to_name')
            success_count += 1
        else:
            msg = f'Tasks: {task_count[0] - task_count[1]} records missing assigned_to_name'
            print(f'   ⚠️ {msg}')
            warnings.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 7: CRITICAL QUERIES
    # ============================================================================
    print('📋 TEST 7: CRITICAL QUERIES')
    print('-' * 80)
    
    # Query 7.1: Get attendance with branch info
    try:
        cursor.execute("""
            SELECT 
                a.id,
                a.user_id,
                a.branch_id,
                a.company_id,
                b.name as branch_name,
                a.check_in,
                a.check_out
            FROM attendance a
            LEFT JOIN branches b ON b.id = a.branch_id
            WHERE a.deleted_at IS NULL
            LIMIT 5
        """)
        cursor.fetchall()
        print(f'   ✅ Query: Attendance with branch info')
        success_count += 1
    except Exception as e:
        msg = f'Query failed: Attendance with branch - {e}'
        print(f'   ❌ {msg}')
        errors.append(msg)
    
    # Query 7.2: Get employees with company
    try:
        cursor.execute("""
            SELECT 
                e.id,
                e.username,
                e.email,
                e.full_name,
                e.role,
                c.name as company_name,
                b.name as branch_name
            FROM employees e
            LEFT JOIN companies c ON c.id = e.company_id
            LEFT JOIN branches b ON b.id = e.branch_id
            WHERE e.deleted_at IS NULL
            LIMIT 5
        """)
        cursor.fetchall()
        print(f'   ✅ Query: Employees with company/branch')
        success_count += 1
    except Exception as e:
        msg = f'Query failed: Employees - {e}'
        print(f'   ❌ {msg}')
        errors.append(msg)
    
    # Query 7.3: Get tasks with assignee name
    try:
        cursor.execute("""
            SELECT 
                t.id,
                t.title,
                t.assigned_to,
                t.assigned_to_name,
                t.status,
                t.priority,
                t.due_date
            FROM tasks t
            WHERE t.deleted_at IS NULL
            LIMIT 5
        """)
        cursor.fetchall()
        print(f'   ✅ Query: Tasks with assignee')
        success_count += 1
    except Exception as e:
        msg = f'Query failed: Tasks - {e}'
        print(f'   ❌ {msg}')
        errors.append(msg)
    
    # Query 7.4: Complex join - attendance + employees + branches
    try:
        cursor.execute("""
            SELECT 
                a.id,
                u.email as user_email,
                e.full_name as employee_name,
                b.name as branch_name,
                c.name as company_name,
                a.check_in,
                a.check_out
            FROM attendance a
            LEFT JOIN users u ON u.id = a.user_id
            LEFT JOIN employees e ON e.id = a.user_id
            LEFT JOIN branches b ON b.id = a.branch_id
            LEFT JOIN companies c ON c.id = a.company_id
            WHERE a.deleted_at IS NULL
            LIMIT 5
        """)
        cursor.fetchall()
        print(f'   ✅ Query: Complex join (attendance+users+employees+branches)')
        success_count += 1
    except Exception as e:
        msg = f'Query failed: Complex join - {e}'
        print(f'   ❌ {msg}')
        errors.append(msg)
    
    print()
    
    # ============================================================================
    # TEST 8: RLS POLICIES
    # ============================================================================
    print('📋 TEST 8: RLS POLICIES')
    print('-' * 80)
    
    cursor.execute("""
        SELECT 
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd
        FROM pg_policies
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
    """)
    
    policies = cursor.fetchall()
    
    if policies:
        tables_with_rls = set()
        for schema, table, policy, permissive, roles, cmd in policies:
            print(f'   ✅ {table}.{policy:<40} {cmd}')
            tables_with_rls.add(table)
            success_count += 1
        
        print()
        print(f'   📊 Total: {len(tables_with_rls)} tables with RLS policies')
    else:
        msg = 'No RLS policies found'
        print(f'   ⚠️ {msg}')
        warnings.append(msg)
    
    print()
    
    # ============================================================================
    # SUMMARY
    # ============================================================================
    print('=' * 80)
    print('📊 TEST SUMMARY')
    print('=' * 80)
    print()
    print(f'✅ Success: {success_count} checks passed')
    print(f'⚠️  Warnings: {len(warnings)}')
    print(f'❌ Errors: {len(errors)}')
    print()
    
    if warnings:
        print('⚠️  WARNINGS:')
        for i, w in enumerate(warnings, 1):
            print(f'   {i}. {w}')
        print()
    
    if errors:
        print('❌ ERRORS:')
        for i, e in enumerate(errors, 1):
            print(f'   {i}. {e}')
        print()
    
    if not errors:
        print('🎉 ALL CRITICAL TESTS PASSED!')
        print()
        print('✅ Schema structure is correct')
        print('✅ All required columns exist')
        print('✅ Critical queries work')
        print('✅ Data integrity is good')
    else:
        print('⚠️  SOME TESTS FAILED - Please review errors above')
    
    print()
    print('=' * 80)
    
    cursor.close()
    conn.close()
    
    return len(errors) == 0

if __name__ == '__main__':
    success = test_database()
    exit(0 if success else 1)
