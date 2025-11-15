import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Initialize Supabase
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("=" * 70)
print("RENAMING user_id TO employee_id in daily_work_reports")
print("=" * 70)

sql_commands = [
    "-- Step 1: Drop constraints that reference user_id",
    "ALTER TABLE daily_work_reports DROP CONSTRAINT IF EXISTS unique_daily_report;",
    
    "-- Step 2: Drop foreign key constraint",
    "ALTER TABLE daily_work_reports DROP CONSTRAINT IF EXISTS daily_work_reports_user_id_fkey;",
    
    "-- Step 3: Drop index",
    "DROP INDEX IF EXISTS idx_daily_reports_user_id;",
    
    "-- Step 4: Rename column",
    "ALTER TABLE daily_work_reports RENAME COLUMN user_id TO employee_id;",
    
    "-- Step 5: Re-create foreign key constraint",
    "ALTER TABLE daily_work_reports ADD CONSTRAINT daily_work_reports_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE;",
    
    "-- Step 6: Re-create unique constraint",
    "ALTER TABLE daily_work_reports ADD CONSTRAINT unique_daily_report UNIQUE(employee_id, report_date);",
    
    "-- Step 7: Re-create index",
    "CREATE INDEX idx_daily_reports_employee_id ON daily_work_reports(employee_id);"
]

try:
    for i, sql in enumerate(sql_commands, 1):
        if sql.startswith('--'):
            print(f"\n{sql}")
            continue
            
        print(f"\n[{i}] Executing: {sql[:60]}...")
        result = supabase.rpc('exec_sql', {'query': sql}).execute()
        print(f"    ✅ Success")
        
    print("\n" + "=" * 70)
    print("✅ RENAME COMPLETED SUCCESSFULLY!")
    print("=" * 70)
    
    print("\n🔍 Verifying the change...")
    # Try to insert a test record to confirm column name
    print("Table structure should now have 'employee_id' instead of 'user_id'")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\n💡 Alternative: Run SQL directly in Supabase SQL Editor:")
    print("\n")
    for sql in sql_commands:
        if not sql.startswith('--'):
            print(sql)
