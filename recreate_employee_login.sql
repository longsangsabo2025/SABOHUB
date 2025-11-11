-- ============================================================================
-- Recreate employee_login function with correct schema (is_active not status)
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
