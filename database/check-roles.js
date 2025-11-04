const { Client } = require('pg');
const path = require('path');

// Load environment variables from parent directory
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

if (!connectionString) {
    console.error('❌ SUPABASE_CONNECTION_STRING not found in .env');
    process.exit(1);
}

async function checkRoleConstraint() {
    const client = new Client({
        connectionString: connectionString,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        console.log('🔄 Connecting to check role constraint...');
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        // Check role constraint
        const constraintResult = await client.query(`
            SELECT 
                conname as constraint_name,
                pg_get_constraintdef(oid) as check_clause
            FROM pg_constraint 
            WHERE conname LIKE '%role%'
            AND conrelid = 'users'::regclass;
        `);
        
        console.log('🔍 Role constraints:');
        for (const row of constraintResult.rows) {
            console.log(`  - ${row.constraint_name}: ${row.check_clause}`);
        }
        
        // Check valid roles
        const roleEnum = await client.query(`
            SELECT enumlabel 
            FROM pg_enum 
            JOIN pg_type ON pg_enum.enumtypid = pg_type.oid 
            WHERE pg_type.typname = 'user_role';
        `);
        
        if (roleEnum.rows.length > 0) {
            console.log('\n📋 Valid roles from enum:');
            for (const row of roleEnum.rows) {
                console.log(`  - ${row.enumlabel}`);
            }
        } else {
            console.log('\n📋 No enum type found, checking constraint directly...');
        }
        
    } catch (error) {
        console.error('❌ Error checking role constraint:', error.message);
        process.exit(1);
    } finally {
        await client.end();
        console.log('\n🔌 Connection closed');
    }
}

// Run the check
checkRoleConstraint();