-- Create RPC function to create employee with bcrypt password hash
-- This function allows CEO to create employees with hashed passwords

CREATE OR REPLACE FUNCTION create_employee_with_password(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_company_id UUID,
    p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(
    id UUID,
    email TEXT,
    full_name TEXT,
    role TEXT,
    company_id UUID,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_password_hash TEXT;
    v_employee_id UUID;
BEGIN
    -- Generate bcrypt hash for password
    v_password_hash := crypt(p_password, gen_salt('bf'));
    
    -- Insert employee with hashed password
    INSERT INTO employees (
        email,
        password_hash,
        full_name,
        role,
        company_id,
        is_active
    ) VALUES (
        p_email,
        v_password_hash,
        p_full_name,
        p_role,
        p_company_id,
        p_is_active
    )
    RETURNING 
        employees.id,
        employees.email,
        employees.full_name,
        employees.role,
        employees.company_id,
        employees.is_active,
        employees.created_at
    INTO 
        v_employee_id,
        p_email,
        p_full_name,
        p_role,
        p_company_id,
        p_is_active,
        created_at;
    
    -- Return the created employee
    RETURN QUERY
    SELECT 
        employees.id,
        employees.email,
        employees.full_name,
        employees.role,
        employees.company_id,
        employees.is_active,
        employees.created_at
    FROM employees
    WHERE employees.id = v_employee_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users (CEO)
GRANT EXECUTE ON FUNCTION create_employee_with_password TO authenticated;

-- Test the function
-- SELECT * FROM create_employee_with_password(
--     'test@example.com',
--     'password123',
--     'Test Employee',
--     'STAFF',
--     'feef10d3-899d-4554-8107-b2256918213a',
--     TRUE
-- );
