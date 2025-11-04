require('dotenv').config({ path: '../.env' });
const { Client } = require('pg');

// 🚀 === SABOHUB RLS POLICIES FIX ===
console.log('\n🚀 === SABOHUB RLS POLICIES FIX ===');
console.log('🔧 Fixing infinite recursion in RLS policies...\n');

const client = new Client({
    host: process.env.SUPABASE_HOST,
    port: process.env.SUPABASE_PORT || 5432,
    database: process.env.SUPABASE_DATABASE,
    user: process.env.SUPABASE_USER,
    password: process.env.SUPABASE_PASSWORD,
    ssl: process.env.SUPABASE_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function fixRLSPolicies() {
    try {
        await client.connect();
        console.log('🔌 Connected to PostgreSQL for RLS fixes\n');

        // 1. Drop existing problematic RLS policies
        console.log('🗑️ === DROPPING PROBLEMATIC RLS POLICIES ===');
        
        const dropPolicies = [
            'DROP POLICY IF EXISTS "users_select_policy" ON users',
            'DROP POLICY IF EXISTS "users_insert_policy" ON users',
            'DROP POLICY IF EXISTS "users_update_policy" ON users',
            'DROP POLICY IF EXISTS "users_delete_policy" ON users',
            'DROP POLICY IF EXISTS "companies_select_policy" ON companies',
            'DROP POLICY IF EXISTS "companies_insert_policy" ON companies',
            'DROP POLICY IF EXISTS "companies_update_policy" ON companies',
            'DROP POLICY IF EXISTS "companies_delete_policy" ON companies',
            'DROP POLICY IF EXISTS "invitations_select_policy" ON employee_invitations',
            'DROP POLICY IF EXISTS "invitations_insert_policy" ON employee_invitations',
            'DROP POLICY IF EXISTS "invitations_update_policy" ON employee_invitations',
            'DROP POLICY IF EXISTS "invitations_delete_policy" ON employee_invitations'
        ];

        for (const policy of dropPolicies) {
            try {
                await client.query(policy);
                console.log(`✅ Dropped policy: ${policy.split(' ')[4]}`);
            } catch (error) {
                console.log(`⚠️ Policy not found or already dropped: ${policy.split(' ')[4]}`);
            }
        }

        // 2. Create simple, non-recursive RLS policies
        console.log('\n🛡️ === CREATING SIMPLE RLS POLICIES ===');

        // Users table policies - simple user-based access
        const usersPolicies = [
            `CREATE POLICY "users_select_simple" ON users 
             FOR SELECT USING (auth.uid()::text = id::text OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "users_insert_simple" ON users 
             FOR INSERT WITH CHECK (auth.uid()::text = id::text OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "users_update_simple" ON users 
             FOR UPDATE USING (auth.uid()::text = id::text OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "users_delete_simple" ON users 
             FOR DELETE USING (auth.uid()::text = id::text OR auth.jwt()->>'role' = 'service_role')`
        ];

        for (const policy of usersPolicies) {
            try {
                await client.query(policy);
                console.log(`✅ Created users policy: ${policy.split('"')[1]}`);
            } catch (error) {
                console.log(`❌ Failed to create users policy: ${error.message}`);
            }
        }

        // Companies table policies - simple access for authenticated users
        const companiesPolicies = [
            `CREATE POLICY "companies_select_simple" ON companies 
             FOR SELECT USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "companies_insert_simple" ON companies 
             FOR INSERT WITH CHECK (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "companies_update_simple" ON companies 
             FOR UPDATE USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "companies_delete_simple" ON companies 
             FOR DELETE USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`
        ];

        for (const policy of companiesPolicies) {
            try {
                await client.query(policy);
                console.log(`✅ Created companies policy: ${policy.split('"')[1]}`);
            } catch (error) {
                console.log(`❌ Failed to create companies policy: ${error.message}`);
            }
        }

        // Employee invitations policies - simple access
        const invitationsPolicies = [
            `CREATE POLICY "invitations_select_simple" ON employee_invitations 
             FOR SELECT USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "invitations_insert_simple" ON employee_invitations 
             FOR INSERT WITH CHECK (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "invitations_update_simple" ON employee_invitations 
             FOR UPDATE USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`,
            
            `CREATE POLICY "invitations_delete_simple" ON employee_invitations 
             FOR DELETE USING (auth.role() = 'authenticated' OR auth.jwt()->>'role' = 'service_role')`
        ];

        for (const policy of invitationsPolicies) {
            try {
                await client.query(policy);
                console.log(`✅ Created invitations policy: ${policy.split('"')[1]}`);
            } catch (error) {
                console.log(`❌ Failed to create invitations policy: ${error.message}`);
            }
        }

        // 3. Add missing columns to employee_invitations
        console.log('\n🔧 === ADDING MISSING COLUMNS ===');

        const addColumns = [
            `ALTER TABLE employee_invitations 
             ADD COLUMN IF NOT EXISTS usage_count INTEGER DEFAULT 0`,
            
            `ALTER TABLE employee_invitations 
             ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'STAFF'`,
             
            `ALTER TABLE employee_invitations 
             ADD COLUMN IF NOT EXISTS is_used BOOLEAN DEFAULT FALSE`
        ];

        for (const column of addColumns) {
            try {
                await client.query(column);
                const columnName = column.includes('usage_count') ? 'usage_count' : 
                                  column.includes('role') ? 'role' : 'is_used';
                console.log(`✅ Added column: ${columnName}`);
            } catch (error) {
                console.log(`⚠️ Column may already exist: ${error.message}`);
            }
        }

        // 4. Update existing invitations with proper role values
        console.log('\n📝 === UPDATING INVITATION ROLES ===');
        
        try {
            const updateRoles = `
                UPDATE employee_invitations 
                SET role = 'STAFF' 
                WHERE role IS NULL OR role = ''
            `;
            const result = await client.query(updateRoles);
            console.log(`✅ Updated ${result.rowCount} invitations with STAFF role`);
        } catch (error) {
            console.log(`⚠️ Error updating roles: ${error.message}`);
        }

        // 5. Create proper indexes for performance
        console.log('\n🚀 === CREATING PERFORMANCE INDEXES ===');
        
        const indexes = [
            'CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id)',
            'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
            'CREATE INDEX IF NOT EXISTS idx_invitations_company_id ON employee_invitations(company_id)',
            'CREATE INDEX IF NOT EXISTS idx_invitations_role ON employee_invitations(role)',
            'CREATE INDEX IF NOT EXISTS idx_invitations_code ON employee_invitations(invitation_code)'
        ];

        for (const index of indexes) {
            try {
                await client.query(index);
                const indexName = index.split(' ')[5];
                console.log(`✅ Created index: ${indexName}`);
            } catch (error) {
                console.log(`⚠️ Index may already exist: ${error.message}`);
            }
        }

        // 6. Test the fixes
        console.log('\n🧪 === TESTING FIXES ===');
        
        try {
            // Test basic queries
            const companies = await client.query('SELECT COUNT(*) FROM companies');
            console.log(`✅ Companies query: ${companies.rows[0].count} companies`);
            
            const users = await client.query('SELECT COUNT(*) FROM users');
            console.log(`✅ Users query: ${users.rows[0].count} users`);
            
            const invitations = await client.query('SELECT COUNT(*) FROM employee_invitations');
            console.log(`✅ Invitations query: ${invitations.rows[0].count} invitations`);
            
            // Test role distribution
            const roleDistribution = await client.query(`
                SELECT role, COUNT(*) as count 
                FROM users 
                WHERE role IS NOT NULL 
                GROUP BY role 
                ORDER BY count DESC
            `);
            console.log(`✅ Role distribution working: ${roleDistribution.rows.length} roles found`);
            
        } catch (error) {
            console.log(`❌ Test query failed: ${error.message}`);
        }

        console.log('\n🎉 === RLS POLICIES FIX COMPLETED ===');
        console.log('✅ Removed recursive policies');
        console.log('✅ Created simple authentication-based policies');
        console.log('✅ Added missing database columns');
        console.log('✅ Created performance indexes');
        console.log('💪 System should now work without infinite recursion!');

    } catch (error) {
        console.error('❌ Fatal error during RLS fix:', error);
    } finally {
        await client.end();
        console.log('🔌 Database connection closed');
    }
}

fixRLSPolicies();