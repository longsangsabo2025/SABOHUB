-- ============================================================================
-- EMPLOYEE AUTHENTICATION SYSTEM
-- ============================================================================
-- Dual authentication model:
-- 1. CEO: Supabase Auth (email/password)
-- 2. Employees: Custom auth (company_name + username + password)
-- ============================================================================

-- ============================================================================
-- 1. CREATE EMPLOYEES TABLE (for non-auth users)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Company assignment
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  
  -- Login credentials
  username VARCHAR(50) NOT NULL, -- Unique within company
  password_hash TEXT NOT NULL, -- bcrypt hashed password
  
  -- Personal info
  full_name TEXT NOT NULL,
  email TEXT, -- Optional, for notifications
  phone TEXT,
  avatar_url TEXT,
  
  -- Role (NOT CEO - CEO uses auth.users)
  role TEXT NOT NULL CHECK (role IN ('MANAGER', 'SHIFT_LEADER', 'STAFF')),
  
  -- Branch assignment
  branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Audit fields
  created_by_ceo_id UUID REFERENCES auth.users(id), -- CEO who created this employee
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  
  -- Ensure username is unique within company
  CONSTRAINT unique_username_per_company UNIQUE(company_id, username)
);

-- ============================================================================
-- 2. INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_employees_company_id ON public.employees(company_id);
CREATE INDEX idx_employees_username ON public.employees(username);
CREATE INDEX idx_employees_company_username ON public.employees(company_id, username);
CREATE INDEX idx_employees_role ON public.employees(role);
CREATE INDEX idx_employees_is_active ON public.employees(is_active);
CREATE INDEX idx_employees_branch_id ON public.employees(branch_id);

-- ============================================================================
-- 3. AUTO UPDATE TIMESTAMP TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_employees_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_employees_updated_at
  BEFORE UPDATE ON public.employees
  FOR EACH ROW
  EXECUTE FUNCTION update_employees_updated_at();

-- ============================================================================
-- 4. ROW LEVEL SECURITY POLICIES
-- ============================================================================

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- CEO can view all employees in their companies
CREATE POLICY "ceo_view_all_employees"
  ON public.employees
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.companies
      WHERE companies.id = employees.company_id
      AND companies.created_by = auth.uid()
    )
  );

-- CEO can create employees for their companies
CREATE POLICY "ceo_create_employees"
  ON public.employees
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.companies
      WHERE companies.id = employees.company_id
      AND companies.created_by = auth.uid()
    )
  );

-- CEO can update employees in their companies
CREATE POLICY "ceo_update_employees"
  ON public.employees
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.companies
      WHERE companies.id = employees.company_id
      AND companies.created_by = auth.uid()
    )
  );

-- CEO can delete employees in their companies
CREATE POLICY "ceo_delete_employees"
  ON public.employees
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.companies
      WHERE companies.id = employees.company_id
      AND companies.created_by = auth.uid()
    )
  );

-- ============================================================================
-- 5. EMPLOYEE LOGIN FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.employee_login(
  p_company_name TEXT,
  p_username TEXT,
  p_password TEXT
)
RETURNS JSON AS $$
DECLARE
  v_employee RECORD;
  v_company_id UUID;
  v_password_match BOOLEAN;
BEGIN
  -- Find company by name (using is_active instead of status)
  SELECT id INTO v_company_id
  FROM public.companies
  WHERE LOWER(name) = LOWER(p_company_name)
  AND is_active = true
  LIMIT 1;
  
  IF v_company_id IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Company not found'
    );
  END IF;
  
  -- Find employee
  SELECT * INTO v_employee
  FROM public.employees
  WHERE company_id = v_company_id
  AND username = p_username
  AND is_active = true;
  
  IF v_employee IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid username or password'
    );
  END IF;
  
  -- Verify password (using pgcrypto extension)
  -- Note: Password should be hashed with bcrypt on client side first
  v_password_match := (v_employee.password_hash = crypt(p_password, v_employee.password_hash));
  
  IF NOT v_password_match THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Invalid username or password'
    );
  END IF;
  
  -- Update last login
  UPDATE public.employees
  SET last_login_at = NOW()
  WHERE id = v_employee.id;
  
  -- Return employee data (without password)
  RETURN json_build_object(
    'success', true,
    'employee', json_build_object(
      'id', v_employee.id,
      'company_id', v_employee.company_id,
      'username', v_employee.username,
      'full_name', v_employee.full_name,
      'email', v_employee.email,
      'phone', v_employee.phone,
      'role', v_employee.role,
      'branch_id', v_employee.branch_id,
      'avatar_url', v_employee.avatar_url
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. HELPER FUNCTION: Hash password
-- ============================================================================

CREATE OR REPLACE FUNCTION public.hash_password(p_password TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN crypt(p_password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 7. UPDATE USERS TABLE - Keep only for CEOs
-- ============================================================================

-- Add comment to clarify users table is now CEO-only
COMMENT ON TABLE public.users IS 'CEO users authenticated via Supabase Auth. Employees use employees table.';

-- Update users table constraint to enforce CEO role only (optional)
-- ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
-- ALTER TABLE public.users ADD CONSTRAINT users_role_check CHECK (role = 'CEO');

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- 
-- Tables created:
-- - employees (for Manager, Shift Leader, Staff)
-- 
-- Functions created:
-- - employee_login(company_name, username, password) → JSON response
-- - hash_password(password) → hashed password
-- 
-- Security:
-- - RLS policies ensure CEOs only see their own company employees
-- - Password hashing using bcrypt
-- - Login function returns employee data without sensitive info
-- 
-- Next steps:
-- 1. Update Flutter auth logic to support dual login
-- 2. Create CEO employee management UI
-- 3. Migrate existing non-CEO users to employees table
-- 
-- ============================================================================
