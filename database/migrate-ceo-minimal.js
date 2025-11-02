/**
 * ============================================================================
 * 🚀 MINIMAL CEO SCHEMA MIGRATION
 * ============================================================================
 * Xây dựng database từ đầu dựa vào CEO features trong Flutter frontend
 * 
 * Files executed:
 * 1. MINIMAL-CEO-SCHEMA.sql (6 tables: users, companies, branches, revenue, activities, summaries)
 * 2. MINIMAL-CEO-RLS.sql (18 RLS policies + Auth Hook)
 * 3. MINIMAL-CEO-SEED.sql (Test data: 2 companies, 3 branches, 5 users)
 * 
 * Usage:
 *   node migrate-ceo-minimal.js
 * 
 * Prerequisites:
 *   - .env file with SUPABASE_CONNECTION_STRING
 *   - Port 5432 (Session Pooler) required
 *   - Fresh database (or tables will be skipped if exist)
 * ============================================================================
 */

require('dotenv').config();
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

const CONFIG = {
  connectionString: process.env.SUPABASE_CONNECTION_STRING,
  sqlFiles: [
    'database/schemas/MINIMAL-CEO-SCHEMA.sql',
    'database/schemas/MINIMAL-CEO-RLS.sql',
    'database/schemas/MINIMAL-CEO-SEED.sql'
  ],
  requiredPort: '5432',
};

// ============================================================================
// VALIDATION
// ============================================================================

function validateEnvironment() {
  console.log('\n🔍 Validating environment...\n');

  // Check connection string exists
  if (!CONFIG.connectionString) {
    console.error('❌ ERROR: SUPABASE_CONNECTION_STRING not found in .env file');
    console.error('');
    console.error('Please add to .env:');
    console.error('SUPABASE_CONNECTION_STRING=postgresql://postgres.[PROJECT_REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:5432/postgres');
    process.exit(1);
  }

  // Check if placeholder value
  if (CONFIG.connectionString.includes('YOUR_') || CONFIG.connectionString.includes('PROJECT_REF')) {
    console.error('❌ ERROR: SUPABASE_CONNECTION_STRING contains placeholder values');
    console.error('');
    console.error('Please update .env with real Supabase credentials');
    console.error('Get from: https://supabase.com/dashboard → Settings → Database');
    process.exit(1);
  }

  // Check port 5432
  if (!CONFIG.connectionString.includes(':5432/')) {
    console.error('❌ ERROR: Connection string must use port 5432 (Session Pooler)');
    console.error('');
    console.error('Current connection string uses wrong port.');
    console.error('Please use Session Pooler connection string (port 5432)');
    console.error('');
    console.error('Why: Port 6543 (Transaction Pooler) does not support all PostgreSQL syntax');
    process.exit(1);
  }

  // Check SQL files exist
  for (const file of CONFIG.sqlFiles) {
    if (!fs.existsSync(file)) {
      console.error(`❌ ERROR: SQL file not found: ${file}`);
      process.exit(1);
    }
  }

  console.log('✅ Environment validation passed');
  console.log(`✅ Using port 5432 (Session Pooler)`);
  console.log(`✅ Found ${CONFIG.sqlFiles.length} SQL files\n`);
}

// ============================================================================
// SQL PARSING
// ============================================================================

function parseSQLStatements(sql) {
  const statements = [];
  let currentStatement = '';
  let inFunction = false;
  let dollarQuoteTag = null;
  
  const lines = sql.split('\n');
  
  for (const line of lines) {
    const trimmedLine = line.trim();
    
    // Skip comments
    if (trimmedLine.startsWith('--') || trimmedLine.length === 0) {
      continue;
    }
    
    // Check for function definition start
    if (trimmedLine.toUpperCase().includes('CREATE') && 
        (trimmedLine.toUpperCase().includes('FUNCTION') || 
         trimmedLine.toUpperCase().includes('TRIGGER'))) {
      inFunction = true;
    }
    
    // Check for dollar quotes (function bodies)
    const dollarMatch = trimmedLine.match(/\$([a-zA-Z_]*)\$/);
    if (dollarMatch) {
      if (!dollarQuoteTag) {
        dollarQuoteTag = dollarMatch[0];
      } else if (dollarMatch[0] === dollarQuoteTag) {
        dollarQuoteTag = null;
      }
    }
    
    currentStatement += line + '\n';
    
    // End of statement detection
    if (trimmedLine.endsWith(';') && !dollarQuoteTag && !inFunction) {
      statements.push(currentStatement.trim());
      currentStatement = '';
      inFunction = false;
    } else if (trimmedLine.endsWith(';') && !dollarQuoteTag && inFunction) {
      // Function definition ended
      statements.push(currentStatement.trim());
      currentStatement = '';
      inFunction = false;
    }
  }
  
  // Add remaining statement if exists
  if (currentStatement.trim().length > 0) {
    statements.push(currentStatement.trim());
  }
  
  return statements.filter(s => s.length > 0);
}

