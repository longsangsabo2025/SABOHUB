import psycopg2
import uuid

# Database connection
conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("🚀 Adding Manager to SABO Billiards")
print("="*60)

try:
    # Connect to database
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("✅ Connected to database")
    
    # Step 1: Get SABO Billiards company ID
    print("\n🔍 Step 1: Finding SABO Billiards company...")
    cur.execute("SELECT id, name FROM companies WHERE name = 'SABO Billiards'")
    company = cur.fetchone()
    
    if not company:
        print("❌ SABO Billiards company not found!")
        exit(1)
    
    company_id = company[0]
    company_name = company[1]
    print(f"✅ Found: {company_name}")
    print(f"   ID: {company_id}")
    
    # Step 2: Check if user exists
    print("\n🔍 Step 2: Checking if user exists...")
    email = "ngocdiem1112@gmail.com"
    cur.execute("SELECT id, full_name, role, company_id FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    
    if user:
        # User exists - update
        user_id = user[0]
        print(f"✅ User exists: {user[1] or 'N/A'}")
        print(f"   Current role: {user[2] or 'N/A'}")
        print(f"   Current company: {user[3] or 'None'}")
        
        print("\n🔄 Step 3: Updating user...")
        cur.execute("""
            UPDATE users 
            SET role = 'BRANCH_MANAGER', company_id = %s 
            WHERE id = %s
        """, (company_id, user_id))
        
        conn.commit()
        print("✅ User updated successfully!")
        
    else:
        # User doesn't exist - create new
        print(f"⚠️ User {email} not found in database")
        print("\n🔧 Step 3: Creating new user record...")
        
        new_user_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO users (id, email, full_name, role, company_id, email_verified)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (new_user_id, email, "Ngọc Diễm", "BRANCH_MANAGER", company_id, False))
        
        conn.commit()
        print("✅ User created successfully!")
        print(f"   New user ID: {new_user_id}")
        print("\n⚠️ Note: User still needs to sign up in app to login")
    
    # Step 4: Verify final state
    print("\n" + "="*60)
    print("📋 FINAL SUMMARY")
    print("="*60)
    
    cur.execute("SELECT id, email, full_name, role, company_id FROM users WHERE email = %s", (email,))
    final_user = cur.fetchone()
    
    if final_user:
        print(f"✅ Email: {final_user[1]}")
        print(f"✅ Full Name: {final_user[2] or 'N/A'}")
        print(f"✅ Role: {final_user[3]}")
        print(f"✅ Company ID: {final_user[4]}")
        print(f"✅ Company Name: {company_name}")
    
    # Close connection
    cur.close()
    conn.close()
    
    print("\n🎉 SUCCESS! Manager added to database")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    if 'conn' in locals():
        conn.rollback()
