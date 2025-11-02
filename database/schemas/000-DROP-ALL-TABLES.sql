-- ============================================
-- DROP ALL EXISTING TABLES
-- Run this before NEW-SCHEMA-V2.sql
-- ============================================

-- Drop all tables in reverse dependency order
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory_transactions CASCADE;
DROP TABLE IF EXISTS branch_inventory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS task_comments CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS user_sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

-- Drop any other tables that might exist
DROP TABLE IF EXISTS inventory_items CASCADE;
DROP TABLE IF EXISTS inventory_adjustments CASCADE;
DROP TABLE IF EXISTS tables CASCADE;
DROP TABLE IF EXISTS store_settings CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS push_tokens CASCADE;
DROP TABLE IF EXISTS promotions CASCADE;
DROP TABLE IF EXISTS void_reasons CASCADE;

-- Drop old RLS helper functions if they exist
DROP FUNCTION IF EXISTS public.is_ceo() CASCADE;
DROP FUNCTION IF EXISTS public.is_manager_or_above() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_branch_id() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_company_id() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role() CASCADE;

-- Success message
DO $$ 
BEGIN
  RAISE NOTICE '✅ All existing tables and functions dropped successfully!';
END $$;
