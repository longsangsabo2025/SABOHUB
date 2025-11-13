-- ============================================================================
-- FIX CEO COMPANIES VISIBILITY ISSUE
-- ============================================================================
-- Problem: CEO không thấy companies trong UI vì RLS đang block
-- Solution: Thêm policy cho phép CEO xem tất cả companies
-- ============================================================================

-- 1. Check current RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'companies';

-- 2. Check existing policies
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;

-- 3. Drop old policies (if any conflict)
DROP POLICY IF EXISTS "companies_select_policy" ON companies;
DROP POLICY IF EXISTS "CEO can view all companies" ON companies;
DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;

-- 4. Create new SELECT policy for CEO
-- ✅ Allow CEO to see ALL companies
-- ✅ Allow other users to see their own company
CREATE POLICY "companies_select_policy"
ON companies
FOR SELECT
TO authenticated
USING (
  -- CEO can see ALL companies
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'CEO'
  )
  OR
  -- Other users can see their own company
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.company_id = companies.id
  )
);

-- 5. Verify the policy was created
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
AND policyname = 'companies_select_policy';

-- 6. Test query as authenticated user
-- Run this in Supabase SQL Editor after logging in as CEO
SELECT id, name, business_type, is_active, created_at
FROM companies
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- ============================================================================
-- EXPECTED RESULT:
-- CEO users should now be able to see all companies in the UI
-- ============================================================================
