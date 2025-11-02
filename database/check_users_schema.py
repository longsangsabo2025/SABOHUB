import psycopg2

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

try:
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    
    cursor = conn.cursor()
    
    # Get column information
    cursor.execute("""
        SELECT column_name, data_type, column_default, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'users'
        ORDER BY ordinal_position
    """)
    
    print("\n📋 Users table columns:")
    for row in cursor.fetchall():
        print(f"  - {row[0]}: {row[1]} (default: {row[2]}, nullable: {row[3]})")
    
    # Get check constraints
    cursor.execute("""
        SELECT con.conname, pg_get_constraintdef(con.oid)
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        WHERE rel.relname = 'users' AND con.contype = 'c'
    """)
    
    print("\n✅ Check constraints:")
    for row in cursor.fetchall():
        print(f"  - {row[0]}: {row[1]}")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
