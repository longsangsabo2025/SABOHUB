const { Client } = require('pg');
require('dotenv').config({ path: '../.env' });

async function fixCEOCompanyLink() {
    const client = new Client({
        connectionString: process.env.SUPABASE_CONNECTION_STRING,
        ssl: { rejectUnauthorized: false }
    });
    
    try {
        await client.connect();
        console.log('🔧 Fixing CEO-Company links...');
        
        // Link CEOs to their companies
        const result = await client.query(`
            UPDATE users 
            SET company_id = (SELECT id FROM companies LIMIT 1) 
            WHERE role = 'CEO' AND company_id IS NULL;
        `);
        console.log(`✅ Updated ${result.rowCount} CEOs with company links`);
        
        // Link managers to companies too
        const managerResult = await client.query(`
            UPDATE users 
            SET company_id = (SELECT id FROM companies LIMIT 1) 
            WHERE role IN ('BRANCH_MANAGER', 'SHIFT_LEADER') 
            AND company_id IS NULL;
        `);
        console.log(`✅ Updated ${managerResult.rowCount} managers with company links`);
        
        // Link staff to companies too
        const staffResult = await client.query(`
            UPDATE users 
            SET company_id = (SELECT id FROM companies LIMIT 1) 
            WHERE role = 'STAFF' AND company_id IS NULL;
        `);
        console.log(`✅ Updated ${staffResult.rowCount} staff with company links`);
        
        // Verify the fix
        const verifyResult = await client.query(`
            SELECT role, COUNT(*) as count, 
                   COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END) as with_company
            FROM users 
            GROUP BY role;
        `);
        
        console.log('\n📊 User-Company Link Status:');
        for (const row of verifyResult.rows) {
            console.log(`  ${row.role}: ${row.with_company}/${row.count} linked to company`);
        }
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

fixCEOCompanyLink();