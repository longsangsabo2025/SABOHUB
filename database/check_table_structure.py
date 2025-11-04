"""
Check actual table structure in database
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

def check_structure():
    """Check table structure"""
    print("\n" + "="*60)
    print("CHECKING TABLE STRUCTURE")
    print("="*60)
    
    conn_str = get_connection_string()
    
    try:
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        # Check if public.users table exists
        print("\n🔵 Checking if public.users table exists...")
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'users'
            );
        """)
        exists = cur.fetchone()[0]
        
        if exists:
            print("✅ Table public.users EXISTS")
            
            # Get columns
            print("\n🔵 Table columns:")
            cur.execute("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public' 
                AND table_name = 'users'
                ORDER BY ordinal_position;
            """)
            
            columns = cur.fetchall()
            for col in columns:
                print(f"  - {col[0]}: {col[1]} | Nullable: {col[2]} | Default: {col[3]}")
                
            # Count rows
            print("\n🔵 Row count:")
            cur.execute("SELECT COUNT(*) FROM public.users;")
            count = cur.fetchone()[0]
            print(f"  Total rows: {count}")
            
            if count > 0:
                # Show sample data
                print("\n🔵 Sample data (first 5 rows):")
                cur.execute("SELECT * FROM public.users LIMIT 5;")
                rows = cur.fetchall()
                for row in rows:
                    print(f"  {row}")
        else:
            print("❌ Table public.users DOES NOT EXIST!")
            print("\n   → Need to create the table")
            print("   → Run: python database/setup_database.py")
            
        # Check triggers
        print("\n🔵 Checking triggers on auth.users...")
        cur.execute("""
            SELECT trigger_name, event_manipulation, action_statement
            FROM information_schema.triggers 
            WHERE event_object_table = 'users'
            AND trigger_schema = 'auth';
        """)
        
        triggers = cur.fetchall()
        if triggers:
            print(f"✅ Found {len(triggers)} triggers:")
            for trigger in triggers:
                print(f"  - {trigger[0]}: {trigger[1]}")
        else:
            print("❌ No triggers found on auth.users")
            
        # Check function
        print("\n🔵 Checking handle_new_user function...")
        cur.execute("""
            SELECT routine_name, routine_definition
            FROM information_schema.routines
            WHERE routine_schema = 'public'
            AND routine_name = 'handle_new_user';
        """)
        
        func = cur.fetchone()
        if func:
            print("✅ Function handle_new_user EXISTS")
        else:
            print("❌ Function handle_new_user DOES NOT EXIST")
            
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")

if __name__ == "__main__":
    check_structure()
