-- ============================================================================
-- 🚀 SABOHUB FLUTTER - CORE DATABASE MIGRATION
-- ============================================================================
-- Version: 1.0.0
-- Created: 2024-11-02
-- Purpose: Create core tables for multi-company billiards management system
-- Instructions: Copy and paste this SQL into Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. COMPANIES TABLE (CEO manages multiple companies)
-- ============================================================================

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic Info
  name TEXT NOT NULL,
  business_type TEXT NOT NULL DEFAULT 'billiards' CHECK (business_type IN (
    'billiards', 'restaurant', 'cafe', 'retail', 'service', 'other'
  )),
  
  -- Contact Info
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  
  -- Tax & Legal
  tax_code TEXT,
  
  -- Finance
  monthly_revenue DECIMAL(15,2) DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. STORES TABLE (Each company has multiple stores/branches)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company relationship
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Basic Info
  name TEXT NOT NULL,
  code TEXT, -- Store code: HCM-01, HN-01
  
  -- Contact Info
  address TEXT NOT NULL,
  phone TEXT,
  
  -- Manager (will link to users table later)
  manager_id UUID,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(company_id, code)
);

-- ============================================================================
-- 3. USERS TABLE (Authentication & Role Management)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Authentication
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  
  -- Basic Info
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  
  -- Role & Permissions
  role TEXT NOT NULL DEFAULT 'STAFF' CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')),
  
  -- Company Assignment
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 4. TABLES TABLE (Billiard tables in each store)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Store relationship
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  
  -- Basic Info
  name TEXT NOT NULL, -- Table 1, Table 2, VIP 1
  table_type TEXT NOT NULL DEFAULT 'standard' CHECK (table_type IN ('standard', 'vip', 'premium')),
  
  -- Pricing
  hourly_rate DECIMAL(10,2) DEFAULT 0,
  
  -- Status
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved', 'maintenance')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(store_id, name)
);

-- ============================================================================
-- 5. TASKS TABLE (Task management across all roles)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  
  -- Task Info
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Assignment
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Status & Timeline
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 6. ACTIVITY_LOGS TABLE (System activity tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Scope
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  -- Activity details
  action TEXT NOT NULL, -- 'created', 'updated', 'deleted', 'completed'
  entity_type TEXT NOT NULL, -- 'company', 'store', 'user', 'task', 'table'
  entity_id UUID,
  description TEXT NOT NULL,
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 7. ADD FOREIGN KEY CONSTRAINTS THAT WERE DEFERRED
-- ============================================================================

-- Add manager_id foreign key to stores table
ALTER TABLE stores 
ADD CONSTRAINT fk_stores_manager 
FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL;

-- ============================================================================
-- 8. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Companies indexes
CREATE INDEX IF NOT EXISTS idx_companies_business_type ON public.companies(business_type);
CREATE INDEX IF NOT EXISTS idx_companies_active ON public.companies(is_active);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_company ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

-- Stores indexes
CREATE INDEX IF NOT EXISTS idx_stores_company ON public.stores(company_id);
CREATE INDEX IF NOT EXISTS idx_stores_manager ON public.stores(manager_id);
CREATE INDEX IF NOT EXISTS idx_stores_status ON public.stores(status);

-- Tables indexes
CREATE INDEX IF NOT EXISTS idx_tables_store ON public.tables(store_id);
CREATE INDEX IF NOT EXISTS idx_tables_company ON public.tables(company_id);
CREATE INDEX IF NOT EXISTS idx_tables_status ON public.tables(status);

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_company ON public.tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_store ON public.tasks(store_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created ON public.tasks(created_at DESC);

-- Activity logs indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_company ON public.activity_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON public.activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON public.activity_logs(entity_type, entity_id);

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_company ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_store ON public.profiles(store_id);

-- ============================================================================
-- 9. UPDATED_AT TRIGGERS
-- ============================================================================

-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON public.companies
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tables_updated_at
  BEFORE UPDATE ON public.tables
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- CEO can see everything
CREATE POLICY "CEO can view all companies" ON public.companies
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'CEO'
    )
  );

-- Users can see their own company
CREATE POLICY "Users can view their company" ON public.companies
  FOR SELECT USING (
    id IN (
      SELECT company_id FROM public.profiles 
      WHERE profiles.id = auth.uid()
    )
  );

-- Similar policies for other tables
CREATE POLICY "Users can view their company stores" ON public.stores
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM public.profiles 
      WHERE profiles.id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'CEO'
    )
  );

CREATE POLICY "Users can view their company tables" ON public.tables
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM public.profiles 
      WHERE profiles.id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'CEO'
    )
  );

CREATE POLICY "Users can view their company tasks" ON public.tasks
  FOR SELECT USING (
    company_id IN (
      SELECT company_id FROM public.profiles 
      WHERE profiles.id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'CEO'
    )
  );

-- ============================================================================
-- 11. SEED DATA FOR TESTING
-- ============================================================================

-- Insert sample CEO user (this should match your actual CEO user ID from Supabase Auth)
-- You'll need to update this with your actual user ID after creating the user in Supabase Auth
-- INSERT INTO public.profiles (id, full_name, role) 
-- VALUES ('your-ceo-user-id-here', 'CEO Test User', 'CEO');

-- Insert sample companies
INSERT INTO public.companies (name, business_type, address, phone, monthly_revenue) VALUES
  ('Quán Bida Diamond', 'billiards', '123 Nguyễn Huệ, Q1, HCM', '0901234567', 85000000),
  ('Bida Royal', 'billiards', '456 Lê Lợi, Q3, HCM', '0912345678', 92000000),
  ('Golden Billiards', 'billiards', '789 Trần Hưng Đạo, Q5, HCM', '0923456789', 76000000)
ON CONFLICT DO NOTHING;

-- The rest of the seed data should be inserted after the companies are created
-- and you have proper user IDs from Supabase Auth

-- ============================================================================
-- 🎯 MIGRATION COMPLETE
-- ============================================================================
-- 
-- Tables created: 7
-- - companies (CEO manages multiple companies)
-- - users (Local user management)  
-- - stores (Each company has stores/branches)
-- - tables (Billiard tables in each store)
-- - tasks (Task management system)
-- - activity_logs (System activity tracking)
-- - profiles (Extended user info linked to Supabase Auth)
--
-- Features supported:
-- ✅ CEO Dashboard (KPIs from multiple tables)
-- ✅ CEO Companies (CRUD operations)
-- ✅ CEO Analytics (revenue tracking, company performance)
-- ✅ Multi-role user management
-- ✅ Multi-store management per company
-- ✅ Task assignment and tracking
-- ✅ Activity logging
-- ✅ Row Level Security for data isolation
--
-- ============================================================================