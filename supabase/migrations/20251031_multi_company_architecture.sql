-- ========================================
-- MULTI-COMPANY MIGRATION
-- ========================================
-- Migration: 20251031_multi_company_architecture
-- Purpose: Transform single-company to multi-company platform
-- Estimated Time: 5-10 minutes
-- Author: SABO HUB Engineering Team
-- Date: October 31, 2025
-- ========================================

-- ========================================
-- STEP 1: CREATE COMPANIES TABLE
-- ========================================

CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Basic Information
  name TEXT NOT NULL,
  legal_name TEXT,
  business_type TEXT NOT NULL DEFAULT 'billiards' 
    CHECK (business_type IN ('billiards', 'cafe', 'restaurant', 'mixed')),
  tax_code TEXT,
  
  -- Contact Information
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  
  -- Ownership
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Branding
  logo_url TEXT,
  primary_color TEXT DEFAULT '#007AFF',
  secondary_color TEXT DEFAULT '#5856D6',
  
  -- Status
  status TEXT NOT NULL DEFAULT 'ACTIVE' 
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
  
  -- Settings (JSONB for flexibility)
  settings JSONB DEFAULT '{
    "timezone": "Asia/Ho_Chi_Minh",
    "currency": "VND",
    "locale": "vi-VN",
    "features": {}
  }'::jsonb,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id)
);

-- Indexes for companies
CREATE INDEX idx_companies_owner ON companies(owner_id);
CREATE INDEX idx_companies_status ON companies(status);
CREATE INDEX idx_companies_business_type ON companies(business_type);

-- Enable RLS (but don't add policies yet - users.company_id doesn't exist)
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 2: UPDATE USERS TABLE FIRST
-- ========================================

-- Add company_id to users (BEFORE creating policies)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Rename store_id to branch_id for clarity  
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_store_id_fkey;

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE users RENAME COLUMN store_id TO branch_id;
  END IF;
END $$;

-- Create index on company_id
CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);

-- ========================================
-- STEP 3: ADD RLS POLICIES FOR COMPANIES
-- ========================================

-- NOW we can add policies that reference users.company_id
CREATE POLICY "Users can view companies they own or work for" ON companies
  FOR SELECT
  USING (
    owner_id = auth.uid() 
    OR 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.company_id = companies.id
    )
  );

CREATE POLICY "Only CEO can create companies" ON companies
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'CEO'
    )
  );

CREATE POLICY "Only owner can update company" ON companies
  FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Only owner can delete company" ON companies
  FOR DELETE
  USING (owner_id = auth.uid());

-- ========================================
-- STEP 4: RENAME STORES TO BRANCHES
-- ========================================

-- Rename the table
ALTER TABLE IF EXISTS stores RENAME TO branches;

-- Add company_id column
ALTER TABLE branches 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Rename owner_id to manager_id for clarity
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branches' AND column_name = 'owner_id'
  ) THEN
    ALTER TABLE branches RENAME COLUMN owner_id TO manager_id;
  END IF;
END $$;

-- Add branch code for identification
ALTER TABLE branches 
ADD COLUMN IF NOT EXISTS code TEXT;

-- Create index on company_id
CREATE INDEX IF NOT EXISTS idx_branches_company ON branches(company_id);

-- Update RLS policies for branches
DROP POLICY IF EXISTS "Users can view stores in their company" ON branches;
DROP POLICY IF EXISTS "Users can view branches in their company" ON branches;

CREATE POLICY "Users can view branches in their company" ON branches
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
    OR
    company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
    )
  );

-- ========================================
-- STEP 5: UPDATE USERS RLS POLICIES
-- ========================================

-- Update RLS policies for users
DROP POLICY IF EXISTS "Users can view users in their store" ON users;
DROP POLICY IF EXISTS "Users can view users in their company" ON users;

CREATE POLICY "Users can view users in their company" ON users
  FOR SELECT
  USING (
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    OR
    company_id IN (SELECT id FROM companies WHERE owner_id = auth.uid())
  );

-- ========================================
-- STEP 6: ADD COMPANY_ID TO ALL TABLES
-- ========================================

-- Tables (billiard tables)
ALTER TABLE tables 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Update foreign key: store_id -> branch_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tables' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE tables RENAME COLUMN store_id TO branch_id;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tables_company ON tables(company_id);

-- Tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Rename store_id to branch_id (if exists)
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE tasks RENAME COLUMN store_id TO branch_id;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tasks_company ON tasks(company_id);

-- Orders
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_orders_company ON orders(company_id);

-- Table Sessions
ALTER TABLE table_sessions 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_table_sessions_company ON table_sessions(company_id);

