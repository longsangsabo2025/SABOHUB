#!/usr/bin/env node

/**
 * Apply NEW SCHEMA V2 and RLS Policies
 * This is a COMPLETE DATABASE REBUILD
 * 
 * ⚠️  WARNING: This will DROP ALL EXISTING TABLES!
 * 
 * Usage:
 *   npm install pg
 *   node database/apply-new-schema.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

// Connection string (Session Pooler port 5432 for full PostgreSQL support)
const connectionString = 'postgresql://postgres.vuxuqvgkfjemthbdwsnh:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

// SQL files to execute IN ORDER
const migrationFiles = [
  'schemas/NEW-SCHEMA-V2.sql',
  'schemas/NEW-RLS-POLICIES-V2.sql'
];

async function executeSqlFile(client, filePath) {
  const fullPath = path.join(__dirname, filePath);
  console.log(`\n📄 Executing: ${filePath}`);
  
  if (!fs.existsSync(fullPath)) {
    throw new Error(`File not found: ${fullPath}`);
  }
  
  const sql = fs.readFileSync(fullPath, 'utf8');
  
  try {
    await client.query(sql);
    console.log(`✅ Success: ${filePath}`);
  } catch (error) {
    console.error(`❌ Error in ${filePath}:`);
    console.error(error.message);
    throw error;
  }
}

async function main() {
  console.log('🚀 SABOHUB Database Migration v2.0');
  console.log('=====================================\n');
  
  // Confirm with user
  console.log('⚠️  WARNING: This will COMPLETELY REBUILD the database!');
  console.log('⚠️  ALL EXISTING DATA WILL BE LOST!');
  console.log('\nMigration steps:');
  console.log('  1. Drop all existing tables');
  console.log('  2. Create new schema v2.0');
  console.log('  3. Apply RLS policies v2.0');
  console.log('\nPress Ctrl+C to cancel, or wait 5 seconds to continue...\n');
  
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  const client = new Client({ connectionString });
  
  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!\n');
    
    // Execute migration files
    for (const file of migrationFiles) {
      await executeSqlFile(client, file);
    }
    
    console.log('\n\n🎉 Migration completed successfully!\n');
    console.log('📝 NEXT STEPS:');
    console.log('   1. Go to Supabase Dashboard → Authentication → Hooks');
    console.log('   2. Enable "Custom access token" hook');
    console.log('   3. Select function: public.custom_access_token_hook');
    console.log('   4. All users must re-login to get JWT tokens');
    console.log('   5. Update your Flutter app models to match new schema');
    console.log('\n🔒 Security Features Enabled:');
    console.log('   ✅ JWT-based authorization (no recursion)');
    console.log('   ✅ Role-based access control');
    console.log('   ✅ Branch-level data isolation');
    console.log('   ✅ CEO has full access across companies');
    console.log('   ✅ Soft delete support');
    console.log('\n');
    
  } catch (error) {
    console.error('\n❌ Migration failed!');
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
    console.log('👋 Connection closed.');
  }
}

// Run
main().catch(console.error);
