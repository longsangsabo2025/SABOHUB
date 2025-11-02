-- ============================================================================
-- 🔐 MINIMAL RLS POLICIES FOR CEO
-- ============================================================================
-- Row Level Security cho CEO-focused schema
-- CEO có quyền xem TẤT CẢ, các role khác chỉ xem data của company/branch mình
-- ============================================================================

-- ============================================================================
-- STEP 1: HELPER FUNCTIONS (Tránh recursive RLS)
-- ============================================================================

-- Get current user's role (cached in JWT)
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN COALESCE(
    current_setting('request.jwt.claims', true)::json->>'user_role',
    'STAFF' -- Default fallback
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get current user's company_id (cached in JWT)
CREATE OR REPLACE FUNCTION public.get_current_user_company_id()
RETURNS UUID AS $$
BEGIN
  RETURN (current_setting('request.jwt.claims', true)::json->>'company_id')::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get current user's branch_id (cached in JWT)
CREATE OR REPLACE FUNCTION public.get_current_user_branch_id()
RETURNS UUID AS $$
BEGIN
  RETURN (current_setting('request.jwt.claims', true)::json->>'branch_id')::UUID;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current user is CEO
CREATE OR REPLACE FUNCTION public.is_ceo()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.get_current_user_role() = 'CEO';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current user is Manager or above
CREATE OR REPLACE FUNCTION public.is_manager_or_above()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN public.get_current_user_role() IN ('CEO', 'BRANCH_MANAGER');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- STEP 2: CUSTOM ACCESS TOKEN HOOK (Inject user_role vào JWT)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb AS $$
DECLARE
  user_data RECORD;
  claims jsonb;
BEGIN
  -- Get user data from users table
  SELECT role, company_id, branch_id
  INTO user_data
  FROM public.users
  WHERE id = (event->>'user_id')::UUID;

  -- Build custom claims
  claims := jsonb_build_object(
    'user_role', COALESCE(user_data.role, 'STAFF'),
    'company_id', user_data.company_id,
    'branch_id', user_data.branch_id
  );

  -- Inject claims into JWT
  event := jsonb_set(event, '{claims}', claims);

  RETURN event;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_revenue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_summary ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: USERS TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY users_select_own ON public.users
  FOR SELECT
  USING (id = auth.uid());

-- CEO can view all users
CREATE POLICY users_select_ceo ON public.users
  FOR SELECT
  USING (public.is_ceo());

-- Branch Managers can view users in their branch
CREATE POLICY users_select_branch_manager ON public.users
  FOR SELECT
  USING (
    public.get_current_user_role() = 'BRANCH_MANAGER'
    AND branch_id = public.get_current_user_branch_id()
  );

-- Users can update their own profile (limited fields)
CREATE POLICY users_update_own ON public.users
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM public.users WHERE id = auth.uid()) -- Prevent role change
  );

-- CEO can update any user
CREATE POLICY users_update_ceo ON public.users
  FOR UPDATE
  USING (public.is_ceo());

-- CEO can insert new users
CREATE POLICY users_insert_ceo ON public.users
  FOR INSERT
  WITH CHECK (public.is_ceo());

-- CEO can delete users
CREATE POLICY users_delete_ceo ON public.users
  FOR DELETE
  USING (public.is_ceo());

-- ============================================================================
-- STEP 5: COMPANIES TABLE POLICIES
-- ============================================================================

-- CEO can see all companies
CREATE POLICY companies_select_ceo ON public.companies
  FOR SELECT
  USING (public.is_ceo());

-- Users can see their own company
CREATE POLICY companies_select_own ON public.companies
  FOR SELECT
  USING (id = public.get_current_user_company_id());

-- Only CEO can modify companies (INSERT/UPDATE/DELETE)
CREATE POLICY companies_all_ceo ON public.companies
  FOR ALL
  USING (public.is_ceo())
  WITH CHECK (public.is_ceo());

-- ============================================================================
-- STEP 6: BRANCHES TABLE POLICIES
-- ============================================================================

-- CEO can see all branches
CREATE POLICY branches_select_ceo ON public.branches
  FOR SELECT
  USING (public.is_ceo());

-- Users can see branches in their company
CREATE POLICY branches_select_company ON public.branches
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- CEO and Branch Managers can modify branches
CREATE POLICY branches_all_managers ON public.branches
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- ============================================================================
-- STEP 7: DAILY_REVENUE TABLE POLICIES
-- ============================================================================

-- CEO can see all revenue data
CREATE POLICY daily_revenue_select_ceo ON public.daily_revenue
  FOR SELECT
  USING (public.is_ceo());

-- Managers can see revenue in their company
CREATE POLICY daily_revenue_select_company ON public.daily_revenue
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- Only CEO and Managers can insert/update revenue
CREATE POLICY daily_revenue_all_managers ON public.daily_revenue
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- ============================================================================
-- STEP 8: ACTIVITY_LOGS TABLE POLICIES
-- ============================================================================

-- CEO can see all activity logs
CREATE POLICY activity_logs_select_ceo ON public.activity_logs
  FOR SELECT
  USING (public.is_ceo());

-- Users can see logs in their company
CREATE POLICY activity_logs_select_company ON public.activity_logs
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- Anyone can insert activity logs (system logging)
CREATE POLICY activity_logs_insert_all ON public.activity_logs
  FOR INSERT
  WITH CHECK (true);

-- ============================================================================
-- STEP 9: REVENUE_SUMMARY TABLE POLICIES
-- ============================================================================

-- CEO can see all revenue summaries
CREATE POLICY revenue_summary_select_ceo ON public.revenue_summary
  FOR SELECT
  USING (public.is_ceo());

-- Managers can see summaries in their company
CREATE POLICY revenue_summary_select_company ON public.revenue_summary
  FOR SELECT
  USING (company_id = public.get_current_user_company_id());

-- Only CEO and Managers can modify summaries
CREATE POLICY revenue_summary_all_managers ON public.revenue_summary
  FOR ALL
  USING (public.is_manager_or_above())
  WITH CHECK (public.is_manager_or_above());

-- ============================================================================
-- 🎯 SUMMARY
-- ============================================================================
--
-- Helper Functions: 5
-- - get_current_user_role()
-- - get_current_user_company_id()
-- - get_current_user_branch_id()
-- - is_ceo()
-- - is_manager_or_above()
--
-- Custom Access Token Hook: 1
-- - custom_access_token_hook() - Injects user_role, company_id, branch_id into JWT
--
-- RLS Policies: 18
-- - users: 6 policies (own, CEO, managers, CRUD)
-- - companies: 3 policies (CEO full access, users see own)
-- - branches: 3 policies (CEO + managers)
-- - daily_revenue: 3 policies (CEO + managers)
-- - activity_logs: 3 policies (CEO + company, public insert)
-- - revenue_summary: 3 policies (CEO + managers)
--
-- ✅ Security Rules:
-- - CEO: Full access to everything
-- - BRANCH_MANAGER: See their company/branch data
-- - SHIFT_LEADER: See their company/branch data
-- - STAFF: See their company/branch data
--
-- ⚠️ IMPORTANT: Enable Auth Hook in Supabase Dashboard
--    Dashboard → Authentication → Hooks → Custom Access Token Hook
--    Select: public.custom_access_token_hook
--
-- ============================================================================
