"""
Create employee with Supabase Auth user
This allows employees to login using Supabase auth system
"""
import psycopg2

CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

sql = """
-- Create function to create employee WITH auth user
CREATE OR REPLACE FUNCTION create_employee_with_auth(
    p_company_id UUID,
    p_username TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_email TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_branch_id UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_employee_id UUID;
    v_auth_user_id UUID;
    v_password_hash TEXT;
    v_auth_email TEXT;
    v_result JSON;
BEGIN
    -- Generate UUID for employee
    v_employee_id := gen_random_uuid();
    
    -- Hash password
    v_password_hash := crypt(p_password, gen_salt('bf'));
    
    -- Generate email if not provided (required for auth.users)
    -- Format: username@company_id.employee.local
    IF p_email IS NULL OR p_email = '' THEN
        v_auth_email := p_username || '@' || p_company_id || '.employee.local';
    ELSE
        v_auth_email := p_email;
    END IF;
    
    -- Create auth user (using service role)
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        aud,
        role,
        created_at,
        updated_at
    )
    VALUES (
        v_employee_id,
        '00000000-0000-0000-0000-000000000000',
        v_auth_email,
        v_password_hash,
        NOW(),
        jsonb_build_object('provider', 'employee', 'providers', ARRAY['employee']),
        jsonb_build_object(
            'username', p_username,
            'full_name', p_full_name,
            'role', p_role,
            'company_id', p_company_id
        ),
        'authenticated',
        'authenticated',
        NOW(),
        NOW()
    );
    
    -- Create employee record
    INSERT INTO employees (
        id,
        company_id,
        username,
        password_hash,
        full_name,
        role,
        email,
        phone,
        branch_id,
        is_active,
        created_at,
        updated_at
    )
    VALUES (
        v_employee_id,
        p_company_id,
        p_username,
        v_password_hash,
        p_full_name,
        p_role,
        p_email,
        p_phone,
        p_branch_id,
        TRUE,
        NOW(),
        NOW()
    );
    
    -- Return success with employee data
    v_result := json_build_object(
        'success', TRUE,
        'employee', json_build_object(
            'id', v_employee_id,
            'company_id', p_company_id,
            'username', p_username,
            'full_name', p_full_name,
            'role', p_role,
            'email', COALESCE(p_email, v_auth_email),
            'phone', p_phone,
            'is_active', TRUE
        )
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', 'Username already exists in this company'
        );
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', FALSE,
            'error', SQLERRM
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_employee_with_auth TO authenticated;
GRANT EXECUTE ON FUNCTION create_employee_with_auth TO anon;
"""

print("🔧 Creating function to create employee with auth...")

try:
    conn = psycopg2.connect(CONNECTION_STRING)
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("✅ Connected!")
    print("🔧 Executing SQL...")
    
    cursor.execute(sql)
    
    print("✅ Function created successfully!")
    print("\n📋 Function: create_employee_with_auth")
    print("   Creates employee record + Supabase auth user")
    print("   Returns: JSON with success/error")
    
    cursor.close()
    conn.close()
    
    print("\n✅ Done! Now update EmployeeAuthService to use this function")
    
except Exception as e:
    print(f"❌ Error: {e}")
