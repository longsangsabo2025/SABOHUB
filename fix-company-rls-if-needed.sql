-- Fix Company RLS Policies if needed
-- Only run this if you're still getting RLS errors

-- 1. Drop existing policies
DROP POLICY IF EXISTS "Users can view companies they own or work for" ON companies;
DROP POLICY IF EXISTS "Only CEO can create companies" ON companies;
DROP POLICY IF EXISTS "Only owner can update company" ON companies;
DROP POLICY IF EXISTS "Only owner can delete company" ON companies;

-- 2. Create simple policies for testing
-- CEO can do everything
CREATE POLICY "CEO can manage all companies" ON companies
  FOR ALL
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

-- Users can view their own companies
CREATE POLICY "Users can view own companies" ON companies
  FOR SELECT
  USING (
    owner_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.company_id = companies.id
    )
  );

-- 3. Verify policies are created
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'companies';

-- 4. Test insert
INSERT INTO companies (name, address, business_type, is_active, owner_id)
VALUES (
  'Test Company RLS',
  'Test Address',
  'billiards',
  true,
  auth.uid()
)
RETURNING *;
