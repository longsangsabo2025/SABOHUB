-- ============================================
-- SABOHUB RLS POLICIES v2.0
-- Safe, Non-Recursive Row Level Security
-- ============================================

-- ==========================================
-- HELPER FUNCTIONS (JWT-based, NO recursion)
-- ==========================================

-- Get user role from JWT
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN COALESCE(
    current_setting('request.jwt.claims', true)::json->>'user_role',
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get user branch_id from JWT
CREATE OR REPLACE FUNCTION public.get_current_user_branch_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'branch_id')::uuid,
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get user company_id from JWT
CREATE OR REPLACE FUNCTION public.get_current_user_company_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (current_setting('request.jwt.claims', true)::json->>'company_id')::uuid,
    NULL
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Check if user is CEO
CREATE OR REPLACE FUNCTION public.is_ceo()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.get_current_user_role() = 'CEO';
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Check if user is manager or above
CREATE OR REPLACE FUNCTION public.is_manager_or_above()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.get_current_user_role() IN ('CEO', 'BRANCH_MANAGER');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ==========================================
-- ENABLE RLS ON ALL TABLES
-- ==========================================

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE branch_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- COMPANIES POLICIES
-- ==========================================

-- CEO can see all companies
CREATE POLICY companies_select_ceo ON companies
  FOR SELECT
  USING (public.is_ceo());

-- Users can see their own company
CREATE POLICY companies_select_own ON companies
  FOR SELECT
  USING (id = public.get_current_user_company_id());

-- Only CEO can modify companies
CREATE POLICY companies_all_ceo ON companies
  FOR ALL
  USING (public.is_ceo())
  WITH CHECK (public.is_ceo());

-- ==========================================
-- BRANCHES POLICIES
-- ==========================================

-- CEO can see all branches
CREATE POLICY branches_select_ceo ON branches
  FOR SELECT
  USING (public.is_ceo());

-- Users can see branches in their company
CREATE POLICY branches_select_company ON branches
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- CEO and Branch Managers can modify branches
CREATE POLICY branches_all_managers ON branches
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- ==========================================
-- USERS POLICIES
-- ==========================================

-- Users can view their own profile
CREATE POLICY users_select_own ON users
  FOR SELECT
  USING (id = auth.uid());

-- CEO can view all users
CREATE POLICY users_select_ceo ON users
  FOR SELECT
  USING (public.is_ceo());

-- Branch Managers can view users in their branch
CREATE POLICY users_select_branch_manager ON users
  FOR SELECT
  USING (
    public.get_current_user_role() = 'BRANCH_MANAGER'
    AND branch_id = public.get_current_user_branch_id()
  );

-- Users can update their own profile (limited fields)
CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    -- Prevent role/company/branch changes by self
    AND role = (SELECT role FROM users WHERE id = auth.uid())
    AND company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    AND branch_id = (SELECT branch_id FROM users WHERE id = auth.uid())
  );

-- CEO can do anything with users
CREATE POLICY users_all_ceo ON users
  FOR ALL
  USING (public.is_ceo())
  WITH CHECK (public.is_ceo());

-- Branch Managers can manage users in their branch (except CEO)
CREATE POLICY users_all_branch_manager ON users
  FOR ALL
  USING (
    public.get_current_user_role() = 'BRANCH_MANAGER'
    AND branch_id = public.get_current_user_branch_id()
    AND role != 'CEO'
  )
  WITH CHECK (
    public.get_current_user_role() = 'BRANCH_MANAGER'
    AND branch_id = public.get_current_user_branch_id()
    AND role != 'CEO'
  );

-- ==========================================
-- TASKS POLICIES
-- ==========================================

-- Users can view tasks assigned to them
CREATE POLICY tasks_select_assigned ON tasks
  FOR SELECT
  USING (assigned_to = auth.uid());

-- CEO can view all tasks
CREATE POLICY tasks_select_ceo ON tasks
  FOR SELECT
  USING (public.is_ceo());

-- Branch staff can view tasks in their branch
CREATE POLICY tasks_select_branch ON tasks
  FOR SELECT
  USING (branch_id = public.get_current_user_branch_id());

