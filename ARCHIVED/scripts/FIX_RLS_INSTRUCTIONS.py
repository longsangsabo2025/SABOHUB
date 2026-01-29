"""
🔧 MANUAL FIX REQUIRED: RLS Policy for Employees Table

ERROR: new row violates row-level security policy for table "employees"
CODE: 42501

SOLUTION: Run this SQL in Supabase Dashboard > SQL Editor

STEP 1: Go to https://app.supabase.com
STEP 2: Select your project (SABOHUB)
STEP 3: Click "SQL Editor" in left sidebar
STEP 4: Copy and paste the SQL below
STEP 5: Click "Run" button

============================================================================
SQL TO RUN:
============================================================================
"""

sql_fix = """
-- Fix RLS policy for employees table

-- Drop and recreate INSERT policy
DROP POLICY IF EXISTS "employees_insert_policy" ON employees;

CREATE POLICY "employees_insert_policy" ON employees
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow if user is CEO
        EXISTS (
            SELECT 1 FROM auth.users  
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    );

-- Verify
SELECT tablename, policyname, cmd FROM pg_policies 
WHERE tablename = 'employees' 
ORDER BY policyname;
"""

print(__doc__)
print(sql_fix)
print("\n" + "=" * 80)
print("✅ After running SQL, try creating employee again in the app")
print("=" * 80)
