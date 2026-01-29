"""
Fix RLS policy for employees table using direct PostgreSQL connection
"""
import psycopg2

# Connection string from .env
CONN_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

sql = """
-- Drop existing policies
DROP POLICY IF EXISTS "employees_insert_policy" ON employees;
DROP POLICY IF EXISTS "employees_select_policy" ON employees;
DROP POLICY IF EXISTS "employees_update_policy" ON employees;
DROP POLICY IF EXISTS "employees_delete_policy" ON employees;

-- Allow CEO to INSERT employees for their company
CREATE POLICY "employees_insert_policy" ON employees
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
        AND users.company_id = employees.company_id
    )
);

-- Allow CEO to VIEW employees in their company
CREATE POLICY "employees_select_policy" ON employees
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
        AND users.company_id = employees.company_id
    )
);

-- Allow CEO to UPDATE employees in their company
CREATE POLICY "employees_update_policy" ON employees
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
        AND users.company_id = employees.company_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
        AND users.company_id = employees.company_id
    )
);

-- Allow CEO to DELETE employees in their company
CREATE POLICY "employees_delete_policy" ON employees
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
        AND users.company_id = employees.company_id
    )
);

-- Enable RLS
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
"""

print("🔧 Connecting to PostgreSQL...")

try:
    # Connect to database
    conn = psycopg2.connect(CONN_STRING)
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("✅ Connected successfully!")
    print("🔧 Executing RLS policy fix...")
    
    # Execute SQL
    cursor.execute(sql)
    
    print("✅ RLS policies created successfully!")
    print("\n📋 Policies created:")
    print("   ✅ employees_insert_policy - CEO can insert employees")
    print("   ✅ employees_select_policy - CEO can view employees")
    print("   ✅ employees_update_policy - CEO can update employees")
    print("   ✅ employees_delete_policy - CEO can delete employees")
    
    # Verify policies
    cursor.execute("""
        SELECT policyname, cmd, qual, with_check 
        FROM pg_policies 
        WHERE tablename = 'employees'
    """)
    
    policies = cursor.fetchall()
    print(f"\n🔍 Verified {len(policies)} policies in database:")
    for policy in policies:
        print(f"   - {policy[0]} ({policy[1]})")
    
    cursor.close()
    conn.close()
    
    print("\n✅ All done! Try creating employee again.")
    
except Exception as e:
    print(f"❌ Error: {e}")
    print("\n📋 If this fails, please run SQL manually in Supabase Dashboard")