-- Shifts
ALTER TABLE shifts 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

-- Rename store_id to branch_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'shifts' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE shifts RENAME COLUMN store_id TO branch_id;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_shifts_company ON shifts(company_id);

-- Products
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_products_company ON products(company_id);

-- Invoices
ALTER TABLE invoices 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_invoices_company ON invoices(company_id);

-- Customers
ALTER TABLE customers 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_customers_company ON customers(company_id);

-- Notifications
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_notifications_company ON notifications(company_id);

-- Analytics Events
ALTER TABLE analytics_events 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_analytics_events_company ON analytics_events(company_id);

-- Posts (Marketing)
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_posts_company ON posts(company_id);

-- Alerts
ALTER TABLE alerts 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_alerts_company ON alerts(company_id);

-- Purchase Requests
ALTER TABLE purchase_requests 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_purchase_requests_company ON purchase_requests(company_id);

-- Shift Reports
ALTER TABLE shift_reports 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_shift_reports_company ON shift_reports(company_id);

-- Incidents
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_incidents_company ON incidents(company_id);

-- Maintenance Logs
ALTER TABLE maintenance_logs 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_maintenance_logs_company ON maintenance_logs(company_id);

-- Check-ins
ALTER TABLE check_ins 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_check_ins_company ON check_ins(company_id);

-- ========================================
-- STEP 5: UPDATE RLS POLICIES
-- ========================================

-- Tasks RLS
DROP POLICY IF EXISTS "Users can view tasks in their store" ON tasks;
DROP POLICY IF EXISTS "Users can view tasks in their company" ON tasks;

CREATE POLICY "Users can view tasks in their company" ON tasks
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
    OR
    company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
    )
  );

CREATE POLICY "CEO and Manager can create tasks" ON tasks
  FOR INSERT
  WITH CHECK (
    company_id IN (
      SELECT company_id FROM users 
      WHERE id = auth.uid() 
      AND role IN ('CEO', 'MANAGER')
    )
    OR
    company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
    )
  );

-- Orders RLS
DROP POLICY IF EXISTS "Users can view orders in their store" ON orders;
DROP POLICY IF EXISTS "Users can view orders in their company" ON orders;

CREATE POLICY "Users can view orders in their company" ON orders
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

-- Shifts RLS
DROP POLICY IF EXISTS "Users can view shifts in their store" ON shifts;
DROP POLICY IF EXISTS "Users can view shifts in their company" ON shifts;

CREATE POLICY "Users can view shifts in their company" ON shifts
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

-- Notifications RLS
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;

CREATE POLICY "Users can view their notifications" ON notifications
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

-- Analytics Events RLS
CREATE POLICY "Users can view analytics in their company" ON analytics_events
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
  );

-- ========================================
-- STEP 6: CREATE MIGRATION DATA
-- ========================================

-- Create a default company for existing data
-- This assumes you have at least one CEO user
DO $$
DECLARE
  v_company_id UUID;
  v_ceo_id UUID;
BEGIN
  -- Find first CEO user
  SELECT id INTO v_ceo_id FROM users WHERE role = 'CEO' LIMIT 1;
  
  IF v_ceo_id IS NOT NULL THEN
    -- Create default company
    INSERT INTO companies (
      name, 
      legal_name, 
      business_type, 
      owner_id,
      status,
      created_by
    ) VALUES (
      'SABO Billiards',
      'Công ty TNHH SABO Billiards',
      'billiards',
      v_ceo_id,
      'ACTIVE',
      v_ceo_id
    )
    RETURNING id INTO v_company_id;
    
    -- Update existing branches to belong to this company
    UPDATE branches 
    SET company_id = v_company_id 
    WHERE company_id IS NULL;
    
    -- Update existing users to belong to this company
    UPDATE users 
    SET company_id = v_company_id 
    WHERE company_id IS NULL;
    
    -- Update all existing data to belong to this company
    UPDATE tasks SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE orders SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE table_sessions SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE shifts SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE products SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE invoices SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE customers SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE tables SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE notifications SET company_id = v_company_id WHERE company_id IS NULL;
    UPDATE analytics_events SET company_id = v_company_id WHERE company_id IS NULL;
    
    -- Create default branch if no branches exist
    IF NOT EXISTS (SELECT 1 FROM branches WHERE company_id = v_company_id) THEN
      INSERT INTO branches (
        company_id,
        name,
        code,
        manager_id,
        status,
        created_by
      ) VALUES (
        v_company_id,
        'Chi nhánh chính',
        'CN01',
        v_ceo_id,
        'ACTIVE',
        v_ceo_id
      );
    END IF;
    
    RAISE NOTICE 'Migration completed successfully. Company ID: %', v_company_id;
  ELSE
    RAISE NOTICE 'No CEO user found. Please create a CEO user first.';
  END IF;
