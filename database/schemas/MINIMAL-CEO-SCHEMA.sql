-- ============================================================================
-- 🎯 MINIMAL CEO-FOCUSED SCHEMA
-- ============================================================================
-- Built bottom-up from Flutter frontend requirements
-- Start with CEO role and expand from there
-- ============================================================================

-- ============================================================================
-- STEP 1: CORE USER & AUTHENTICATION
-- ============================================================================

-- Users table (CEO là trung tâm)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Authentication (Supabase Auth integration)
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  
  -- Basic Info
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  
  -- Role & Permissions
  role TEXT NOT NULL CHECK (role IN ('CEO', 'BRANCH_MANAGER', 'SHIFT_LEADER', 'STAFF')),
  
  -- Company/Branch Assignment (CEO có thể null)
  company_id UUID, -- NULL cho CEO (xem tất cả companies)
  branch_id UUID,  -- NULL cho CEO (xem tất cả branches)
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 2: COMPANY MANAGEMENT (CEO quản lý nhiều công ty)
-- ============================================================================

-- Companies table
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic Info
  name TEXT NOT NULL,
  business_type TEXT NOT NULL CHECK (business_type IN (
    'restaurant', 'cafe', 'retail', 'service', 'other'
  )),
  
  -- Contact Info
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  
  -- Tax & Legal
  tax_code TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 3: BRANCH MANAGEMENT (Mỗi công ty có nhiều chi nhánh)
-- ============================================================================

-- Branches table
CREATE TABLE IF NOT EXISTS public.branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company relationship
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  
  -- Basic Info
  name TEXT NOT NULL,
  code TEXT, -- Chi nhánh HCM-01, HN-01
  
  -- Contact Info
  address TEXT,
  phone TEXT,
  
  -- Manager
  manager_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(company_id, code)
);

-- ============================================================================
-- STEP 4: CEO DASHBOARD KPIs (Dữ liệu cho Dashboard)
-- ============================================================================

-- Revenue tracking (theo ngày để tính KPI)
CREATE TABLE IF NOT EXISTS public.daily_revenue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  
  -- Date
  date DATE NOT NULL,
  
  -- Metrics
  total_revenue DECIMAL(15,2) DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  total_customers INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(company_id, branch_id, date)
);

-- Activity log (cho Recent Activities section)
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  
  -- Activity details
  action TEXT NOT NULL, -- 'created', 'updated', 'deleted', 'completed'
  entity_type TEXT NOT NULL, -- 'company', 'branch', 'user', 'task', 'order'
  entity_id UUID,
  description TEXT NOT NULL,
  
  -- Metadata
  metadata JSONB,
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- STEP 5: ANALYTICS DATA (Cho CEO Analytics Page)
-- ============================================================================

-- Revenue by period (pre-aggregated cho performance)
CREATE TABLE IF NOT EXISTS public.revenue_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
  
  -- Period
  period_type TEXT NOT NULL CHECK (period_type IN ('day', 'week', 'month', 'quarter', 'year')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  -- Metrics
  total_revenue DECIMAL(15,2) DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  total_customers INTEGER DEFAULT 0,
  avg_order_value DECIMAL(15,2) DEFAULT 0,
  
  -- Growth
  growth_percentage DECIMAL(5,2),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(company_id, branch_id, period_type, period_start)
);

-- ============================================================================
-- STEP 6: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_company ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_branch ON public.users(branch_id);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users(is_active);

-- Companies indexes
CREATE INDEX IF NOT EXISTS idx_companies_business_type ON public.companies(business_type);
CREATE INDEX IF NOT EXISTS idx_companies_active ON public.companies(is_active);

-- Branches indexes
CREATE INDEX IF NOT EXISTS idx_branches_company ON public.branches(company_id);
CREATE INDEX IF NOT EXISTS idx_branches_manager ON public.branches(manager_id);
CREATE INDEX IF NOT EXISTS idx_branches_active ON public.branches(is_active);

-- Daily revenue indexes
CREATE INDEX IF NOT EXISTS idx_daily_revenue_company ON public.daily_revenue(company_id);
CREATE INDEX IF NOT EXISTS idx_daily_revenue_branch ON public.daily_revenue(branch_id);
CREATE INDEX IF NOT EXISTS idx_daily_revenue_date ON public.daily_revenue(date DESC);

-- Activity logs indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_company ON public.activity_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON public.activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON public.activity_logs(entity_type, entity_id);

-- Revenue summary indexes
CREATE INDEX IF NOT EXISTS idx_revenue_summary_company ON public.revenue_summary(company_id);
CREATE INDEX IF NOT EXISTS idx_revenue_summary_period ON public.revenue_summary(period_type, period_start DESC);

-- ============================================================================
-- STEP 7: UPDATED_AT TRIGGERS
-- ============================================================================

-- Trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON public.companies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_branches_updated_at
  BEFORE UPDATE ON public.branches
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_daily_revenue_updated_at
  BEFORE UPDATE ON public.daily_revenue
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_revenue_summary_updated_at
  BEFORE UPDATE ON public.revenue_summary
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- STEP 8: FOREIGN KEY CONSTRAINTS (Add after base tables)
-- ============================================================================

-- Users -> Companies/Branches
ALTER TABLE public.users
  ADD CONSTRAINT fk_users_company 
  FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;

ALTER TABLE public.users
  ADD CONSTRAINT fk_users_branch 
  FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE SET NULL;

-- ============================================================================
-- 🎯 SUMMARY
-- ============================================================================
-- 
-- Tables created: 6
-- - users (Authentication & roles)
-- - companies (CEO manages multiple companies)
-- - branches (Each company has branches)
-- - daily_revenue (Daily metrics for KPIs)
-- - activity_logs (Recent activity feed)
-- - revenue_summary (Pre-aggregated analytics)
--
-- Indexes: 15 (for fast CEO dashboard queries)
-- Triggers: 5 (auto-update updated_at)
-- 
-- ✅ CEO Dashboard Features:
--    - View all companies
--    - View total revenue (aggregated from daily_revenue)
--    - View employee count (from users table)
--    - View recent activities (from activity_logs)
--
-- ✅ CEO Companies Page:
--    - CRUD operations on companies table
--    - View company stats (branches, employees)
--
-- ✅ CEO Analytics Page:
--    - Query revenue_summary by period (week/month/quarter/year)
--    - Compare companies performance
--
-- ============================================================================
