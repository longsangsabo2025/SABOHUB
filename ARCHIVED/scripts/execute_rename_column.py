import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Initialize Supabase with SERVICE_ROLE_KEY to bypass RLS
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

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
    print("\n🔄 Executing SQL commands...")
    
    for i, sql in enumerate(sql_commands, 1):
        print(f"\n[{i}/{len(sql_commands)}] {sql[:70]}...")
        
        # Use postgrest to execute raw SQL
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print(f"    ✅ Success")
        
    print("\n" + "=" * 70)
    print("✅ COLUMN RENAMED SUCCESSFULLY!")
    print("=" * 70)
    
    # Verify
    print("\n🔍 Verifying change...")
    test_query = supabase.table('daily_work_reports').select('employee_id').limit(0).execute()
    print("✅ Column 'employee_id' confirmed!")
    
except Exception as e:
    error_msg = str(e)
    print(f"\n❌ Error: {error_msg}")
    
    if 'exec_sql' in error_msg or 'function' in error_msg.lower():
        print("\n⚠️ Cannot execute SQL via Python client.")
        print("📋 Please run this SQL in Supabase SQL Editor:")
        print("\n" + "=" * 70)
        for sql in sql_commands:
            print(sql)
        print("=" * 70)
    else:
        print("\n💡 Alternative: Copy SQL from 'rename_user_id_to_employee_id.sql'")
