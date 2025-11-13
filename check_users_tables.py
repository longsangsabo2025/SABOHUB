"""
Check users table vs auth.users
"""
import psycopg2
from psycopg2.extras import RealDictCursor

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('=' * 80)
print('🔍 CHECK USERS TABLES')
print('=' * 80)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # 1. Check public.users table
    print('\n1️⃣ PUBLIC.USERS TABLE (for app data)')
    cursor.execute("SELECT id, full_name, email, role FROM users ORDER BY created_at")
    public_users = cursor.fetchall()
    print(f'   Total: {len(public_users)} users\n')
    for user in public_users:
        print(f'   👤 {user.get("full_name", "No name")} ({user.get("role", "No role")})')
        print(f'      Email: {user.get("email", "N/A")}')
        print(f'      ID: {user["id"]}\n')
    
    # 2. Check auth.users table
    print('\n2️⃣ AUTH.USERS TABLE (Supabase auth)')
    cursor.execute("""
        SELECT id, email, 
               raw_user_meta_data->>'full_name' as full_name,
               raw_user_meta_data->>'role' as role
        FROM auth.users
        ORDER BY created_at
    """)
    auth_users = cursor.fetchall()
    print(f'   Total: {len(auth_users)} users\n')
    for user in auth_users:
        print(f'   👤 {user.get("full_name", "No name")} ({user.get("role", "No role")})')
        print(f'      Email: {user.get("email", "N/A")}')
        print(f'      ID: {user["id"]}\n')
    
    # 3. Check companies foreign key
    print('\n3️⃣ COMPANIES TABLE FOREIGN KEY')
    cursor.execute("""
        SELECT
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_name = 'companies'
          AND kcu.column_name = 'created_by'
    """)
    fk = cursor.fetchone()
    
    if fk:
        print(f'   companies.{fk["column_name"]} → {fk["foreign_table_name"]}.{fk["foreign_column_name"]}')
    else:
        print('   No foreign key found')
    
    cursor.close()
    conn.close()
    
    print('\n' + '=' * 80)
    print('💡 SOLUTION:')
    print('=' * 80)
    
    if len(public_users) == 0 and len(auth_users) > 0:
        print('\n⚠️  CEOs are in auth.users but public.users is EMPTY')
        print('\n   Options:')
        print('   1. Copy CEOs from auth.users to public.users')
        print('   2. Change companies.created_by foreign key to auth.users')
        print('   3. Use auth.uid() directly without foreign key')
    elif len(public_users) > 0:
        print(f'\n✅ public.users has {len(public_users)} users')
        print('   Use one of these IDs for companies.created_by')
    
    print('=' * 80)
    
except Exception as e:
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
