"""
Fix role constraint and backfill users properly
"""

import os
from pathlib import Path
import psycopg2
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

def get_connection_string():
    """Get database connection string from environment"""
    conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_str:
        raise ValueError("SUPABASE_CONNECTION_STRING not found in .env file")
    return conn_str

def fix_role_constraint():
    """Fix role constraint and backfill"""
    print("\n" + "="*60)
    print("FIXING ROLE CONSTRAINT AND BACKFILLING")
    print("="*60)
    
    conn_str = get_connection_string()
    
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # Check current constraints
        print("\n🔵 Checking current constraints...")
        cur.execute("""
            SELECT constraint_name, check_clause
            FROM information_schema.check_constraints
            WHERE constraint_schema = 'public'
            AND constraint_name LIKE '%role%';
        """)
        
        constraints = cur.fetchall()
        for const in constraints:
            print(f"  - {const[0]}: {const[1]}")
            
        # Drop role constraint if exists
        print("\n🔵 Dropping role constraint...")
        cur.execute("""
            ALTER TABLE public.users 
            DROP CONSTRAINT IF EXISTS users_role_check;
        """)
        print("✅ Dropped role constraint")
        
        # Add new constraint that accepts uppercase roles
        print("\n🔵 Adding new role constraint...")
        cur.execute("""
            ALTER TABLE public.users 
            ADD CONSTRAINT users_role_check 
            CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF'));
        """)
        print("✅ Added new role constraint (accepts uppercase)")
        
        conn.commit()
        
        # Now backfill existing users
        print("\n🔵 Backfilling existing users...")
        cur.execute("""
            INSERT INTO public.users (
                id,
                email,
                full_name,
                phone,
                role,
                avatar_url
            )
            SELECT 
                au.id,
                au.email,
                COALESCE(au.raw_user_meta_data->>'name', au.raw_user_meta_data->>'full_name', ''),
                COALESCE(au.raw_user_meta_data->>'phone', ''),
                UPPER(COALESCE(au.raw_user_meta_data->>'role', 'STAFF')),
                COALESCE(au.raw_user_meta_data->>'avatar_url', '')
            FROM auth.users au
            WHERE NOT EXISTS (
                SELECT 1 FROM public.users pu WHERE pu.id = au.id
            );
        """)
        
        rows_inserted = cur.rowcount
        conn.commit()
        print(f"✅ Backfilled {rows_inserted} users")
        
        # Verify
        print("\n🔵 Verifying...")
        cur.execute("SELECT COUNT(*) FROM public.users;")
        count = cur.fetchone()[0]
        print(f"✅ public.users now has {count} rows")
        
        # Show all users
        cur.execute("""
            SELECT 
                u.email, 
                u.full_name, 
                u.role,
                u.phone,
                u.created_at
            FROM public.users u
            ORDER BY u.created_at DESC;
        """)
        users = cur.fetchall()
        print(f"\n🔵 All {len(users)} users:")
        for user in users:
            print(f"  - {user[0]}")
            print(f"    Name: {user[1]}")
            print(f"    Role: {user[2]}")
            print(f"    Phone: {user[3]}")
            print(f"    Created: {user[4]}")
            print()
        
        cur.close()
        conn.close()
        
        print("="*60)
        print("✅ CONSTRAINT FIXED AND USERS BACKFILLED!")
        print("="*60)
        print("\n✅ New signups will now automatically create profiles")
        print("✅ All existing users have been backfilled")
        print("✅ Login should now work for all users")
        print("\n")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        if conn:
            conn.rollback()

if __name__ == "__main__":
    fix_role_constraint()
