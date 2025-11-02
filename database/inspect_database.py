#!/usr/bin/env python3
"""
🔍 SUPABASE DATABASE INSPECTOR
Kiểm tra cấu trúc database hiện tại để hiểu những gì đã có
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
import json

# Load environment variables
from dotenv import load_dotenv
load_dotenv()

def connect_to_supabase():
    """Kết nối đến Supabase database"""
    connection_string = os.getenv('SUPABASE_CONNECTION_STRING')
    if not connection_string:
        print("❌ SUPABASE_CONNECTION_STRING not found in .env")
        return None
    
    try:
        conn = psycopg2.connect(connection_string)
        print("✅ Connected to Supabase database")
        return conn
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return None

def inspect_database(conn):
    """Kiểm tra cấu trúc database"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        print("\n" + "="*60)
        print("📊 SUPABASE DATABASE INSPECTION")
        print("="*60)
        
        # 1. List all tables
        print("\n🔍 ALL TABLES:")
        cur.execute("""
            SELECT schemaname, tablename, tableowner 
            FROM pg_tables 
            WHERE schemaname IN ('public', 'auth') 
            ORDER BY schemaname, tablename;
        """)
        tables = cur.fetchall()
        
        if not tables:
            print("❌ No tables found!")
            return
        
        for table in tables:
            print(f"  📋 {table['schemaname']}.{table['tablename']}")
        
        # 2. Check specific tables we need
        required_tables = ['companies', 'users', 'stores', 'tables', 'tasks', 'activity_logs']
        print(f"\n🎯 CHECKING REQUIRED TABLES:")
        
        existing_tables = []
        missing_tables = []
        
        for table_name in required_tables:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = %s
                );
            """, (table_name,))
            
            exists = cur.fetchone()['exists']
            if exists:
                existing_tables.append(table_name)
                print(f"  ✅ {table_name}")
            else:
                missing_tables.append(table_name)
                print(f"  ❌ {table_name}")
        
        # 3. Inspect existing table structures
        if existing_tables:
            print(f"\n📋 TABLE STRUCTURES:")
            for table_name in existing_tables:
                print(f"\n  🔍 {table_name}:")
                cur.execute("""
                    SELECT column_name, data_type, is_nullable, column_default
                    FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = %s
                    ORDER BY ordinal_position;
                """, (table_name,))
                
                columns = cur.fetchall()
                for col in columns:
                    nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                    default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
                    print(f"    📌 {col['column_name']}: {col['data_type']} {nullable}{default}")
        
        # 4. Check sample data
        if existing_tables:
            print(f"\n📊 SAMPLE DATA:")
            for table_name in existing_tables[:3]:  # Only check first 3 tables
                try:
                    cur.execute(f"SELECT COUNT(*) as count FROM {table_name};")
                    count = cur.fetchone()['count']
                    print(f"  📈 {table_name}: {count} rows")
                    
                    if count > 0:
                        cur.execute(f"SELECT * FROM {table_name} LIMIT 2;")
                        samples = cur.fetchall()
                        for i, row in enumerate(samples, 1):
                            print(f"    🔸 Row {i}: {dict(row)}")
                except Exception as e:
                    print(f"    ⚠️ Error reading {table_name}: {e}")
        
        # 5. Summary
        print(f"\n📊 SUMMARY:")
        print(f"  ✅ Existing tables: {len(existing_tables)}")
        print(f"  ❌ Missing tables: {len(missing_tables)}")
        
        if missing_tables:
            print(f"  🚨 Need to create: {', '.join(missing_tables)}")
        else:
            print(f"  🎉 All required tables exist!")
        
        return {
            'existing_tables': existing_tables,
            'missing_tables': missing_tables,
            'all_tables': [f"{t['schemaname']}.{t['tablename']}" for t in tables]
        }

def main():
    """Main function"""
    print("🚀 Starting Supabase Database Inspection...")
    
    conn = connect_to_supabase()
    if not conn:
        return
    
    try:
        result = inspect_database(conn)
        
        # Save result to file
        with open('database/database_inspection.json', 'w') as f:
            json.dump(result, f, indent=2)
        
        print(f"\n💾 Inspection result saved to: database/database_inspection.json")
        
    except Exception as e:
        print(f"❌ Inspection failed: {e}")
    finally:
        conn.close()
        print("🔌 Database connection closed")

if __name__ == "__main__":
    main()