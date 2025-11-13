import psycopg2
from datetime import datetime
import sys
import codecs

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'strict')

# Connection string from .env
conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    
    print("=" * 80)
    print("CHECKING EMPLOYEES IN DATABASE")
    print("=" * 80)
    
    # Get all employees from users table
    print("\n1. EMPLOYEES IN 'users' TABLE:")
    print("-" * 80)
    cursor.execute("""
        SELECT 
            id,
            full_name,
            email,
            role,
            company_id,
            created_at
        FROM users
        WHERE company_id IS NOT NULL
        ORDER BY created_at DESC
    """)
    
    users = cursor.fetchall()
    if users:
        for idx, user in enumerate(users, 1):
            print(f"\n{idx}. User:")
            print(f"   ID: {user[0]}")
            print(f"   Name: {user[1]}")
            print(f"   Email: {user[2]}")
            print(f"   Role: {user[3]}")
            print(f"   Company ID: {user[4]}")
            print(f"   Created: {user[5]}")
    else:
        print("   No employees found in users table")
    
    # Get all employees from employees table
    print("\n\n2. EMPLOYEES IN 'employees' TABLE:")
    print("-" * 80)
    cursor.execute("""
        SELECT 
            id,
            full_name,
            username,
            role,
            company_id,
            created_at
        FROM employees
        ORDER BY created_at DESC
    """)
    
    employees = cursor.fetchall()
    if employees:
        for idx, emp in enumerate(employees, 1):
            print(f"\n{idx}. Employee:")
            print(f"   ID: {emp[0]}")
            print(f"   Name: {emp[1]}")
            print(f"   Username: {emp[2]}")
            print(f"   Role: {emp[3]}")
            print(f"   Company ID: {emp[4]}")
            print(f"   Created: {emp[5]}")
    else:
        print("   No employees found in employees table")
    
    # Check for specific company (SABO Billiards)
    print("\n\n3. EMPLOYEES FOR 'SABO Billiards':")
    print("-" * 80)
    cursor.execute("""
        SELECT 
            c.id as company_id,
            c.name as company_name,
            COUNT(u.id) as employee_count
        FROM companies c
        LEFT JOIN users u ON u.company_id = c.id
        WHERE c.name ILIKE '%SABO%'
        GROUP BY c.id, c.name
    """)
    
    company_stats = cursor.fetchall()
    if company_stats:
        for stat in company_stats:
            print(f"\nCompany: {stat[1]}")
            print(f"Company ID: {stat[0]}")
            print(f"Employee Count: {stat[2]}")
            
            # Get detailed employee list for this company
            cursor.execute("""
                SELECT 
                    id,
                    full_name,
                    email,
                    role,
                    created_at
                FROM users
                WHERE company_id = %s
                ORDER BY created_at DESC
            """, (stat[0],))
            
            company_employees = cursor.fetchall()
            if company_employees:
                print("\n   Employees:")
                for idx, emp in enumerate(company_employees, 1):
                    print(f"   {idx}. {emp[1]} ({emp[2]}) - {emp[3]} - Created: {emp[4]}")
            else:
                print("   No employees found for this company")
    else:
        print("   SABO Billiards company not found")
    
    # Check auth.users table
    print("\n\n4. CHECKING auth.users TABLE:")
    print("-" * 80)
    cursor.execute("""
        SELECT 
            id,
            email,
            created_at
        FROM auth.users
        ORDER BY created_at DESC
        LIMIT 10
    """)
    
    auth_users = cursor.fetchall()
    if auth_users:
        print(f"\nFound {len(auth_users)} recent auth users:")
        for idx, user in enumerate(auth_users, 1):
            print(f"{idx}. {user[1]} - ID: {user[0]} - Created: {user[2]}")
    else:
        print("   No auth users found")
    
    print("\n" + "=" * 80)
    print("CHECK COMPLETE")
    print("=" * 80)
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
