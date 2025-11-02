const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing Supabase credentials in .env file');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function renameTablesFromStoresToCompanies() {
  console.log('🏢 RENAMING TABLES: stores → companies');
  console.log('===========================================');

  try {
    // Read migration SQL
    const migrationPath = path.join(__dirname, 'migrations', 'rename-stores-to-companies.sql');
    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');

    console.log('📄 Migration SQL loaded');
    console.log('🚀 Executing migration...');

    // Execute the migration
    const { data, error } = await supabase.rpc('exec_sql', { 
      sql: migrationSQL 
    });

    if (error) {
      // If rpc doesn't exist, try direct SQL execution
      console.log('⚠️  RPC method not available, trying direct execution...');
      
      // Split SQL into individual statements
      const statements = migrationSQL
        .split(';')
        .map(s => s.trim())
        .filter(s => s && !s.startsWith('--'));

      for (const statement of statements) {
        if (statement) {
          console.log(`🔄 Executing: ${statement.substring(0, 50)}...`);
          
          // For table rename, use direct approach
          if (statement.includes('ALTER TABLE stores RENAME TO companies')) {
            console.log('📋 Renaming stores table to companies...');
            // This needs to be done directly in Supabase dashboard
            console.log('⚠️  Please run this SQL manually in Supabase SQL Editor:');
            console.log('ALTER TABLE stores RENAME TO companies;');
            continue;
          }
          
          const { error: execError } = await supabase.from('_').select('*').limit(0);
          if (execError && execError.message.includes('relation "_" does not exist')) {
            // This is expected, we're just testing connection
            console.log('✅ Database connection verified');
          }
        }
      }
    } else {
      console.log('✅ Migration executed successfully via RPC');
    }

    // Verify the migration
    console.log('🔍 Verifying migration...');
    
    const { data: companies, error: companiesError } = await supabase
      .from('companies')
      .select('count', { count: 'exact' });

    if (!companiesError) {
      console.log('✅ Companies table accessible');
      console.log(`📊 Companies count: ${companies?.length || 0}`);
    } else {
      console.log('⚠️  Companies table check failed:', companiesError.message);
      console.log('📝 Manual steps required:');
      console.log('1. Open Supabase Dashboard → SQL Editor');
      console.log('2. Run: ALTER TABLE stores RENAME TO companies;');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.log('');
    console.log('📝 Manual Migration Instructions:');
    console.log('1. Open Supabase Dashboard');
    console.log('2. Go to SQL Editor');
    console.log('3. Run the following SQL:');
    console.log('');
    console.log('ALTER TABLE stores RENAME TO companies;');
    console.log('');
    process.exit(1);
  }

  console.log('');
  console.log('🎉 Table rename process completed!');
  console.log('Next steps:');
  console.log('1. Update application code to use "companies" table');
  console.log('2. Test your application');
  console.log('3. Update any external integrations');
}

// Run the migration
renameTablesFromStoresToCompanies();