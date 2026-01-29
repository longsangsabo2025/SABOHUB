import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    cursor = conn.cursor()
    
    print("🔍 Checking users table columns...")
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    print("Users table columns:")
    for col in columns:
        print(f"  - {col[0]}: {col[1]}")
    
    print("\n🔍 Sample data from users table...")
    cursor.execute("""
        SELECT id, role, company_id 
        FROM users 
        WHERE role = 'CEO' 
        LIMIT 1
    """)
    result = cursor.fetchone()
    if result:
        print(f"Sample CEO user found: id={result[0]}, role={result[1]}, company_id={result[2]}")
    else:
        print("No CEO user found")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
