"""
Check tasks and users table structure and foreign key constraints
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("="*80)
    print("📋 TASKS TABLE STRUCTURE")
    print("="*80)
    
    # Get all columns in tasks table
    cur.execute("""
        SELECT 
            column_name, 
            data_type, 
            column_default,
            is_nullable,
            character_maximum_length
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = 'tasks'
        ORDER BY ordinal_position;
    """)
    
    print("\nColumns:")
    for row in cur.fetchall():
        col_name, data_type, default, nullable, max_len = row
        print(f"  - {col_name:25} {data_type:20} nullable={nullable:3} default={default}")
    
    # Get foreign key constraints on tasks table
    print("\n" + "="*80)
    print("🔗 FOREIGN KEY CONSTRAINTS ON TASKS TABLE")
    print("="*80)
    
    cur.execute("""
        SELECT
            tc.constraint_name,
            tc.table_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND tc.table_name = 'tasks';
    """)
    
    fk_constraints = cur.fetchall()
    if fk_constraints:
        for row in fk_constraints:
            const_name, table, column, foreign_table, foreign_column = row
            print(f"\n  Constraint: {const_name}")
            print(f"    {table}.{column} -> {foreign_table}.{foreign_column}")
    else:
        print("\n  No foreign key constraints found")
    
    # Check if users table exists
    print("\n" + "="*80)
    print("👤 USERS TABLE STRUCTURE")
    print("="*80)
    
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'users'
        );
    """)
    
    users_exists = cur.fetchone()[0]
    
    if users_exists:
        print("\n✅ Users table EXISTS")
        
        # Get users table columns
        cur.execute("""
            SELECT 
                column_name, 
                data_type, 
                is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public' 
            AND table_name = 'users'
            ORDER BY ordinal_position;
        """)
        
        print("\nColumns:")
        for row in cur.fetchall():
            col_name, data_type, nullable = row
            print(f"  - {col_name:25} {data_type:20} nullable={nullable}")
        
        # Count users
        cur.execute("SELECT COUNT(*) FROM users;")
        user_count = cur.fetchone()[0]
        print(f"\n📊 Total users in database: {user_count}")
        
        if user_count > 0:
            # Show sample users
            cur.execute("SELECT id, email, role FROM users LIMIT 5;")
            print("\nSample users:")
            for row in cur.fetchall():
                print(f"  - {row[0]} | {row[1]} | {row[2]}")
    else:
        print("\n❌ Users table DOES NOT EXIST!")
    
    # Check for auth.users (Supabase default)
    print("\n" + "="*80)
    print("🔐 AUTH.USERS TABLE (Supabase Auth)")
    print("="*80)
    
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'auth' 
            AND table_name = 'users'
        );
    """)
    
    auth_users_exists = cur.fetchone()[0]
    
    if auth_users_exists:
        print("\n✅ auth.users table EXISTS")
        
        # Count auth users
        cur.execute("SELECT COUNT(*) FROM auth.users;")
        auth_user_count = cur.fetchone()[0]
        print(f"📊 Total users in auth.users: {auth_user_count}")
        
        if auth_user_count > 0:
            # Show sample auth users
            cur.execute("SELECT id, email, created_at FROM auth.users LIMIT 5;")
            print("\nSample auth users:")
            for row in cur.fetchall():
                print(f"  - {row[0]} | {row[1]} | {row[2]}")
    else:
        print("\n❌ auth.users table DOES NOT EXIST!")
    
    # Check the specific foreign key that's failing
    print("\n" + "="*80)
    print("🔍 CHECKING SPECIFIC FOREIGN KEY: tasks_assigned_to_key")
    print("="*80)
    
    cur.execute("""
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_name = 'tasks_assigned_to_key'
        AND tc.table_schema = 'public';
    """)
    
    result = cur.fetchone()
    if result:
        const_name, column, fk_schema, fk_table, fk_column = result
        print(f"\n✅ Found constraint: {const_name}")
        print(f"   Column: {column}")
        print(f"   References: {fk_schema}.{fk_table}.{fk_column}")
        
        # Check if the referenced table exists
        cur.execute(f"""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = '{fk_schema}' 
                AND table_name = '{fk_table}'
            );
        """)
        ref_table_exists = cur.fetchone()[0]
        print(f"   Referenced table exists: {ref_table_exists}")
    else:
        print("\n❌ Constraint 'tasks_assigned_to_key' NOT FOUND")
    
    cur.close()
    conn.close()
    
    print("\n" + "="*80)
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
