#!/usr/bin/env python3
"""
🤖 Auto-apply AI Assistant Migration to Supabase
"""

import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def main():
    print("🔄 Applying AI Assistant Migration...")
    print()
    
    # Get connection string
    conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
    if not conn_string:
        print("❌ Missing SUPABASE_CONNECTION_STRING in .env")
        return 1
    
    # Read SQL file
    sql_file = "supabase/migrations/20251102_ai_assistant_tables_fixed.sql"
    try:
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        print(f"✅ SQL file loaded: {sql_file}")
        print(f"📊 SQL size: {len(sql_content)} bytes")
        print()
    except FileNotFoundError:
        print(f"❌ Migration file not found: {sql_file}")
        return 1
    
    # Connect to database
    print("🔌 Connecting to database...")
    try:
        conn = psycopg2.connect(conn_string)
        conn.autocommit = False
        cursor = conn.cursor()
        print("✅ Connected successfully")
        print()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return 1
    
    # Execute migration
    print("🚀 Executing migration...")
    try:
        cursor.execute(sql_content)
        conn.commit()
        print("✅ Migration executed successfully!")
        print()
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        conn.rollback()
        return 1
    finally:
        cursor.close()
        conn.close()
    
    # Verify tables
    print("🔍 Verifying tables...")
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        tables = [
            'ai_assistants',
            'ai_conversations',
            'ai_messages',
            'ai_files',
            'ai_usage_analytics'
        ]
        
        for table in tables:
            cursor.execute(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = '{table}'
                );
            """)
            exists = cursor.fetchone()[0]
            status = "✅" if exists else "❌"
            print(f"  {status} {table}")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"⚠️ Verification failed: {e}")
    
    print()
    print("🔍 Verifying functions...")
    try:
        conn = psycopg2.connect(conn_string)
        cursor = conn.cursor()
        
        functions = [
            'get_or_create_ai_assistant',
            'get_ai_total_cost',
            'get_ai_usage_stats'
        ]
        
        for func in functions:
            cursor.execute(f"""
                SELECT EXISTS (
                    SELECT FROM pg_proc 
                    WHERE proname = '{func}'
                );
            """)
            exists = cursor.fetchone()[0]
            status = "✅" if exists else "❌"
            print(f"  {status} {func}")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"⚠️ Function verification failed: {e}")
    
    print()
    print("✅ AI Assistant migration completed!")
    print("🤖 Your app can now use AI features!")
    return 0

if __name__ == "__main__":
    exit(main())
