import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("KIEM TRA EMPLOYEES TRONG COMPANY")
print("=" * 60)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Tim company
    cur.execute("""
        SELECT id, name
        FROM companies
        LIMIT 1
    """)
    
    company = cur.fetchone()
    if not company:
        print("KHONG CO COMPANY NAO!")
        exit(1)
    
    company_id, company_name = company
    print(f"\nCOMPANY: {company_name}")
    print(f"ID: {company_id}")
    
    # Lay employees trong company
    print("\n" + "=" * 60)
    print("EMPLOYEES TRONG COMPANY:")
    print("=" * 60)
    
    cur.execute("""
        SELECT 
            id,
            username,
            full_name,
            email,
            role,
            company_id,
            branch_id,
            is_active
        FROM employees
        WHERE company_id = %s
        ORDER BY created_at DESC
    """, (company_id,))
    
    employees = cur.fetchall()
    
    if employees:
        print(f"\nTim thay {len(employees)} employee(s):\n")
        for emp in employees:
            emp_id, username, name, email, role, comp_id, br_id, active = emp
            print(f"Name: {name}")
            print(f"  ID: {emp_id}")
            print(f"  Username: {username}")
            print(f"  Email: {email}")
            print(f"  Role: {role}")
            print(f"  Company: {comp_id}")
            print(f"  Branch: {br_id}")
            print(f"  Active: {active}")
            print()
    else:
        print(f"\nKHONG CO EMPLOYEE NAO TRONG COMPANY {company_name}!")
        print("\nKiem tra:")
        print("  - Employees co duoc gan vao company khong?")
        print("  - Company ID co dung khong?")
    
    # Kiem tra tat ca employees
    print("\n" + "=" * 60)
    print("TAT CA EMPLOYEES TRONG HE THONG:")
    print("=" * 60)
    
    cur.execute("""
        SELECT 
            id,
            username,
            full_name,
            company_id,
            branch_id
        FROM employees
        ORDER BY created_at DESC
    """)
    
    all_emps = cur.fetchall()
    
    if all_emps:
        print(f"\nCo {len(all_emps)} employee(s):\n")
        for emp in all_emps:
            emp_id, username, name, comp_id, br_id = emp
            print(f"{name} (username: {username})")
            print(f"  Company ID: {comp_id}")
            print(f"  Branch ID: {br_id}")
            print()
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\nLOI: {str(e)}")
    import traceback
    traceback.print_exc()
