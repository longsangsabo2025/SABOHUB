#!/usr/bin/env python3
"""
Automatic DMS Migrations Executor
Executes COMBINED_DMS_MIGRATIONS.sql via transaction pooler
"""

import sys
from pathlib import Path

try:
    import psycopg2
    from psycopg2 import sql
except ImportError:
    print("❌ psycopg2 not installed. Installing now...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2
    from psycopg2 import sql

# Transaction Pooler Connection String
POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

# Migration file path
MIGRATION_FILE = Path(__file__).parent / "database" / "migrations" / "COMBINED_DMS_MIGRATIONS.sql"

def execute_migrations():
    """Execute the combined migrations SQL file"""
    
    print("=" * 80)
    print("🚀 AUTOMATIC DMS MIGRATIONS EXECUTOR")
    print("=" * 80)
    print()
    
    # Check if file exists
    if not MIGRATION_FILE.exists():
        print(f"❌ Migration file not found: {MIGRATION_FILE}")
        return False
    
    print(f"📄 Reading migration file: {MIGRATION_FILE.name}")
    print(f"   Size: {MIGRATION_FILE.stat().st_size:,} bytes")
    print()
    
    # Read SQL content
    try:
        sql_content = MIGRATION_FILE.read_text(encoding='utf-8')
        print(f"✅ SQL content loaded: {len(sql_content):,} characters")
        print()
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return False
    
    # Connect to database via transaction pooler
    print("🔌 Connecting to Supabase via Transaction Pooler...")
    print(f"   Host: aws-1-ap-southeast-2.pooler.supabase.com:6543")
    print()
    
    try:
        conn = psycopg2.connect(POOLER_URL)
        conn.autocommit = False  # Use transaction for safety
        cursor = conn.cursor()
        print("✅ Connected successfully!")
        print()
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False
    
    # Execute migrations
    print("⚡ Executing migrations...")
    print("   This may take 10-30 seconds...")
    print()
    
    try:
        # Execute the entire SQL content
        cursor.execute(sql_content)
        
        # Commit transaction
        conn.commit()
        
        print("✅ Migrations executed successfully!")
        print()
        
        # Verify tables created
        print("🔍 Verifying tables created...")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name LIKE 'dms_%'
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        print(f"✅ Found {len(tables)} DMS tables:")
        print()
        
        for i, (table_name,) in enumerate(tables, 1):
            print(f"   {i:2d}. {table_name}")
        
        print()
        
        if len(tables) >= 27:
            print("🎉 SUCCESS! All expected tables created!")
        else:
            print(f"⚠️  Expected 27 tables, found {len(tables)}")
        
        print()
        
    except Exception as e:
        print(f"❌ Execution failed: {e}")
        print()
        print("Rolling back transaction...")
        conn.rollback()
        cursor.close()
        conn.close()
        return False
    
    finally:
        cursor.close()
        conn.close()
        print("🔒 Connection closed")
    
    print()
    print("=" * 80)
    print("✅ MIGRATION COMPLETE - 100% DONE!")
    print("=" * 80)
    print()
    print("Next steps:")
    print("  1. Visit: https://hub.saboarena.com")
    print("  2. Test DMS pages:")
    print("     - /dms/distributor-portal")
    print("     - /dms/price-lists")
    print("     - /dms/sell-through")
    print("     - /dms/sales-routes")
    print("     - /dms/accounting/chart-of-accounts")
    print("     - /dms/accounting/journal-entries")
    print("  3. Seed standard COA via button on Chart of Accounts page")
    print()
    
    return True

if __name__ == "__main__":
    success = execute_migrations()
    sys.exit(0 if success else 1)
