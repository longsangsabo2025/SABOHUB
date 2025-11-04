"""
Check and fix trigger/function issues
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

def fix_trigger():
    """Check and fix trigger"""
    print("\n" + "="*60)
    print("DIAGNOSING AND FIXING TRIGGER ISSUE")
    print("="*60)
    
    conn_str = get_connection_string()
    
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # Get current function definition
        print("\n🔵 Checking current function definition...")
        cur.execute("""
            SELECT routine_definition
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'handle_new_user';
        """)
        
        func_def = cur.fetchone()
        if func_def:
            print("Current function:")
            print(func_def[0][:500])
            
        # Drop and recreate trigger with correct definition
        print("\n🔵 Recreating trigger...")
        
        # Drop existing trigger
        cur.execute("""
            DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
        """)
        print("✅ Dropped old trigger")
        
        # Drop old function
        cur.execute("""
            DROP FUNCTION IF EXISTS public.handle_new_user();
        """)
        print("✅ Dropped old function")
        
        # Create new function that matches auth.users structure
        cur.execute("""
            CREATE OR REPLACE FUNCTION public.handle_new_user()
            RETURNS trigger
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            BEGIN
              -- Insert into public.users with data from auth.users
              INSERT INTO public.users (
                id,
                email,
                full_name,
                phone,
                role,
                avatar_url
              )
              VALUES (
                NEW.id,
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', ''),
                COALESCE(NEW.raw_user_meta_data->>'phone', ''),
                COALESCE(NEW.raw_user_meta_data->>'role', 'STAFF'),
                COALESCE(NEW.raw_user_meta_data->>'avatar_url', '')
              );
              
              RETURN NEW;
            EXCEPTION
              WHEN OTHERS THEN
                -- Log error but don't fail the signup
                RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
                RETURN NEW;
            END;
            $$;
        """)
        print("✅ Created new function")
        
        # Create trigger
        cur.execute("""
            CREATE TRIGGER on_auth_user_created
              AFTER INSERT ON auth.users
              FOR EACH ROW
              EXECUTE FUNCTION public.handle_new_user();
        """)
        print("✅ Created new trigger")
        
        # Commit changes
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
                COALESCE(au.raw_user_meta_data->>'role', 'STAFF'),
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
        
        # Show sample
        cur.execute("""
            SELECT id, email, full_name, role 
            FROM public.users 
            ORDER BY created_at DESC 
            LIMIT 5;
        """)
        users = cur.fetchall()
        print("\n🔵 Sample users:")
        for user in users:
            print(f"  - {user[1]} | {user[2]} | {user[3]}")
        
        cur.close()
        conn.close()
        
        print("\n" + "="*60)
        print("✅ TRIGGER FIXED AND USERS BACKFILLED!")
        print("="*60)
        print("\n✅ New signups will now automatically create profiles")
        print("✅ Existing users have been backfilled")
        print("\n")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        if conn:
            conn.rollback()

if __name__ == "__main__":
    fix_trigger()
