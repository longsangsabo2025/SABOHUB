"""
Create accounting_transactions table
"""
import os
from dotenv import load_dotenv

load_dotenv()

def create_accounting_table():
    print("🔧 Migration: Create accounting_transactions table")
    print("=" * 60)
    
    # Read SQL file
    with open('create_accounting_table.sql', 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print("\n📋 SQL to execute:")
    print(sql_content[:500] + "..." if len(sql_content) > 500 else sql_content)
    print("\n" + "=" * 60)
    
    # Try to execute using psycopg2
    try:
        import psycopg2
        
        conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
        if not conn_string:
            print("\n⚠️  SUPABASE_CONNECTION_STRING not found in .env")
            print("\n📝 Please run the SQL manually in Supabase SQL Editor")
            return
        
        print("\n🔗 Connecting to database...")
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        print("✅ Connected!")
        print("🚀 Executing SQL...")
        
        cursor.execute(sql_content)
        conn.commit()
        
        print("✅ Migration completed successfully!")
        print("💰 accounting_transactions table has been created")
        print("🔒 RLS policies have been enabled")
        
        cursor.close()
        conn.close()
        
    except ImportError:
        print("\n⚠️  psycopg2 not installed")
        print("\n📝 Please run the SQL manually in Supabase SQL Editor")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\n📝 Please run the SQL manually in Supabase SQL Editor")

if __name__ == '__main__':
    create_accounting_table()
