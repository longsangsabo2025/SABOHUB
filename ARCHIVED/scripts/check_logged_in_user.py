"""
Check current logged in employee user data
"""
import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    cursor = conn.cursor()
    
    print("🔍 Checking latest employee login...")
    
    # Get employee Võ Ngọc Diễm
    cursor.execute("""
        SELECT 
            id, username, full_name, role, company_id, is_active, last_login_at
        FROM employees
        WHERE username = 'diem'
    """)
    
    emp = cursor.fetchone()
    if emp:
        print(f"\n📋 Employee data:")
        print(f"   ID: {emp[0]}")
        print(f"   Username: {emp[1]}")
        print(f"   Full Name: {emp[2]}")
        print(f"   Role: {emp[3]}")  # <-- This should be MANAGER
        print(f"   Company ID: {emp[4]}")
        print(f"   Active: {emp[5]}")
        print(f"   Last Login: {emp[6]}")
        
        # Check if role is being saved correctly to users table
        print(f"\n🔍 Checking users table (for app User model)...")
        cursor.execute("""
            SELECT id, email, full_name, role, company_id
            FROM users
            WHERE id = %s
        """, (emp[0],))
        
        user = cursor.fetchone()
        if user:
            print(f"\n📋 Users table data:")
            print(f"   ID: {user[0]}")
            print(f"   Email: {user[1]}")
            print(f"   Full Name: {user[2]}")
            print(f"   Role: {user[3]}")  # <-- This should ALSO be MANAGER
            print(f"   Company ID: {user[4]}")
            
            if user[3] != emp[3]:
                print(f"\n⚠️  WARNING: Role mismatch!")
                print(f"   Employees table: {emp[3]}")
                print(f"   Users table: {user[3]}")
        else:
            print("\n❌ No record in users table!")
    else:
        print("❌ Employee 'diem' not found!")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
