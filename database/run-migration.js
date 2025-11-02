const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = process.env.SUPABASE_CONNECTION_STRING;
const sqlFile = path.join(__dirname, 'migrations', '999_fix_rls_infinite_recursion.sql');

async function applyMigration() {
  const client = new Client({
    connectionString: connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully!');
    console.log('');
    
    console.log('📄 Reading SQL file...');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    console.log(`   Size: ${(sql.length / 1024).toFixed(2)} KB`);
    console.log('');
    
    console.log('🚀 Executing migration...');
    console.log('   This may take 10-30 seconds...');
    console.log('');
    
    await client.query(sql);
    
    console.log('');
    console.log('✅ Migration applied successfully!');
    console.log('');
    console.log('═══════════════════════════════════════════════════════');
    console.log('📝 NEXT STEPS:');
    console.log('═══════════════════════════════════════════════════════');
    console.log('');
    console.log('1️⃣  Enable Auth Hook in Supabase Dashboard:');
    console.log('   → Go to: Authentication → Hooks');
    console.log('   → Enable: "Custom Access Token"');
    console.log('   → Function: public.custom_access_token_hook');
    console.log('   → Click "Save"');
    console.log('');
    console.log('2️⃣  Test in your Flutter app:');
    console.log('   → All users MUST re-login!');
    console.log('   → Test CEO, Manager, Staff roles');
    console.log('   → Verify no "infinite recursion" errors');
    console.log('');
    console.log('🔗 Auth Hooks Dashboard:');
    console.log('   https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/hooks');
    console.log('');
    console.log('═══════════════════════════════════════════════════════');
    
  } catch (error) {
    console.error('');
    console.error('❌ ERROR APPLYING MIGRATION:');
    console.error('═══════════════════════════════════════════════════════');
    console.error('Message:', error.message);
    console.error('');
    if (error.detail) {
      console.error('Details:', error.detail);
      console.error('');
    }
    if (error.hint) {
      console.error('Hint:', error.hint);
      console.error('');
    }
    if (error.position) {
      console.error('Position in SQL:', error.position);
      console.error('');
    }
    console.error('═══════════════════════════════════════════════════════');
    process.exit(1);
  } finally {
    await client.end();
    console.log('🔌 Connection closed.');
  }
}

applyMigration();
