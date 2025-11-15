import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Get connection string from .env
conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("=" * 70)
print("RENAMING user_id TO employee_id in daily_work_reports")
print("=" * 70)

sql_commands = [
    # Step 1: Drop constraints
    "ALTER TABLE daily_work_reports DROP CONSTRAINT IF EXISTS unique_daily_report;",
    "ALTER TABLE daily_work_reports DROP CONSTRAINT IF EXISTS daily_work_reports_user_id_fkey;",
    
    # Step 2: Drop index
    "DROP INDEX IF EXISTS idx_daily_reports_user_id;",
    
    # Step 3: Rename column
    "ALTER TABLE daily_work_reports RENAME COLUMN user_id TO employee_id;",
    
    # Step 4: Re-create foreign key
    "ALTER TABLE daily_work_reports ADD CONSTRAINT daily_work_reports_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;",
    
    # Step 5: Re-create unique constraint
    "ALTER TABLE daily_work_reports ADD CONSTRAINT unique_daily_report UNIQUE(employee_id, report_date);",
    
    # Step 6: Re-create index
    "CREATE INDEX idx_daily_reports_employee_id ON daily_work_reports(employee_id);"
]

try:
    print("\n🔌 Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cur = conn.cursor()
    print("✅ Connected!")
    
    print("\n🔄 Executing SQL commands...")
    
    for i, sql in enumerate(sql_commands, 1):
        print(f"\n[{i}/{len(sql_commands)}] {sql[:70]}...")
        cur.execute(sql)
        print("    ✅ Success")
        
    cur.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ COLUMN RENAMED SUCCESSFULLY!")
    print("=" * 70)
    print("\n📋 Summary:")
    print("  • Dropped old constraints and index")
    print("  • Renamed: user_id → employee_id")
    print("  • Re-created foreign key to employees(id)")
    print("  • Re-created unique constraint on (employee_id, report_date)")
    print("  • Re-created index on employee_id")
    print("\n🎉 All Flutter code is now ready to use!")
    
except psycopg2.Error as e:
    print(f"\n❌ Database Error: {e}")
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\n💡 Make sure psycopg2 is installed: pip install psycopg2-binary")
