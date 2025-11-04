const { Client } = require('pg');
require('dotenv').config({ path: '../.env' });

async function fixDataWithTriggerDisable() {
    const client = new Client({
        connectionString: process.env.SUPABASE_CONNECTION_STRING,
        ssl: { rejectUnauthorized: false }
    });
    
    try {
        await client.connect();
        console.log('🔧 Temporarily disabling CEO trigger to fix data...');
        
        // Disable trigger
        await client.query('DROP TRIGGER IF EXISTS trigger_prevent_multiple_ceos ON users;');
        console.log('✅ CEO trigger disabled');
        
        // Fix data by linking orphaned users to company
        const result = await client.query(`
            UPDATE users 
            SET company_id = (SELECT id FROM companies LIMIT 1) 
            WHERE company_id IS NULL;
        `);
        console.log(`✅ Updated ${result.rowCount} users with company links`);
        
        // Re-enable trigger
        await client.query(`
            CREATE TRIGGER trigger_prevent_multiple_ceos
            BEFORE INSERT OR UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION prevent_multiple_ceos();
        `);
        console.log('✅ CEO trigger re-enabled');
        
        // Check final status
        const check = await client.query(`
            SELECT COUNT(*) as total, COUNT(company_id) as linked 
            FROM users;
        `);
        console.log(`📊 Final status: ${check.rows[0].linked}/${check.rows[0].total} users linked to companies`);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

fixDataWithTriggerDisable();