"""
SABOHUB - Automatic Database Setup Script
Automatically runs SQL setup on Supabase to enable user signup
"""

import os
import sys
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

def run_sql_file(file_path: str):
    """Execute SQL file on Supabase database"""
    print(f"\n🔵 Reading SQL file: {file_path}")
    
    # Read SQL file
    sql_path = Path(file_path)
    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file not found: {file_path}")
    
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"📄 SQL file loaded ({len(sql_content)} characters)")
    
    # Connect to database
    print("\n🔵 Connecting to Supabase database...")
    conn_str = get_connection_string()
    
    try:
        conn = psycopg2.connect(conn_str)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("✅ Connected to database successfully")
        
        # Execute SQL
        print("\n🔵 Executing SQL setup...")
        cur.execute(sql_content)
        
        print("✅ SQL executed successfully!")
        
        # Verify setup
        print("\n🔵 Verifying setup...")
        
        # Check users table
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'users'
            );
        """)
        table_exists = cur.fetchone()[0]
        
        if table_exists:
            print("✅ Users table created")
            
            # Check RLS policies
            cur.execute("""
                SELECT COUNT(*) FROM pg_policies 
                WHERE tablename = 'users';
            """)
            policy_count = cur.fetchone()[0]
            print(f"✅ {policy_count} RLS policies configured")
            
            # Check triggers
            cur.execute("""
                SELECT COUNT(*) FROM information_schema.triggers 
                WHERE event_object_table = 'users';
            """)
            trigger_count = cur.fetchone()[0]
            print(f"✅ {trigger_count} triggers configured")
            
            print("\n" + "="*60)
            print("🎉 DATABASE SETUP COMPLETE!")
            print("="*60)
            print("\n✅ You can now test the signup flow in your app")
            print("✅ Users will automatically get a profile created on signup")
            print("✅ RLS policies are protecting user data")
            print("\n")
            
        else:
            print("❌ Users table not found - setup may have failed")
            return False
        
        cur.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ Database error: {e}")
        print(f"Error code: {e.pgcode}")
        return False
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return False

def main():
    """Main execution function"""
    print("\n" + "="*60)
    print("SABOHUB - Database Setup for User Authentication")
    print("="*60)
    
    # Get SQL file path
    sql_file = Path(__file__).parent / 'setup_auth_users.sql'
    
    try:
        success = run_sql_file(sql_file)
        
        if success:
            sys.exit(0)
        else:
            print("\n❌ Setup failed. Please check the errors above.")
            sys.exit(1)
            
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
