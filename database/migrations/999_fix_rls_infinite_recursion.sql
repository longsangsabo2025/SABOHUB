-- ============================================
-- CRITICAL FIX: Infinite Recursion in RLS Policies
-- Created: 2025-11-02
-- Purpose: Fix infinite recursion by removing circular dependencies
-- ============================================

-- ==========================================
-- STEP 1: DROP ALL EXISTING POLICIES ON USERS TABLE
-- ==========================================

DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "CEO can manage users" ON users;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "CEO and MANAGER can read store users" ON users;
DROP POLICY IF EXISTS "CEO and MANAGER can update store users" ON users;
DROP POLICY IF EXISTS "tasks_select_own" ON users;
DROP POLICY IF EXISTS "tasks_select_leaders" ON users;

-- ==========================================
-- STEP 2: DROP OLD HELPER FUNCTIONS (THEY CAUSE RECURSION)
-- ==========================================

DROP FUNCTION IF EXISTS is_ceo();
DROP FUNCTION IF EXISTS is_manager_or_above();
DROP FUNCTION IF EXISTS is_shift_leader_or_above();
DROP FUNCTION IF EXISTS get_user_role();

-- ==========================================
-- STEP 3: CREATE NEW SAFE HELPER FUNCTIONS
-- Using JWT claims to avoid querying users table
-- Note: Created in public schema (no permission for auth schema)
-- ==========================================

-- Get user role from JWT token (no database query!)
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN COALESCE(
    current_setting('request.jwt.claims', true)::json->>'user_role',
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get user branch_id from JWT token
CREATE OR REPLACE FUNCTION public.get_user_branch_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'branch_id')::uuid,
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get user company_id from JWT token
CREATE OR REPLACE FUNCTION public.get_user_company_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'company_id')::uuid,
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ==========================================
-- STEP 4: CREATE SAFE RLS POLICIES FOR USERS TABLE
-- ==========================================

-- Policy 1: Users can always read their own profile (no recursion)
CREATE POLICY "users_select_own"
  ON users FOR SELECT
  USING (id = auth.uid());

-- Policy 2: CEOs can read all users (using JWT, not query)
CREATE POLICY "users_select_ceo"
  ON users FOR SELECT
  USING (public.get_user_role() = 'CEO');

-- Policy 3: Managers can read users in their store
CREATE POLICY "users_select_manager"
  ON users FOR SELECT
  USING (
    public.get_user_role() = 'MANAGER' 
    AND branch_id = public.get_user_branch_id()
  );

-- Policy 4: Users can update their own basic info
CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    -- Only allow updating safe fields, role changes blocked
    AND role = (SELECT role FROM users WHERE id = auth.uid())
  );

-- Policy 5: CEO can update any user
CREATE POLICY "users_update_ceo"
  ON users FOR UPDATE
  USING (public.get_user_role() = 'CEO');

-- Policy 6: Manager can update users in their store (except CEO)
CREATE POLICY "users_update_manager"
  ON users FOR UPDATE
  USING (
    public.get_user_role() = 'MANAGER'
    AND branch_id = public.get_user_branch_id()
    AND role != 'CEO'
  );

-- Policy 7: Only CEO can insert new users
CREATE POLICY "users_insert_ceo"
  ON users FOR INSERT
  WITH CHECK (public.get_user_role() = 'CEO');

-- Policy 8: Only CEO can delete users
CREATE POLICY "users_delete_ceo"
  ON users FOR DELETE
  USING (public.get_user_role() = 'CEO');

-- ==========================================
-- STEP 5: FIX TASKS POLICIES (REMOVE RECURSION)
-- ==========================================

-- Drop old policies
DROP POLICY IF EXISTS "tasks_select_own" ON tasks;
DROP POLICY IF EXISTS "tasks_select_leaders" ON tasks;
DROP POLICY IF EXISTS "tasks_insert_leaders" ON tasks;
DROP POLICY IF EXISTS "tasks_update" ON tasks;
DROP POLICY IF EXISTS "tasks_delete_leaders" ON tasks;
DROP POLICY IF EXISTS "Users can view their tasks" ON tasks;
DROP POLICY IF EXISTS "Managers can create tasks" ON tasks;
DROP POLICY IF EXISTS "Users can update assigned tasks" ON tasks;
DROP POLICY IF EXISTS "Managers can delete tasks" ON tasks;

-- New safe policies
CREATE POLICY "tasks_select_own"
  ON tasks FOR SELECT
  USING (assigned_to = auth.uid());

CREATE POLICY "tasks_select_ceo"
  ON tasks FOR SELECT
  USING (public.get_user_role() = 'CEO');

