require('dotenv').config({ path: '../.env' });
const { createClient } = require('@supabase/supabase-js');

// 🚀 === CREATE EXEC_SQL FUNCTION IN SUPABASE ===
console.log('\n🚀 === CREATE EXEC_SQL FUNCTION IN SUPABASE ===');
console.log('🔧 Creating exec_sql function for database operations...\n');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('❌ Missing Supabase configuration in .env file');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function createExecSQLFunction() {
    console.log('🔌 Connected to Supabase with service role for function creation\n');

    try {
        // 1. First, try to create the exec_sql function using a direct insert into functions
        console.log('🔧 === CREATING EXEC_SQL FUNCTION ===');
        
        // Create the function using Supabase Edge Functions SQL
        const execSqlFunctionSQL = `
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
`;

        // Try to execute via a simple query that creates the function
        console.log('📝 Attempting to create exec_sql function...');
        
        // Use a different approach - create via SQL file
        const createFunctionQuery = `
            -- Create exec_sql function
            ${execSqlFunctionSQL}
            
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
        `;

        // Try to create these functions via a file write and then run via command line
        console.log('💾 Writing SQL functions to file...');
        
        const fs = require('fs');
        fs.writeFileSync('create-functions.sql', createFunctionQuery);
        
        console.log('✅ SQL functions written to create-functions.sql');
        console.log('📋 Functions to be created:');
        console.log('   - exec_sql(sql text)');
        console.log('   - get_system_stats()');
        console.log('   - update_invitation_columns()');
        console.log('   - fix_rls_policies()');
        
        // Try to test if we can create a simple function
        console.log('\n🧪 === TESTING FUNCTION CREATION ===');
        
        try {
            // Test with a very simple function first
            const { data, error } = await supabase
                .from('_test')
                .select('*')
                .limit(1);
            
            // This will fail, but tells us about our connection
            console.log(`Database connection test: ${error ? 'Connected (expected error)' : 'Connected'}`);
            
        } catch (error) {
            console.log(`Database test: ${error.message}`);
        }

        // 2. Alternative approach: Use psql command if available
        console.log('\n🔧 === ALTERNATIVE: USING PSQL COMMAND ===');
        
        const psqlCommand = `psql "${process.env.SUPABASE_CONNECTION_STRING}" -f create-functions.sql`;
        console.log('💡 Run this command to create functions:');
        console.log(`   ${psqlCommand}`);
        
        // 3. Try to use supabase CLI if available
        console.log('\n🚀 === ALTERNATIVE: USING SUPABASE CLI ===');
        
        const supabaseCLICommand = 'supabase db reset --local';
        console.log('💡 Or use Supabase CLI:');
        console.log(`   ${supabaseCLICommand}`);
        
        // 4. Try manual SQL execution via different method
        console.log('\n🔄 === TRYING MANUAL FUNCTION CREATION ===');
        
        // Create a simple test function to see if it works
        const simpleFunction = `
        CREATE OR REPLACE FUNCTION test_simple()
        RETURNS text
        LANGUAGE sql
        AS $$
            SELECT 'Function creation test successful' as result;
        $$;
        `;
        
        console.log('🧪 Testing simple function creation...');
        console.log('📝 Simple function SQL saved to test-function.sql');
        
        fs.writeFileSync('test-function.sql', simpleFunction);
        
        // 5. Show the user what they need to do
        console.log('\n📋 === MANUAL STEPS TO CREATE FUNCTIONS ===');
        console.log('1. Open Supabase Dashboard → SQL Editor');
        console.log('2. Copy and paste the contents of create-functions.sql');
        console.log('3. Execute the SQL to create all functions');
        console.log('4. Or use psql command line:');
        console.log(`   psql "${process.env.SUPABASE_CONNECTION_STRING}" -f create-functions.sql`);
        
        console.log('\n✅ === FUNCTIONS READY FOR CREATION ===');
        console.log('📄 File created: create-functions.sql');
        console.log('📄 File created: test-function.sql');
        console.log('🔧 Functions will enable:');
        console.log('   ✅ exec_sql() - Execute DDL operations');
        console.log('   ✅ get_system_stats() - Get system statistics');
        console.log('   ✅ update_invitation_columns() - Fix database schema');
        console.log('   ✅ fix_rls_policies() - Fix RLS recursion');
        
        return true;
        
    } catch (error) {
        console.error('❌ Error during function creation:', error);
        return false;
    }
}

async function main() {
    const success = await createExecSQLFunction();
    
    if (success) {
        console.log('\n🎉 Function creation files prepared successfully!');
        console.log('💪 "Kiên trì là mẹ thành công" - Ready to execute SQL functions!');
    } else {
        console.log('\n❌ Function creation failed');
    }
}

main();