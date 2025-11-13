"""
Fix RLS policy: Allow CEO to create employees for ANY company
CEO role có company_id = NULL, nên không thể match với employees.company_id
"""
import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

sql = """
-- Drop existing policies
DROP POLICY IF EXISTS "employees_insert_policy" ON employees;
DROP POLICY IF EXISTS "employees_select_policy" ON employees;
DROP POLICY IF EXISTS "employees_update_policy" ON employees;
DROP POLICY IF EXISTS "employees_delete_policy" ON employees;
DROP POLICY IF EXISTS "ceo_create_employees" ON employees;
DROP POLICY IF EXISTS "ceo_view_all_employees" ON employees;
DROP POLICY IF EXISTS "ceo_update_employees" ON employees;
DROP POLICY IF EXISTS "ceo_delete_employees" ON employees;

-- Allow CEO to INSERT employees for ANY company
CREATE POLICY "ceo_create_employees" ON employees
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
    )
);

-- Allow CEO to VIEW all employees
CREATE POLICY "ceo_view_all_employees" ON employees
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
    )
);

-- Allow CEO to UPDATE all employees
CREATE POLICY "ceo_update_employees" ON employees
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
    )
);

-- Allow CEO to DELETE all employees
CREATE POLICY "ceo_delete_employees" ON employees
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'CEO'
    )
);

-- Enable RLS
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
"""

print("🔧 Fixing RLS for CEO (allow all companies)...")

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("✅ Connected!")
    print("🔧 Executing SQL...")
    
    cursor.execute(sql)
    
    print("✅ RLS policies updated!")
    print("\n📋 New policies:")
    print("   ✅ ceo_create_employees - CEO can create employees for ANY company")
    print("   ✅ ceo_view_all_employees - CEO can view ALL employees")
    print("   ✅ ceo_update_employees - CEO can update ALL employees")
    print("   ✅ ceo_delete_employees - CEO can delete ALL employees")
    
    # Verify
    cursor.execute("""
        SELECT policyname, cmd 
        FROM pg_policies 
        WHERE tablename = 'employees'
        ORDER BY policyname
    """)
    policies = cursor.fetchall()
    print(f"\n🔍 Verified {len(policies)} policies:")
    for p in policies:
        print(f"   - {p[0]} ({p[1]})")
    
    cursor.close()
    conn.close()
    
    print("\n✅ Done! Try creating employee now!")
    
except Exception as e:
    print(f"❌ Error: {e}")
