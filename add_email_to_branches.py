"""
Add email column to branches table
"""
import os
from dotenv import load_dotenv

load_dotenv()

def add_email_to_branches():
    print("🔧 Migration: Add email column to branches table")
    print("=" * 60)
    
    # Read SQL file
    with open('add_email_to_branches.sql', 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print("\n📋 SQL to execute:")
    print(sql_content)
    print("\n" + "=" * 60)
    
    # Try to execute using psycopg2 if connection string is available
    try:
        import psycopg2
        
        conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
        if not conn_string:
            print("\n⚠️  SUPABASE_CONNECTION_STRING not found in .env")
            print("\n📝 Please run the SQL above manually in Supabase SQL Editor:")
            print("   1. Go to Supabase Dashboard")
            print("   2. Open SQL Editor")
            print("   3. Copy and paste the SQL above")
            print("   4. Click 'Run'")
            return
        
        print("\n🔗 Connecting to database...")
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        print("✅ Connected!")
        print("🚀 Executing SQL...")
        
        cursor.execute(sql_content)
        conn.commit()
        
        print("✅ Migration completed successfully!")
        print("📧 Email column has been added to branches table")
        
        cursor.close()
        conn.close()
        
    except ImportError:
        print("\n⚠️  psycopg2 not installed")
        print("\n📝 Please run the SQL manually in Supabase SQL Editor:")
        print(sql_content)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\n📝 Please run the SQL manually in Supabase SQL Editor:")
        print(sql_content)

if __name__ == '__main__':
    add_email_to_branches()
