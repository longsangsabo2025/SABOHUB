import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Get connection string
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")
db_password = os.environ.get("SUPABASE_DB_PASSWORD")

print("🚀 RUNNING ATTENDANCE SCHEMA MIGRATION")
print("=" * 80)

# Read migration file
migration_file = "supabase/migrations/20251113_fix_attendance_schema.sql"
with open(migration_file, 'r', encoding='utf-8') as f:
    migration_sql = f.read()

print(f"📄 Loaded migration: {migration_file}")
print("=" * 80)

try:
    # Connect to database
    print("\n⚡ Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = False
    cursor = conn.cursor()
    
    print("✅ Connected!")
    print("\n⚡ Executing migration...")
    print("-" * 80)
    
    # Execute migration
    cursor.execute(migration_sql)
    
    # Commit transaction
    conn.commit()
    
    print("\n✅ MIGRATION COMPLETED SUCCESSFULLY!")
    print("=" * 80)
    
    # Verify results
    print("\n📊 Verification:")
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            COUNT(branch_id) as with_branch,
            COUNT(company_id) as with_company,
            COUNT(deleted_at) as deleted
        FROM attendance
    """)
    
    result = cursor.fetchone()
    print(f"  Total records: {result[0]}")
    print(f"  With branch_id: {result[1]}")
    print(f"  With company_id: {result[2]}")
    print(f"  Soft deleted: {result[3]}")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 80)
    print("✅ ALL DONE! Attendance schema fixed successfully")
    print("=" * 80)
    
except psycopg2.Error as e:
    print(f"\n❌ Database Error: {e}")
    if conn:
        conn.rollback()
        conn.close()
except Exception as e:
    print(f"\n❌ Error: {e}")
    if conn:
        conn.rollback()
        conn.close()
