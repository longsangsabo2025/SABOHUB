-- ============================================================
-- FIX COMPANIES SELECT POLICY
-- Allow CEO and authenticated users to SELECT companies
-- ============================================================

-- Drop existing SELECT policy if exists
DROP POLICY IF EXISTS "Companies SELECT policy" ON companies;
DROP POLICY IF EXISTS "Allow CEO to select companies" ON companies;
DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;

-- Create new SELECT policy: Allow all authenticated users to read companies
-- This is necessary because:
-- 1. CEO needs to see all companies to assign tasks
-- 2. Managers need to see companies they work for
-- 3. Employees need to see their company information
CREATE POLICY "Allow authenticated users to select companies"
ON companies
FOR SELECT
TO authenticated
USING (true);

-- Verify the policy was created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;

-- Test query: Try to select companies
SELECT id, name, business_type, is_active 
FROM companies 
ORDER BY name;
