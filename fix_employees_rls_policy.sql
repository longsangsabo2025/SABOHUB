-- Fix RLS policy for employees table to allow CEO to create employees
-- Error: new row violates row-level security policy for table "employees"

-- First, check existing policies
-- SELECT * FROM pg_policies WHERE tablename = 'employees';

-- Drop existing restrictive INSERT policy if exists
DROP POLICY IF EXISTS "employees_insert_policy" ON employees;

-- Create new INSERT policy: Allow authenticated users (CEO) to insert employees for their company
CREATE POLICY "employees_insert_policy" ON employees
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow if user's company_id matches the employee's company_id
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'company_id')::uuid = employees.company_id
        )
        OR
        -- OR allow if user is CEO (has role 'ceo' in raw_user_meta_data)
        EXISTS (
            SELECT 1 FROM auth.users  
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    );

-- Also ensure SELECT policy exists
DROP POLICY IF EXISTS "employees_select_policy" ON employees;

CREATE POLICY "employees_select_policy" ON employees
    FOR SELECT
    TO authenticated
    USING (
        -- Allow if user's company_id matches
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'company_id')::uuid = employees.company_id
        )
        OR
        -- OR if user is CEO
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    );

-- UPDATE policy
DROP POLICY IF EXISTS "employees_update_policy" ON employees;

CREATE POLICY "employees_update_policy" ON employees
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'company_id')::uuid = employees.company_id
        )
        OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'company_id')::uuid = employees.company_id
        )
        OR
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    );

-- DELETE policy
DROP POLICY IF EXISTS "employees_delete_policy" ON employees;

CREATE POLICY "employees_delete_policy" ON employees
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND (auth.users.raw_user_meta_data->>'role') = 'ceo'
        )
    );

-- Verify RLS is enabled
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- Test query to verify
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies 
WHERE tablename = 'employees'
ORDER BY policyname;
