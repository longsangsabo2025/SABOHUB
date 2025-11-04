import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("🚀 Assigning Manager to SABO Billiards")
print("="*60)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("✅ Connected to database")
    
    # Get SABO Billiards company ID
    print("\n🔍 Finding SABO Billiards company...")
    cur.execute("SELECT id, name FROM companies WHERE name = 'SABO Billiards'")
    company = cur.fetchone()
    
    if not company:
        print("❌ SABO Billiards company not found!")
        exit(1)
    
    company_id = company[0]
    company_name = company[1]
    print(f"✅ Found: {company_name}")
    print(f"   ID: {company_id}")
    
    # Get user
    email = "ngocdiem1112@gmail.com"
    print(f"\n🔍 Finding user: {email}")
    cur.execute("SELECT id, full_name, role, company_id FROM users WHERE email = %s", (email,))
    user = cur.fetchone()
    
    if not user:
        print(f"❌ User {email} not found!")
        exit(1)
    
    user_id = user[0]
    print(f"✅ Found: {user[1]}")
    print(f"   Current role: {user[2]}")
    print(f"   Current company: {user[3] or 'None'}")
    
    # Update user to assign to company
    print(f"\n🔄 Assigning user to {company_name}...")
    
    # Valid roles are: CEO, MANAGER, SHIFT_LEADER, STAFF
    # User already has MANAGER role, just update company_id
    cur.execute("""
        UPDATE users 
        SET company_id = %s 
        WHERE id = %s
    """, (company_id, user_id))
    
    conn.commit()
    print("✅ User assigned to company successfully!")
    
    # Verify
    print("\n" + "="*60)
    print("📋 FINAL RESULT")
    print("="*60)
    
    cur.execute("SELECT email, full_name, role, company_id FROM users WHERE id = %s", (user_id,))
    final = cur.fetchone()
    
    print(f"✅ Email: {final[0]}")
    print(f"✅ Name: {final[1]}")
    print(f"✅ Role: {final[2]}")
    print(f"✅ Company ID: {final[3]}")
    print(f"✅ Company Name: {company_name}")
    
    cur.close()
    conn.close()
    
    print("\n🎉 SUCCESS! Manager now belongs to SABO Billiards")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    if 'conn' in locals():
        conn.rollback()
