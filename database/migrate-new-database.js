/**
 * 🚀 SABOHUB Database Migration - NEW DATABASE
 * 
 * This script will set up a BRAND NEW Supabase database with:
 * - All tables (60 tables total)
 * - RLS policies (21 tables protected)
 * - Custom access token hook function
 * - Test data (company, branch, CEO user)
 * 
 * Prerequisites:
 * 1. Update .env file with NEW database credentials
 * 2. Make sure SUPABASE_CONNECTION_STRING uses port 5432 (Session Pooler)
 */

require('dotenv').config({ path: '../.env' });
const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Validate environment variables
function validateEnv() {
  const required = ['SUPABASE_CONNECTION_STRING'];
  const missing = required.filter(key => !process.env[key] || process.env[key].includes('YOUR_'));
  
  if (missing.length > 0) {
    console.error('\n❌ Missing or invalid environment variables:');
    missing.forEach(key => console.error(`   - ${key}`));
    console.error('\n💡 Please update .env file with your NEW Supabase credentials');
    console.error('   See: SETUP-NEW-DATABASE.md for instructions\n');
    process.exit(1);
  }
  
  // Validate port 5432
  if (process.env.SUPABASE_CONNECTION_STRING.includes(':6543/')) {
    console.error('\n❌ ERROR: Connection string uses port 6543 (Transaction Pooler)');
    console.error('   You MUST use port 5432 (Session Pooler) for migrations!');
    console.error('   Change :6543/ to :5432/ in your .env file\n');
    process.exit(1);
  }
}

// SQL statement parser
function parseSQLStatements(sql) {
  const statements = [];
  let current = '';
  let inDollarQuote = false;
  let dollarTag = '';
  
  for (let i = 0; i < sql.length; i++) {
    const char = sql[i];
    const next = sql[i + 1];
    
    // Handle $$ or $tag$ for function bodies
    if (char === '$') {
      const tagMatch = sql.slice(i).match(/^\$([a-zA-Z_]*)\$/);
      if (tagMatch) {
        const tag = tagMatch[0];
        if (!inDollarQuote) {
          inDollarQuote = true;
          dollarTag = tag;
        } else if (tag === dollarTag) {
          inDollarQuote = false;
          dollarTag = '';
        }
        current += tag;
        i += tag.length - 1;
        continue;
      }
    }
    
    current += char;
    
    // Split on semicolon only if not in dollar quote
    if (char === ';' && !inDollarQuote) {
      const stmt = current.trim();
      if (stmt && !stmt.startsWith('--')) {
        statements.push(stmt);
      }
      current = '';
    }
  }
  
  // Add last statement if exists
  if (current.trim() && !current.trim().startsWith('--')) {
    statements.push(current.trim());
  }
  
  return statements;
}

// Execute SQL file
async function executeSQLFile(client, filePath, fileName) {
  console.log(`\n📄 Executing: ${fileName}`);
  
  const sql = fs.readFileSync(filePath, 'utf8');
  const statements = parseSQLStatements(sql);
  
  console.log(`   Found ${statements.length} SQL statements`);
  
  let successCount = 0;
  let errorCount = 0;
  
  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    process.stdout.write(`\r   Progress: ${i + 1}/${statements.length} `);
    
    try {
      await client.query(stmt);
      successCount++;
    } catch (error) {
      errorCount++;
      // Show error details for important failures
      if (!error.message.includes('already exists') && 
          !error.message.includes('does not exist')) {
        console.log(`\n   ⚠️  Error in statement ${i + 1}:`);
        console.log(`      ${stmt.substring(0, 50)}...`);
        console.log(`      ${error.message}`);
      }
    }
  }
  
  console.log(`\n   ✅ Success: ${successCount}/${statements.length} statements`);
  if (errorCount > 0) {
    console.log(`   ⚠️  Warnings: ${errorCount} statements (may be ignorable)`);
  }
}

// Main migration function
async function migrate() {
  console.log('\n🚀 SABOHUB Database Migration - NEW DATABASE\n');
  console.log('═══════════════════════════════════════════════════════\n');
  
  // Validate environment
  validateEnv();
  
  const client = new Client({
    connectionString: process.env.SUPABASE_CONNECTION_STRING
  });
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!\n');
    
    // Migration files in order
    const migrationFiles = [
      'schemas/NEW-SCHEMA-V2.sql',        // Create all tables
      'schemas/NEW-RLS-POLICIES-V2.sql'   // Apply RLS policies + hook function
    ];
    
    // Execute each migration file
    for (const file of migrationFiles) {
      const filePath = path.join(__dirname, file);
      if (!fs.existsSync(filePath)) {
        console.error(`\n❌ File not found: ${file}`);
        process.exit(1);
      }
      await executeSQLFile(client, filePath, file);
    }
    
    console.log('\n═══════════════════════════════════════════════════════');
    console.log('\n🎉 Migration completed successfully!');
    console.log('\n📋 Next steps:');
    console.log('   1. Enable Auth Hook in Supabase Dashboard');
    console.log('   2. Run: node setup-test-data.js');
    console.log('   3. Run: node test-jwt-token.js\n');
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    await client.end();
  }
}

// Run migration
migrate().catch(console.error);
