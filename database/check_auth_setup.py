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
    
    # Check for auth hooks/triggers
    cursor.execute("""
        SELECT routine_name, routine_definition 
        FROM information_schema.routines 
        WHERE routine_name LIKE '%user%' OR routine_name LIKE '%auth%'
        ORDER BY routine_name
    """)
    
    print('📋 Database functions related to users/auth:')
    results = cursor.fetchall()
    for row in results:
        print(f'  - {row[0]}')
    
    if not results:
        print('  ❌ No auth-related functions found!')
    
    # Check triggers on auth.users
    cursor.execute("""
        SELECT trigger_name, event_manipulation, action_statement
        FROM information_schema.triggers 
        WHERE event_object_table = 'users'
    """)
    
    print('\n🔗 Triggers on users table:')
    results = cursor.fetchall()
    for row in results:
        print(f'  - {row[0]} on {row[1]}')
    
    if not results:
        print('  ❌ No triggers found on users table!')
    
    # Check if public.users table exists separately
    cursor.execute("""
        SELECT table_name, table_schema
        FROM information_schema.tables 
        WHERE table_name = 'users'
    """)
    
    print('\n📊 Users tables found:')
    for row in cursor.fetchall():
        print(f'  - {row[1]}.{row[0]}')
    
    # Check recent users in auth.users
    cursor.execute("""
        SELECT id, email, created_at
        FROM auth.users 
        ORDER BY created_at DESC 
        LIMIT 5
    """)
    
    print('\n👥 Recent users in auth.users:')
    for row in cursor.fetchall():
        print(f'  - {row[1]} (created: {row[2]})')
    
    # Check if there's a corresponding public.users entry
    cursor.execute("""
        SELECT COUNT(*) 
        FROM public.users
    """)
    
    count = cursor.fetchone()[0]
    print(f'\n📈 Total users in public.users: {count}')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")