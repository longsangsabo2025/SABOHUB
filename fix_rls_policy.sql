-- ========================================
-- FIX INFINITE RECURSION IN RLS POLICY
-- ========================================

-- Step 1: Drop all existing policies on users table
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON users;
DROP POLICY IF EXISTS "Enable delete for users based on id" ON users;
DROP POLICY IF EXISTS "Allow users to read own data" ON users;
DROP POLICY IF EXISTS "Allow users to update own data" ON users;

-- Step 2: Disable RLS temporarily (for testing)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Step 3: Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 4: Create SIMPLE, NON-RECURSIVE policies
-- Policy 1: Users can SELECT their own profile
CREATE POLICY "users_select_own"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy 2: Users can UPDATE their own profile
CREATE POLICY "users_update_own"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 3: Service role can do anything
CREATE POLICY "service_role_all"
ON users
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy 4: Allow INSERT for authenticated users (for signup)
CREATE POLICY "users_insert_own"
ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- ========================================
-- VERIFY POLICIES
-- ========================================
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
WHERE tablename = 'users'
ORDER BY policyname;
