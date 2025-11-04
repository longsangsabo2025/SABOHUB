const { Client } = require('pg');

// Load environment variables
require('dotenv').config();

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

if (!connectionString) {
    console.error('❌ SUPABASE_CONNECTION_STRING not found in .env');
    process.exit(1);
}

async function checkSchema() {
    const client = new Client({
        connectionString: connectionString,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        console.log('🔄 Connecting to check current schema...');
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        // Check tables
        const tablesResult = await client.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;
        `);
        
        console.log('📊 Current tables:');
        tablesResult.rows.forEach(row => {
            console.log(`  - ${row.table_name}`);
        });
        
        // Check companies table structure if it exists
        const companiesExists = tablesResult.rows.some(row => row.table_name === 'companies');
        
        if (companiesExists) {
            console.log('\n🏢 Companies table structure:');
            const columnsResult = await client.query(`
                SELECT column_name, data_type, is_nullable 
                FROM information_schema.columns 
                WHERE table_name = 'companies' 
                AND table_schema = 'public'
                ORDER BY ordinal_position;
            `);
            
            columnsResult.rows.forEach(row => {
                console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
            });
        }
        
        // Check users table structure if it exists
        const usersExists = tablesResult.rows.some(row => row.table_name === 'users');
        
        if (usersExists) {
            console.log('\n👤 Users table structure:');
            const usersColumnsResult = await client.query(`
                SELECT column_name, data_type, is_nullable 
                FROM information_schema.columns 
                WHERE table_name = 'users' 
                AND table_schema = 'public'
                ORDER BY ordinal_position;
            `);
            
            usersColumnsResult.rows.forEach(row => {
                console.log(`  - ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
            });
        }
        
    } catch (error) {
        console.error('❌ Schema check failed:');
        console.error('   Error:', error.message);
        process.exit(1);
    } finally {
        await client.end();
        console.log('\n🔌 Connection closed');
    }
}

// Run the schema check
checkSchema();