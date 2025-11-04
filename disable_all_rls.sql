-- ============================================================
-- DISABLE RLS FOR ALL TABLES (FOR DEVELOPMENT ONLY)
-- ⚠️ WARNING: This removes all security! Only use in development!
-- ============================================================

-- List all tables with RLS enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND rowsecurity = true;

-- ============================================================
-- DISABLE RLS on all main tables
-- ============================================================

ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE branches DISABLE ROW LEVEL SECURITY;
ALTER TABLE tables DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE time_slots DISABLE ROW LEVEL SECURITY;
ALTER TABLE management_tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE ai_uploaded_files DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- DROP ALL POLICIES (cleanup)
-- ============================================================

-- Users table policies
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "CEO can read all users" ON users;
DROP POLICY IF EXISTS "Allow authenticated users to read users" ON users;

-- Companies table policies
DROP POLICY IF EXISTS "Companies SELECT policy" ON companies;
DROP POLICY IF EXISTS "Allow CEO to select companies" ON companies;
DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;
DROP POLICY IF EXISTS "CEO can insert companies" ON companies;
DROP POLICY IF EXISTS "CEO can update companies" ON companies;
DROP POLICY IF EXISTS "CEO can delete companies" ON companies;

-- Management tasks policies
DROP POLICY IF EXISTS "CEO can read all tasks" ON management_tasks;
DROP POLICY IF EXISTS "Manager can read assigned tasks" ON management_tasks;
DROP POLICY IF EXISTS "CEO can create tasks" ON management_tasks;
DROP POLICY IF EXISTS "CEO can update tasks" ON management_tasks;
DROP POLICY IF EXISTS "Manager can update assigned tasks" ON management_tasks;

-- Branches policies
DROP POLICY IF EXISTS "Allow authenticated users to read branches" ON branches;
DROP POLICY IF EXISTS "CEO can manage branches" ON branches;

-- Tables policies
DROP POLICY IF EXISTS "Allow authenticated users to read tables" ON tables;
DROP POLICY IF EXISTS "Manager can manage tables" ON tables;

-- Orders policies
DROP POLICY IF EXISTS "Allow authenticated users to read orders" ON orders;
DROP POLICY IF EXISTS "Staff can manage orders" ON orders;

-- AI tables policies
DROP POLICY IF EXISTS "Users can read own conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON ai_conversations;
DROP POLICY IF EXISTS "Users can read own messages" ON ai_messages;
DROP POLICY IF EXISTS "Users can create messages" ON ai_messages;
DROP POLICY IF EXISTS "Users can read own files" ON ai_uploaded_files;
DROP POLICY IF EXISTS "Users can upload files" ON ai_uploaded_files;

-- ============================================================
-- VERIFY: Show all remaining policies (should be none)
-- ============================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================
-- VERIFY: Show RLS status for all tables (should be disabled)
-- ============================================================

SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '🔒 RLS ENABLED' ELSE '✅ RLS DISABLED' END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'users', 'companies', 'branches', 'tables', 
    'orders', 'order_items', 'time_slots',
    'management_tasks', 'ai_conversations', 
    'ai_messages', 'ai_uploaded_files'
  )
ORDER BY tablename;

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

SELECT '✅ RLS DISABLED FOR ALL TABLES!' as status,
       'All users can now read/write all data' as note,
       '⚠️ RE-ENABLE RLS BEFORE PRODUCTION!' as warning;
