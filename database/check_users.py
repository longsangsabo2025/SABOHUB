"""
Check if signup is working - verify users in database
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

def check_users():
    """Check users in database"""
    print("\n" + "="*60)
    print("CHECKING USERS IN DATABASE")
    print("="*60)
    
    conn_str = get_connection_string()
    
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # Check auth.users
        print("\n🔵 Checking auth.users (Supabase Auth)...")
        cur.execute("""
            SELECT id, email, created_at, 
                   raw_user_meta_data->>'name' as name,
                   raw_user_meta_data->>'role' as role
            FROM auth.users 
            ORDER BY created_at DESC 
            LIMIT 10;
        """)
        
        auth_users = cur.fetchall()
        if auth_users:
            print(f"✅ Found {len(auth_users)} users in auth.users:")
            for user in auth_users:
                print(f"  - ID: {user[0][:8]}... | Email: {user[1]} | Name: {user[3]} | Role: {user[4]} | Created: {user[2]}")
        else:
            print("❌ No users found in auth.users")
        
        # Check public.users
        print("\n🔵 Checking public.users (User Profiles)...")
        cur.execute("""
            SELECT id, name, email, role, phone, created_at 
            FROM public.users 
            ORDER BY created_at DESC 
            LIMIT 10;
        """)
        
        public_users = cur.fetchall()
        if public_users:
            print(f"✅ Found {len(public_users)} users in public.users:")
            for user in public_users:
                print(f"  - ID: {user[0][:8]}... | Name: {user[1]} | Email: {user[2]} | Role: {user[3]} | Phone: {user[4]} | Created: {user[5]}")
        else:
            print("❌ No users found in public.users")
            
        # Check trigger exists
        print("\n🔵 Checking trigger...")
        cur.execute("""
            SELECT trigger_name, event_manipulation, action_statement
            FROM information_schema.triggers 
            WHERE event_object_table = 'users'
            AND trigger_schema = 'auth';
        """)
        
        triggers = cur.fetchall()
        if triggers:
            print(f"✅ Found {len(triggers)} triggers on auth.users:")
            for trigger in triggers:
                print(f"  - {trigger[0]}: {trigger[1]} → {trigger[2][:50]}...")
        else:
            print("❌ No triggers found on auth.users")
            
        # Check if function exists
        print("\n🔵 Checking handle_new_user function...")
        cur.execute("""
            SELECT routine_name, routine_type
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'handle_new_user';
        """)
        
        functions = cur.fetchall()
        if functions:
            print("✅ Function handle_new_user exists")
        else:
            print("❌ Function handle_new_user NOT found")
            
        cur.close()
        conn.close()
        
        # Summary
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Auth users: {len(auth_users) if auth_users else 0}")
        print(f"Public users: {len(public_users) if public_users else 0}")
        print(f"Triggers: {len(triggers) if triggers else 0}")
        print(f"Functions: {len(functions) if functions else 0}")
        
        if auth_users and not public_users:
            print("\n⚠️  WARNING: Auth users exist but no public profiles!")
            print("   → Trigger may not be working")
            print("   → Run: python database/fix_trigger.py")
        elif not auth_users:
            print("\n⚠️  No signup attempts found")
            print("   → Try signing up in the app")
        else:
            print("\n✅ Everything looks good!")
        
        print("\n")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    check_users()
