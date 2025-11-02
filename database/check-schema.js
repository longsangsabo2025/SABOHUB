const { Client } = require('pg');

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

async function checkSchema() {
  const client = new Client({
    connectionString: connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!');
    console.log('');
    
    // Check users table structure
    console.log('📊 Checking USERS table structure:');
    console.log('═══════════════════════════════════════════');
    const usersColumns = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'users'
      ORDER BY ordinal_position;
    `);
    
    if (usersColumns.rows.length === 0) {
      console.log('❌ Table "users" does not exist!');
    } else {
      console.table(usersColumns.rows);
    }
    console.log('');
    
    // Check tasks table
    console.log('📊 Checking TASKS table structure:');
    console.log('═══════════════════════════════════════════');
    const tasksColumns = await client.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'tasks'
      ORDER BY ordinal_position;
    `);
    
    if (tasksColumns.rows.length === 0) {
      console.log('❌ Table "tasks" does not exist!');
    } else {
      console.table(tasksColumns.rows);
    }
    console.log('');
    
    // Check all tables in public schema
    console.log('📋 All tables in public schema:');
    console.log('═══════════════════════════════════════════');
    const tables = await client.query(`
      SELECT tablename
      FROM pg_tables
      WHERE schemaname = 'public'
      ORDER BY tablename;
    `);
    
    tables.rows.forEach(row => {
      console.log('  -', row.tablename);
    });
    console.log('');
    console.log('Total tables:', tables.rows.length);
    
  } catch (error) {
    console.error('');
    console.error('❌ ERROR:');
    console.error(error.message);
  } finally {
    await client.end();
  }
}

checkSchema();
