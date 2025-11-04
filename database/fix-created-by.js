const { Client } = require('pg');
require('dotenv').config({ path: '../.env' });

async function fixCreatedBy() {
    const client = new Client({
        connectionString: process.env.SUPABASE_CONNECTION_STRING,
        ssl: { rejectUnauthorized: false }
    });
    
    try {
        await client.connect();
        console.log('🔧 Adding created_by column to companies table...');
        
        await client.query(`
            ALTER TABLE companies 
            ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id);
        `);
        console.log('✅ created_by column added');
        
        // Update existing companies to have a created_by
        const result = await client.query(`
            UPDATE companies 
            SET created_by = (SELECT id FROM users WHERE role = 'CEO' LIMIT 1) 
            WHERE created_by IS NULL;
        `);
        console.log(`✅ Updated ${result.rowCount} companies with created_by`);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

fixCreatedBy();