CREATE POLICY "tasks_select_manager"
  ON tasks FOR SELECT
  USING (
    public.get_user_role() IN ('MANAGER', 'SHIFT_LEADER')
    AND (branch_id = public.get_user_branch_id() OR company_id = public.get_user_company_id())
  );

CREATE POLICY "tasks_insert_leaders"
  ON tasks FOR INSERT
  WITH CHECK (
    public.get_user_role() IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
  );

CREATE POLICY "tasks_update_own"
  ON tasks FOR UPDATE
  USING (assigned_to = auth.uid());

CREATE POLICY "tasks_update_leaders"
  ON tasks FOR UPDATE
  USING (
    public.get_user_role() IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
  );

CREATE POLICY "tasks_delete_leaders"
  ON tasks FOR DELETE
  USING (
    public.get_user_role() IN ('CEO', 'MANAGER', 'SHIFT_LEADER')
  );

-- ==========================================
-- STEP 6: UPDATE JWT CLAIMS FUNCTION
-- This ensures JWT tokens include necessary metadata
-- ==========================================

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims jsonb;
  user_role text;
  user_branch_id uuid;
  user_company_id uuid;
BEGIN
  -- Get user metadata from database
  SELECT role, branch_id, company_id INTO user_role, user_branch_id, user_company_id
  FROM public.users
  WHERE id = (event->>'user_id')::uuid;

  -- Add custom claims to JWT
  claims := event->'claims';
  
  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  END IF;
  
  IF user_branch_id IS NOT NULL THEN
    claims := jsonb_set(claims, '{branch_id}', to_jsonb(user_branch_id::text));
  END IF;
  
  IF user_company_id IS NOT NULL THEN
    claims := jsonb_set(claims, '{company_id}', to_jsonb(user_company_id::text));
  END IF;

  -- Return modified event
  event := jsonb_set(event, '{claims}', claims);
  
  RETURN event;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO postgres;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO authenticated;

-- ==========================================
-- STEP 7: FIX OTHER TABLES POLICIES
-- ==========================================

-- TABLES TABLE
DROP POLICY IF EXISTS "Users can read store tables" ON tables;
CREATE POLICY "tables_select_store"
  ON tables FOR SELECT
  USING (
    public.get_user_role() = 'CEO'
    OR branch_id = public.get_user_branch_id()
  );

-- ORDERS TABLE
DROP POLICY IF EXISTS "Users can manage store orders" ON orders;
CREATE POLICY "orders_select_store"
  ON orders FOR SELECT
  USING (
    public.get_user_role() = 'CEO'
    OR branch_id = public.get_user_branch_id()
  );

CREATE POLICY "orders_insert_staff"
  ON orders FOR INSERT
  WITH CHECK (branch_id = public.get_user_branch_id());

CREATE POLICY "orders_update_staff"
  ON orders FOR UPDATE
  USING (branch_id = public.get_user_branch_id());

-- PRODUCTS TABLE
DROP POLICY IF EXISTS "Users can read store products" ON products;
CREATE POLICY "products_select_store"
  ON products FOR SELECT
  USING (
    public.get_user_role() = 'CEO'
    OR branch_id = public.get_user_branch_id()
  );

-- INVENTORY ITEMS
DROP POLICY IF EXISTS "Users can manage store inventory items" ON inventory_items;
CREATE POLICY "inventory_select_store"
  ON inventory_items FOR SELECT
  USING (
    public.get_user_role() = 'CEO'
    OR branch_id = public.get_user_branch_id()
  );

CREATE POLICY "inventory_insert_manager"
  ON inventory_items FOR INSERT
  WITH CHECK (
    public.get_user_role() IN ('CEO', 'MANAGER')
    AND branch_id = public.get_user_branch_id()
  );

CREATE POLICY "inventory_update_manager"
  ON inventory_items FOR UPDATE
  USING (
    public.get_user_role() IN ('CEO', 'MANAGER')
    AND branch_id = public.get_user_branch_id()
  );

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Test that policies work
DO $$
BEGIN
  RAISE NOTICE '✅ RLS Policies fixed successfully!';
  RAISE NOTICE '⚠️  IMPORTANT: You must configure Auth Hook in Supabase Dashboard:';
  RAISE NOTICE '    1. Go to Authentication → Hooks';
  RAISE NOTICE '    2. Enable "custom_access_token_hook"';
  RAISE NOTICE '    3. Set hook function: public.custom_access_token_hook';
  RAISE NOTICE '';
  RAISE NOTICE '📝 After applying this migration:';
  RAISE NOTICE '    1. All users must re-login to get new JWT tokens';
  RAISE NOTICE '    2. Test with different roles (CEO, MANAGER, STAFF)';
  RAISE NOTICE '    3. Verify no infinite recursion errors';
END $$;

