
            -- Create exec_sql function
            
CREATE OR REPLACE FUNCTION exec_sql(sql text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result text;
BEGIN
    -- Only allow specific types of DDL operations for security
    IF sql ~* '^(ALTER TABLE|CREATE INDEX|CREATE FUNCTION|CREATE OR REPLACE FUNCTION|DROP POLICY|CREATE POLICY)' THEN
        EXECUTE sql;
        result := 'SQL executed successfully';
    ELSE
        RAISE EXCEPTION 'Operation not allowed: %', sql;
    END IF;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN format('Error: %s', SQLERRM);
END;
$$;

            
            -- Create get_system_stats function
            CREATE OR REPLACE FUNCTION get_system_stats()
            RETURNS json
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            DECLARE
                result json;
            BEGIN
                -- Get system statistics
                SELECT json_build_object(
                    'companies_count', (SELECT COUNT(*) FROM companies),
                    'users_count', (SELECT COUNT(*) FROM users),
                    'invitations_count', (SELECT COUNT(*) FROM employee_invitations),
                    'users_with_company', (SELECT COUNT(*) FROM users WHERE company_id IS NOT NULL),
                    'companies_with_users', (SELECT COUNT(DISTINCT company_id) FROM users WHERE company_id IS NOT NULL),
                    'role_stats', (
                        SELECT json_object_agg(role, count)
                        FROM (
                            SELECT 
                                COALESCE(role, 'NULL') as role, 
                                COUNT(*) as count 
                            FROM users 
                            GROUP BY role
                        ) role_counts
                    )
                ) INTO result;
                
                RETURN result;
            END;
            $$;
            
            -- Create update_invitation_columns function
            CREATE OR REPLACE FUNCTION update_invitation_columns()
            RETURNS text
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            DECLARE
                result text;
            BEGIN
                -- Add missing columns if they don't exist
                BEGIN
                    ALTER TABLE employee_invitations ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0;
                    ALTER TABLE employee_invitations ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'STAFF';
                    ALTER TABLE employee_invitations ADD COLUMN IF NOT EXISTS is_used BOOLEAN DEFAULT FALSE;
                    
                    -- Update existing records
                    UPDATE employee_invitations 
                    SET 
                        role = 'STAFF',
                        usage_count = 0,
                        is_used = false
                    WHERE role IS NULL OR role = '';
                    
                    result := 'Invitation columns updated successfully';
                EXCEPTION
                    WHEN OTHERS THEN
                        result := format('Error updating columns: %s', SQLERRM);
                END;
                
                RETURN result;
            END;
            $$;
            
            -- Create fix_rls_policies function
            CREATE OR REPLACE FUNCTION fix_rls_policies()
            RETURNS text
            LANGUAGE plpgsql
            SECURITY DEFINER
            SET search_path = public
            AS $$
            DECLARE
                result text;
            BEGIN
                -- Drop existing problematic policies
                DROP POLICY IF EXISTS "users_select_policy" ON users;
                DROP POLICY IF EXISTS "users_insert_policy" ON users;
                DROP POLICY IF EXISTS "users_update_policy" ON users;
                DROP POLICY IF EXISTS "users_delete_policy" ON users;
                
                -- Create simple policies that don't cause recursion
                CREATE POLICY "users_select_simple" ON users 
                FOR SELECT USING (true); -- Allow all for now
                
                CREATE POLICY "users_insert_simple" ON users 
                FOR INSERT WITH CHECK (true); -- Allow all for now
                
                CREATE POLICY "users_update_simple" ON users 
                FOR UPDATE USING (true); -- Allow all for now
                
                CREATE POLICY "users_delete_simple" ON users 
                FOR DELETE USING (true); -- Allow all for now
                
                result := 'RLS policies fixed successfully';
                
                RETURN result;
            EXCEPTION
                WHEN OTHERS THEN
                    result := format('Error fixing RLS: %s', SQLERRM);
                    RETURN result;
            END;
            $$;
        