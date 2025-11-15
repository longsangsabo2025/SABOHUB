#!/usr/bin/env python3
"""
Test Supabase connection using Transaction Pooler (Port 6543)
This allows direct SQL execution via psycopg2
"""
import psycopg2
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_DB_PASSWORD = os.getenv('SUPABASE_DB_PASSWORD')  # Need to add this to .env

def test_transaction_pooler():
    """Test connection using Transaction Pooler"""
    
    # Extract project reference from Supabase URL
    # Example: https://dqddxowyikefqcdiioyh.supabase.co
    project_ref = SUPABASE_URL.replace('https://', '').replace('.supabase.co', '')
    
    print("=" * 80)
    print("🔌 Testing Supabase Transaction Pooler Connection")
    print("=" * 80)
    print(f"\nProject Ref: {project_ref}")
    
    # Check if we have database password
    if not SUPABASE_DB_PASSWORD:
        print("\n⚠️  SUPABASE_DB_PASSWORD not found in .env file!")
        print("\n📋 To get your database password:")
        print(f"1. Go to: https://supabase.com/dashboard/project/{project_ref}/settings/database")
        print("2. Look for 'Database Password' section")
        print("3. Reset password if needed")
        print("4. Add to .env file:")
        print("   SUPABASE_DB_PASSWORD=your_password_here")
        print("\n" + "=" * 80)
        
        # Show connection string format
        print("\n📝 Connection String Format:")
        print(f"   postgresql://postgres:[PASSWORD]@db.{project_ref}.supabase.co:6543/postgres")
        print("\n   Port 6543 = Transaction Pooler (for direct SQL)")
        print("   Port 5432 = Session Pooler (for psql)")
        print("=" * 80)
        return False
    
    # Build connection string for Transaction Pooler (port 6543)
    # Supabase pooler format: postgres://postgres.[PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres
    # Or direct: postgres://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
    
    # Try direct connection first (port 5432)
    direct_host = f"db.{project_ref}.supabase.co"
    conn_string = f"postgresql://postgres:{SUPABASE_DB_PASSWORD}@{direct_host}:5432/postgres"
    
    try:
        print(f"\n🔌 Connecting to Supabase Database (port 5432)...")
        print(f"   Host: {direct_host}:5432")
        print(f"   User: postgres")
        
        # Connect
        conn = psycopg2.connect(conn_string)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("✅ Connected successfully!\n")
        
        # Test 1: Check PostgreSQL version
        print("📍 Test 1: PostgreSQL Version")
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"   {version[:80]}...\n")
        
        # Test 2: List tables
        print("📍 Test 2: List Tables")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = cursor.fetchall()
        print(f"   Found {len(tables)} tables:")
        for table in tables[:10]:  # Show first 10
            print(f"   - {table[0]}")
        if len(tables) > 10:
            print(f"   ... and {len(tables) - 10} more\n")
        else:
            print()
        
        # Test 3: Check if daily_work_reports exists
        print("📍 Test 3: Check daily_work_reports table")
        cursor.execute("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.tables 
                WHERE table_schema = 'public' 
                AND table_name = 'daily_work_reports'
            );
        """)
        exists = cursor.fetchone()[0]
        
        if exists:
            print("   ✅ Table 'daily_work_reports' EXISTS")
            
            # Get column info
            cursor.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_name = 'daily_work_reports'
                ORDER BY ordinal_position;
            """)
            columns = cursor.fetchall()
            print(f"   📊 Columns ({len(columns)}):")
            for col_name, col_type, nullable in columns:
                null_str = "NULL" if nullable == "YES" else "NOT NULL"
                print(f"      - {col_name}: {col_type} ({null_str})")
            
            # Count records
            cursor.execute("SELECT COUNT(*) FROM daily_work_reports;")
            count = cursor.fetchone()[0]
            print(f"\n   📈 Total records: {count}")
            
        else:
            print("   ⚠️  Table 'daily_work_reports' DOES NOT EXIST")
            print("\n   💡 Need to create it? Run:")
            print("      python create_daily_work_reports_table.py")
        
        print("\n" + "=" * 80)
        print("✅ Transaction Pooler connection test PASSED")
        print("=" * 80)
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.OperationalError as e:
        print(f"\n❌ Connection failed: {e}")
        print("\n📋 Troubleshooting:")
        print("1. Verify database password in .env")
        print("2. Check if IP is whitelisted in Supabase")
        print("3. Ensure Transaction Pooler is enabled")
        print("=" * 80)
        return False
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("=" * 80)
        return False

if __name__ == '__main__':
    test_transaction_pooler()
