import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    cursor = conn.cursor()
    
    print("🔍 Checking for user/profile tables...")
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND (table_name LIKE '%user%' OR table_name LIKE '%profile%')
        ORDER BY table_name
    """)
    tables = cursor.fetchall()
    print(f"Found tables: {[t[0] for t in tables]}")
    
    print("\n🔍 Checking employees table columns...")
    cursor.execute("""
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'employees'
        ORDER BY ordinal_position
    """)
    columns = cursor.fetchall()
    print("Employees columns:")
    for col in columns:
        print(f"  - {col[0]}: {col[1]}")
    
    print("\n🔍 Checking auth schema...")
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'auth'
        ORDER BY table_name
    """)
    auth_tables = cursor.fetchall()
    print(f"Auth tables: {[t[0] for t in auth_tables]}")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
