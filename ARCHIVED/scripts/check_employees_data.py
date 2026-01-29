"""
Check if employee data was inserted successfully
"""
import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    cursor = conn.cursor()
    
    print("🔍 Checking employees table...")
    
    # Get all employees
    cursor.execute("""
        SELECT 
            e.id,
            e.username,
            e.full_name,
            e.role,
            c.name,
            e.is_active,
            e.created_at
        FROM employees e
        LEFT JOIN companies c ON e.company_id = c.id
        ORDER BY e.created_at DESC
        LIMIT 10
    """)
    
    employees = cursor.fetchall()
    
    if employees:
        print(f"\n✅ Found {len(employees)} employees:\n")
        print(f"{'No.':<4} {'Username':<20} {'Full Name':<25} {'Role':<15} {'Company':<25} {'Active':<8} {'Created'}")
        print("-" * 140)
        
        for idx, emp in enumerate(employees, 1):
            emp_id, username, full_name, role, company, is_active, created_at = emp
            active_status = "✅" if is_active else "❌"
            company_name = company or "N/A"
            created_str = str(created_at)[:19] if created_at else "N/A"
            
            print(f"{idx:<4} {username:<20} {full_name:<25} {role:<15} {company_name:<25} {active_status:<8} {created_str}")
    else:
        print("❌ No employees found in database")
    
    # Count total employees
    cursor.execute("SELECT COUNT(*) FROM employees")
    total = cursor.fetchone()[0]
    print(f"\n📊 Total employees: {total}")
    
    # Count by role
    cursor.execute("""
        SELECT role, COUNT(*) 
        FROM employees 
        GROUP BY role 
        ORDER BY COUNT(*) DESC
    """)
    roles = cursor.fetchall()
    print("\n📊 Employees by role:")
    for role, count in roles:
        print(f"   - {role}: {count}")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
