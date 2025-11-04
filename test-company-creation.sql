-- Test Company Creation & RLS Policies
-- Run this in Supabase SQL Editor to debug issues

-- 1. Check current user's role
SELECT 
  id,
  email,
  role,
  company_id,
  created_at
FROM users 
WHERE email = 'longsangsabo1@gmail.com';

-- 2. Check if companies table has owner_id column
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'companies'
ORDER BY ordinal_position;

-- 3. Check RLS policies on companies table
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
WHERE tablename = 'companies';

-- 4. Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'companies';

-- 5. Test insert directly (should work if you're CEO)
-- Replace 'your-user-id' with actual user ID from step 1
/*
INSERT INTO companies (name, address, business_type, is_active, owner_id)
VALUES (
  'Test Company',
  '123 Test Street',
  'billiards',
  true,
  'your-user-id-here'
)
RETURNING *;
*/

-- 6. Check existing companies
SELECT 
  id,
  name,
  business_type,
  address,
  owner_id,
  is_active,
  created_at
FROM companies
ORDER BY created_at DESC
LIMIT 10;

-- 7. If insert fails, check auth.uid()
SELECT auth.uid() as current_user_id;

-- 8. Check if user exists in auth.users
SELECT id, email, created_at
FROM auth.users
WHERE email = 'longsangsabo1@gmail.com';
