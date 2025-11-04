-- ============================================================================
-- FIX COMPANIES RLS - ALLOW CEO TO CREATE COMPANIES
-- ============================================================================
-- Database mới, RLS policies cũ chặn INSERT
-- Fix: Cho phép CEO tạo companies dễ dàng hơn
-- ============================================================================

-- Drop old policies
DROP POLICY IF EXISTS "Users can view companies they own or work for" ON companies;
DROP POLICY IF EXISTS "Only CEO can create companies" ON companies;
DROP POLICY IF EXISTS "Only owner can update company" ON companies;
DROP POLICY IF EXISTS "Only owner can delete company" ON companies;

-- ============================================================================
-- NEW SIMPLE POLICIES (No owner_id dependency)
-- ============================================================================

-- 1. SELECT: CEO xem tất cả, staff xem company của mình
CREATE POLICY "companies_select_policy" ON companies
  FOR SELECT
  USING (
    -- CEO xem tất cả
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'CEO'
    )
    OR
    -- Staff xem company của mình
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.company_id = companies.id
    )
  );

-- 2. INSERT: Chỉ CEO được tạo companies
CREATE POLICY "companies_insert_policy" ON companies
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'CEO'
    )
  );

-- 3. UPDATE: CEO update tất cả, manager update company của mình
CREATE POLICY "companies_update_policy" ON companies
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND (
        users.role = 'CEO'
        OR 
        users.company_id = companies.id
      )
    )
  );

-- 4. DELETE: Chỉ CEO được xóa
CREATE POLICY "companies_delete_policy" ON companies
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'CEO'
    )
  );

-- ============================================================================
-- VERIFY
-- ============================================================================

-- Check policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;