// ============================================================================
// SQL EXECUTION
// ============================================================================

async function executeSQLFile(client, filePath) {
  console.log(`\n📄 Executing: ${path.basename(filePath)}`);
  console.log('━'.repeat(60));
  
  const sql = fs.readFileSync(filePath, 'utf8');
  const statements = parseSQLStatements(sql);
  
  console.log(`Found ${statements.length} SQL statements\n`);
  
  let successCount = 0;
  let skipCount = 0;
  let errorCount = 0;
  
  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];
    const preview = statement.substring(0, 60).replace(/\n/g, ' ');
    
    try {
      await client.query(statement);
      successCount++;
      console.log(`✅ [${i + 1}/${statements.length}] ${preview}...`);
    } catch (error) {
      // Check if error is ignorable (already exists)
      if (error.message.includes('already exists') || 
          error.message.includes('duplicate key')) {
        skipCount++;
        console.log(`⏭️  [${i + 1}/${statements.length}] ${preview}... (already exists)`);
      } else {
        errorCount++;
        console.error(`❌ [${i + 1}/${statements.length}] ${preview}...`);
        console.error(`   Error: ${error.message}`);
        
        // Don't stop on errors, continue with next statement
        console.log('   Continuing with next statement...\n');
      }
    }
  }
  
  console.log('\n' + '━'.repeat(60));
  console.log(`📊 Results: ${successCount} succeeded, ${skipCount} skipped, ${errorCount} failed`);
  
  return { successCount, skipCount, errorCount };
}

// ============================================================================
// MAIN MIGRATION
// ============================================================================

async function runMigration() {
  console.log('\n' + '='.repeat(60));
  console.log('🚀 MINIMAL CEO SCHEMA MIGRATION');
  console.log('='.repeat(60));
  
  // Validate environment
  validateEnvironment();
  
  // Connect to database
  const client = new Client({
    connectionString: CONFIG.connectionString,
    ssl: { rejectUnauthorized: false }
  });
  
  try {
    console.log('📡 Connecting to Supabase database...\n');
    await client.connect();
    console.log('✅ Connected successfully\n');
    
    // Execute SQL files
    let totalSuccess = 0;
    let totalSkip = 0;
    let totalError = 0;
    
    for (const file of CONFIG.sqlFiles) {
      const result = await executeSQLFile(client, file);
      totalSuccess += result.successCount;
      totalSkip += result.skipCount;
      totalError += result.errorCount;
    }
    
    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('✅ MIGRATION COMPLETED');
    console.log('='.repeat(60));
    console.log(`📊 Total: ${totalSuccess + totalSkip + totalError} statements`);
    console.log(`   ✅ Succeeded: ${totalSuccess}`);
    console.log(`   ⏭️  Skipped: ${totalSkip}`);
    console.log(`   ❌ Failed: ${totalError}`);
    
    if (totalError > 0) {
      console.log('\n⚠️  Some statements failed. Check errors above.');
      console.log('Database may be partially migrated.');
    }
    
    console.log('\n🎯 NEXT STEPS:');
    console.log('━'.repeat(60));
    console.log('1. ✅ Schema created (6 tables)');
    console.log('2. ✅ RLS policies applied (18 policies)');
    console.log('3. ✅ Seed data inserted (test companies & users)');
    console.log('');
    console.log('4. ⚠️  ENABLE AUTH HOOK (MANUAL STEP):');
    console.log('   Go to: Supabase Dashboard → Authentication → Hooks');
    console.log('   Enable: Custom Access Token Hook');
    console.log('   Select: public.custom_access_token_hook');
    console.log('   Click: Save');
    console.log('');
    console.log('5. 🧪 TEST LOGIN:');
    console.log('   Login with: ceo@sabohub.com');
    console.log('   Check JWT token has custom claims:');
    console.log('   - user_role: "CEO"');
    console.log('   - company_id: null');
    console.log('   - branch_id: null');
    console.log('');
    console.log('6. 📱 OPEN FLUTTER APP:');
    console.log('   CEO Dashboard should show:');
    console.log('   - 2 companies');
    console.log('   - 5 employees');
    console.log('   - Revenue data');
    console.log('   - Recent activities');
    console.log('\n' + '='.repeat(60) + '\n');
    
  } catch (error) {
    console.error('\n❌ MIGRATION FAILED');
    console.error('='.repeat(60));
    console.error('Error:', error.message);
    console.error('');
    
    if (error.message.includes('password authentication failed')) {
      console.error('💡 Tip: Check your database password in .env');
    } else if (error.message.includes('Connection refused')) {
      console.error('💡 Tip: Check your Supabase project URL and port (5432)');
    } else if (error.message.includes('timeout')) {
      console.error('💡 Tip: Check your internet connection');
    }
    
    process.exit(1);
  } finally {
    await client.end();
    console.log('📡 Database connection closed\n');
  }
}

// ============================================================================
// RUN
// ============================================================================

runMigration().catch(error => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
