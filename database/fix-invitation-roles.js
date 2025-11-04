const { Client } = require('pg');
const path = require('path');

// Load environment variables from parent directory
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

async function checkAndFixInvitationRoles() {
    const client = new Client({
        connectionString: connectionString,
        ssl: { rejectUnauthorized: false }
    });

    try {
        await client.connect();
        console.log('🔧 === FIXING INVITATION ROLE CONSTRAINT ===');
        
        // Check current constraint
        const constraintResult = await client.query(`
            SELECT 
                conname as constraint_name,
                pg_get_constraintdef(oid) as check_clause
            FROM pg_constraint 
            WHERE conname LIKE '%role_type%'
            AND conrelid = 'employee_invitations'::regclass;
        `);
        
        console.log('🔍 Current constraints:');
        for (const row of constraintResult.rows) {
            console.log(`  - ${row.constraint_name}: ${row.check_clause}`);
        }
        
        // Drop old constraint if exists
        if (constraintResult.rows.length > 0) {
            const constraintName = constraintResult.rows[0].constraint_name;
            console.log(`🗑️ Dropping old constraint: ${constraintName}`);
            
            await client.query(`
                ALTER TABLE employee_invitations 
                DROP CONSTRAINT IF EXISTS ${constraintName};
            `);
            console.log('✅ Old constraint dropped');
        }
        
        // Add new constraint with correct roles
        console.log('➕ Adding new constraint with correct roles...');
        await client.query(`
            ALTER TABLE employee_invitations 
            ADD CONSTRAINT chk_valid_role_type 
            CHECK (role_type IN ('CEO', 'BRANCH_MANAGER', 'SHIFT_LEADER', 'STAFF'));
        `);
        console.log('✅ New constraint added with roles: CEO, BRANCH_MANAGER, SHIFT_LEADER, STAFF');
        
        // Test the fix
        console.log('🧪 Testing the fix...');
        try {
            const testResult = await client.query(`
                INSERT INTO employee_invitations (
                    company_id, 
                    created_by, 
                    invitation_code, 
                    role_type, 
                    expires_at
                ) VALUES (
                    (SELECT id FROM companies LIMIT 1),
                    (SELECT id FROM users WHERE role = 'CEO' LIMIT 1),
                    'TEST_STAFF_${Date.now()}',
                    'STAFF',
                    NOW() + INTERVAL '1 day'
                ) RETURNING id, role_type;
            `);
            
            if (testResult.rows.length > 0) {
                console.log('✅ Test passed! STAFF role accepted');
                
                // Cleanup test record
                await client.query('DELETE FROM employee_invitations WHERE id = $1', [testResult.rows[0].id]);
                console.log('🧹 Test record cleaned up');
            }
            
        } catch (error) {
            console.error('❌ Test failed:', error.message);
        }
        
    } catch (error) {
        console.error('❌ Error fixing constraint:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

// Run the fix
checkAndFixInvitationRoles();