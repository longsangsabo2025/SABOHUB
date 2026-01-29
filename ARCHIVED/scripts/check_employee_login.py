"""
Check if employee can login - verify users table and auth
"""
import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    cursor = conn.cursor()
    
    print("🔍 Checking employee in employees table...")
    cursor.execute("""
        SELECT id, username, full_name, role, company_id, is_active
        FROM employees
        WHERE username = 'diem'
    """)
    emp = cursor.fetchone()
    
    if emp:
        print(f"✅ Found in employees table:")
        print(f"   - ID: {emp[0]}")
        print(f"   - Username: {emp[1]}")
        print(f"   - Full Name: {emp[2]}")
        print(f"   - Role: {emp[3]}")
        print(f"   - Company ID: {emp[4]}")
        print(f"   - Active: {emp[5]}")
        
        # Check if exists in users table
        print(f"\n🔍 Checking in users table (for login)...")
        cursor.execute("""
            SELECT id, email, full_name, role, company_id, is_active
            FROM users
            WHERE id = %s
        """, (emp[0],))
        user = cursor.fetchone()
        
        if user:
            print(f"✅ Found in users table:")
            print(f"   - ID: {user[0]}")
            print(f"   - Email: {user[1]}")
            print(f"   - Full Name: {user[2]}")
            print(f"   - Role: {user[3]}")
            print(f"   - Company ID: {user[4]}")
            print(f"   - Active: {user[5]}")
        else:
            print("❌ NOT found in users table - CANNOT LOGIN!")
            print("\n⚠️  Employee record exists but no user account for login.")
            print("   Need to create user record in users table or auth.users")
        
        # Check auth.users
        print(f"\n🔍 Checking in auth.users...")
        cursor.execute("""
            SELECT id, email, raw_user_meta_data
            FROM auth.users
            WHERE id = %s
        """, (emp[0],))
        auth_user = cursor.fetchone()
        
        if auth_user:
            print(f"✅ Found in auth.users:")
            print(f"   - ID: {auth_user[0]}")
            print(f"   - Email: {auth_user[1]}")
            print(f"   - Metadata: {auth_user[2]}")
        else:
            print("❌ NOT found in auth.users - CANNOT LOGIN!")
            
    else:
        print("❌ Employee 'diem' not found!")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
