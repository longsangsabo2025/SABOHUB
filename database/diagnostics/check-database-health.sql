-- ============================================
-- Database Health Check & Diagnostics
-- Run this to see current RLS policies and identify issues
-- ============================================

-- ==========================================
-- 1. CHECK RLS STATUS ON TABLES
-- ==========================================
SELECT 
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('users', 'tasks', 'orders', 'products', 'inventory_items')
ORDER BY tablename;

-- ==========================================
-- 2. LIST ALL POLICIES ON USERS TABLE
-- ==========================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd AS command,
    qual AS using_expression,
    with_check AS with_check_expression
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- ==========================================
-- 3. LIST ALL POLICIES ON TASKS TABLE
-- ==========================================
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd AS command
FROM pg_policies
WHERE tablename = 'tasks'
ORDER BY policyname;

-- ==========================================
-- 4. CHECK FOR DANGEROUS FUNCTIONS (RECURSION RISK)
-- ==========================================
SELECT 
    n.nspname AS schema,
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('is_ceo', 'is_manager_or_above', 'is_shift_leader_or_above', 'get_user_role')
ORDER BY p.proname;

-- ==========================================
-- 5. CHECK CUSTOM AUTH FUNCTIONS
-- ==========================================
SELECT 
    n.nspname AS schema,
    p.proname AS function_name,
    pg_get_function_result(p.oid) AS return_type,
    CASE 
        WHEN p.prosecdef THEN 'SECURITY DEFINER'
        ELSE 'SECURITY INVOKER'
    END AS security_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'auth'
AND p.proname LIKE '%user%'
ORDER BY p.proname;

-- ==========================================
-- 6. CHECK FOR CUSTOM ACCESS TOKEN HOOK
-- ==========================================
SELECT 
    n.nspname AS schema,
    p.proname AS function_name,
    pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'custom_access_token_hook'
ORDER BY n.nspname;

-- ==========================================
-- 7. COUNT USERS BY ROLE
-- ==========================================
SELECT 
    role,
    COUNT(*) AS user_count
FROM users
GROUP BY role
ORDER BY user_count DESC;

-- ==========================================
-- 8. CHECK RECENT ERRORS IN LOGS
-- ==========================================
-- Note: This requires pg_stat_statements extension
-- You may need to enable it first:
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

/*
SELECT 
    LEFT(query, 100) AS query_start,
    calls,
    total_exec_time / 1000 AS total_time_seconds,
    mean_exec_time / 1000 AS avg_time_seconds
FROM pg_stat_statements
WHERE query LIKE '%users%'
AND mean_exec_time > 1000  -- Queries taking > 1 second
ORDER BY total_exec_time DESC
LIMIT 10;
*/

-- ==========================================
-- 9. SIMULATE POLICY CHECK
-- ==========================================
-- Test if current user can select from users table
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    BEGIN
        SELECT COUNT(*) INTO test_count FROM users;
        RAISE NOTICE '✅ Successfully queried users table. Count: %', test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Error querying users table: % %', SQLERRM, SQLSTATE;
    END;
END $$;

-- ==========================================
-- 10. CHECK TABLE OWNERSHIP
-- ==========================================
SELECT 
    t.schemaname,
    t.tablename,
    t.tableowner,
    pg_size_pretty(pg_total_relation_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename))) AS size
FROM pg_tables t
WHERE t.schemaname = 'public'
AND t.tablename IN ('users', 'tasks', 'orders', 'products')
ORDER BY pg_total_relation_size(quote_ident(t.schemaname)||'.'||quote_ident(t.tablename)) DESC;

-- ==========================================
-- 11. SUMMARY
-- ==========================================
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'DATABASE HEALTH CHECK COMPLETE';
    RAISE NOTICE '================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Review the results above to identify:';
    RAISE NOTICE '  1. Tables with RLS enabled';
    RAISE NOTICE '  2. Existing policies that may cause recursion';
    RAISE NOTICE '  3. Dangerous functions (is_ceo, is_manager_or_above)';
    RAISE NOTICE '  4. Whether custom_access_token_hook exists';
    RAISE NOTICE '';
    RAISE NOTICE 'If you see recursion-causing functions/policies,';
    RAISE NOTICE 'apply migration: 999_fix_rls_infinite_recursion.sql';
    RAISE NOTICE '================================================';
END $$;