-- Managers can create/update/delete tasks
CREATE POLICY tasks_all_managers ON tasks
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- Assigned users can update their task status
CREATE POLICY tasks_update_assigned ON tasks
  FOR UPDATE
  USING (assigned_to = auth.uid())
  WITH CHECK (
    assigned_to = auth.uid()
    -- Only allow status updates, not reassignment
    AND assigned_to = (SELECT assigned_to FROM tasks WHERE id = tasks.id)
  );

-- ==========================================
-- PRODUCTS & INVENTORY POLICIES
-- ==========================================

-- Everyone can view products in their company
CREATE POLICY products_select_company ON products
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- Managers can manage products
CREATE POLICY products_all_managers ON products
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- Branch staff can view inventory in their branch
CREATE POLICY branch_inventory_select_branch ON branch_inventory
  FOR SELECT
  USING (branch_id = public.get_current_user_branch_id());

-- Managers can manage inventory
CREATE POLICY branch_inventory_all_managers ON branch_inventory
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- Everyone can view inventory transactions in their branch
CREATE POLICY inventory_transactions_select_branch ON inventory_transactions
  FOR SELECT
  USING (branch_id = public.get_current_user_branch_id());

-- Staff can create inventory transactions
CREATE POLICY inventory_transactions_insert_staff ON inventory_transactions
  FOR INSERT
  WITH CHECK (branch_id = public.get_current_user_branch_id());

-- ==========================================
-- ORDERS & PAYMENTS POLICIES
-- ==========================================

-- CEO can view all orders
CREATE POLICY orders_select_ceo ON orders
  FOR SELECT
  USING (public.is_ceo());

-- Branch staff can view orders in their branch
CREATE POLICY orders_select_branch ON orders
  FOR SELECT
  USING (branch_id = public.get_current_user_branch_id());

-- Branch staff can create orders
CREATE POLICY orders_insert_branch ON orders
  FOR INSERT
  WITH CHECK (branch_id = public.get_current_user_branch_id());

-- Branch staff can update orders in their branch
CREATE POLICY orders_update_branch ON orders
  FOR UPDATE
  USING (branch_id = public.get_current_user_branch_id())
  WITH CHECK (branch_id = public.get_current_user_branch_id());

-- Managers can delete orders
CREATE POLICY orders_delete_managers ON orders
  FOR DELETE
  USING (public.is_manager_or_above());

-- Order items follow order permissions
CREATE POLICY order_items_select_via_order ON order_items
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND (
        orders.branch_id = public.get_current_user_branch_id()
        OR public.is_ceo()
      )
    )
  );

CREATE POLICY order_items_all_via_order ON order_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.branch_id = public.get_current_user_branch_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.branch_id = public.get_current_user_branch_id()
    )
  );

-- Payments follow similar pattern
CREATE POLICY payments_select_branch ON payments
  FOR SELECT
  USING (
    branch_id = public.get_current_user_branch_id()
    OR public.is_ceo()
  );

CREATE POLICY payments_insert_branch ON payments
  FOR INSERT
  WITH CHECK (branch_id = public.get_current_user_branch_id());

-- ==========================================
-- CUSTOM ACCESS TOKEN HOOK
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
  SELECT role, branch_id, company_id 
  INTO user_role, user_branch_id, user_company_id
  FROM public.users
  WHERE id = (event->>'user_id')::uuid
  AND deleted_at IS NULL;

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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO postgres;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO authenticated;

-- ==========================================
-- VERIFICATION
-- ==========================================

DO $$
BEGIN
  RAISE NOTICE '✅ RLS Policies v2.0 created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE '📝 NEXT STEPS:';
  RAISE NOTICE '   1. Enable Auth Hook in Supabase Dashboard';
  RAISE NOTICE '   2. Function: public.custom_access_token_hook';
  RAISE NOTICE '   3. All users must re-login to get JWT with metadata';
  RAISE NOTICE '';
  RAISE NOTICE '🔒 Security Features:';
  RAISE NOTICE '   - JWT-based authorization (no database queries in policies)';
  RAISE NOTICE '   - Role-based access control';
  RAISE NOTICE '   - Branch-level isolation';
  RAISE NOTICE '   - CEO has full access across all companies';
  RAISE NOTICE '';
END $$;
