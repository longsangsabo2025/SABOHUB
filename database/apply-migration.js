const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config();

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

if (!connectionString) {
    console.error('❌ SUPABASE_CONNECTION_STRING not found in .env');
    process.exit(1);
}

async function runMigration() {
    const client = new Client({
        connectionString: connectionString,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        console.log('🔄 Connecting to Supabase PostgreSQL...');
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        // Read migration file
        const sqlFile = path.join(__dirname, 'migrations', '002_employee_invitations.sql');
        if (!fs.existsSync(sqlFile)) {
            throw new Error(`Migration file not found: ${sqlFile}`);
        }
        
        const sql = fs.readFileSync(sqlFile, 'utf8');
        console.log(`📄 Loaded migration: ${sql.length} characters`);
        
        console.log('🚀 Executing migration...');
        await client.query(sql);
        
        console.log('✅ Migration executed successfully!');
        console.log('');
        console.log('📊 Employee Invitations table created with:');
        console.log('  - Unique invitation codes');
        console.log('  - Role-based access control');
        console.log('  - Expiration handling');
        console.log('  - Usage tracking');
        console.log('  - RLS security policies');
        
    } catch (error) {
        console.error('❌ Migration failed:');
        console.error('   Error:', error.message);
        
        // Provide helpful error context
        if (error.message.includes('already exists')) {
            console.log('💡 Table might already exist. This is usually safe to ignore.');
        } else if (error.message.includes('permission denied')) {
            console.log('💡 Check your SUPABASE_CONNECTION_STRING permissions.');
        }
        
        process.exit(1);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

// Run the migration
runMigration();