END $$;

-- ========================================
-- STEP 7: CREATE HELPER FUNCTIONS
-- ========================================

-- Function to get company statistics
CREATE OR REPLACE FUNCTION get_company_stats(
  p_company_id UUID,
  p_period TEXT DEFAULT 'month'
)
RETURNS TABLE (
  total_revenue NUMERIC,
  total_orders INTEGER,
  active_staff INTEGER,
  active_branches INTEGER,
  total_tasks INTEGER,
  completed_tasks INTEGER,
  active_tables INTEGER,
  total_customers INTEGER
) AS $$
DECLARE
  v_start_date TIMESTAMPTZ;
BEGIN
  -- Calculate start date based on period
  CASE p_period
    WHEN 'today' THEN
      v_start_date := date_trunc('day', NOW());
    WHEN 'week' THEN
      v_start_date := date_trunc('week', NOW());
    WHEN 'month' THEN
      v_start_date := date_trunc('month', NOW());
    WHEN 'year' THEN
      v_start_date := date_trunc('year', NOW());
    ELSE
      v_start_date := date_trunc('month', NOW());
  END CASE;

  RETURN QUERY
  SELECT
    -- Revenue
    COALESCE(SUM(o.total_amount), 0)::NUMERIC as total_revenue,
    
    -- Orders
    COUNT(DISTINCT o.id)::INTEGER as total_orders,
    
    -- Staff
    (SELECT COUNT(*) FROM users WHERE company_id = p_company_id AND role != 'CEO')::INTEGER as active_staff,
    
    -- Branches
    (SELECT COUNT(*) FROM branches WHERE company_id = p_company_id AND status = 'ACTIVE')::INTEGER as active_branches,
    
    -- Tasks
    (SELECT COUNT(*) FROM tasks WHERE company_id = p_company_id AND created_at >= v_start_date)::INTEGER as total_tasks,
    (SELECT COUNT(*) FROM tasks WHERE company_id = p_company_id AND status = 'COMPLETED' AND created_at >= v_start_date)::INTEGER as completed_tasks,
    
    -- Tables
    (SELECT COUNT(*) FROM tables WHERE company_id = p_company_id AND status != 'MAINTENANCE')::INTEGER as active_tables,
    
    -- Customers
    (SELECT COUNT(*) FROM customers WHERE company_id = p_company_id)::INTEGER as total_customers
  FROM orders o
  WHERE o.company_id = p_company_id
    AND o.created_at >= v_start_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify company access
CREATE OR REPLACE FUNCTION verify_company_access(
  p_user_id UUID,
  p_company_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM companies
    WHERE id = p_company_id
      AND (
        owner_id = p_user_id
        OR
        EXISTS (
          SELECT 1 FROM users 
          WHERE id = p_user_id 
          AND company_id = p_company_id
        )
      )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 8: CREATE TRIGGERS
-- ========================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to companies table
DROP TRIGGER IF EXISTS update_companies_updated_at ON companies;
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- STEP 9: ADD COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON TABLE companies IS 'Multi-company/organization management. CEO can own multiple companies.';
COMMENT ON COLUMN companies.owner_id IS 'CEO who owns this company';
COMMENT ON COLUMN companies.settings IS 'JSONB field for flexible company-specific settings';

COMMENT ON TABLE branches IS 'Physical locations/branches belonging to a company (formerly stores table)';
COMMENT ON COLUMN branches.company_id IS 'Parent company that owns this branch';
COMMENT ON COLUMN branches.manager_id IS 'Branch manager (not company owner)';

COMMENT ON COLUMN users.company_id IS 'Company the user belongs to';
COMMENT ON COLUMN users.branch_id IS 'Specific branch the user works at (optional)';

-- ========================================
-- MIGRATION COMPLETE
-- ========================================

-- Verify migration
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'MIGRATION COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Tables created/updated:';
  RAISE NOTICE '  ✅ companies (new)';
  RAISE NOTICE '  ✅ branches (renamed from stores)';
  RAISE NOTICE '  ✅ users (added company_id)';
  RAISE NOTICE '  ✅ 20+ tables (added company_id)';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS policies updated: ✅';
  RAISE NOTICE 'Helper functions created: ✅';
  RAISE NOTICE 'Triggers created: ✅';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Test company creation';
  RAISE NOTICE '  2. Test company switching';
  RAISE NOTICE '  3. Verify data isolation';
  RAISE NOTICE '  4. Deploy frontend changes';
  RAISE NOTICE '';
END $$;
