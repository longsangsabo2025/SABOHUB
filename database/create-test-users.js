/**
 * Create Test Users for JWT Token Testing
 * Creates users with different roles to test the Custom Access Token Hook
 */

require('dotenv').config({ path: '../.env' });
const { Client } = require('pg');

const connectionString = 'postgresql://postgres.vuxuqvgkfjemthbdwsnh:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres';

async function createTestUsers() {
  const client = new Client({ connectionString });
  
  try {
    console.log('\n🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected!\n');
    
    console.log('📝 Creating test users...\n');
    
    // First, create a test company and branch
    const companyResult = await client.query(`
      INSERT INTO companies (name, description, address, phone)
      VALUES ('Test Company', 'For testing JWT hook', '123 Test St', '0123456789')
      ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id
    `);
    const companyId = companyResult.rows[0].id;
    console.log(`✅ Test company created: ${companyId}`);
    
    const branchResult = await client.query(`
      INSERT INTO branches (company_id, name, address, phone)
      VALUES ($1, 'Main Branch', '123 Test St', '0123456789')
      ON CONFLICT (company_id, name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id
    `, [companyId]);
    const branchId = branchResult.rows[0].id;
    console.log(`✅ Test branch created: ${branchId}\n`);
    
    // Create test users in auth.users (using Supabase Admin API)
    const testUsers = [
      {
        email: 'ceo@test.com',
        password: 'Test123456!',
        role: 'CEO',
        fullName: 'CEO Test User'
      },
      {
        email: 'manager@test.com',
        password: 'Test123456!',
        role: 'BRANCH_MANAGER',
        fullName: 'Manager Test User'
      },
      {
        email: 'staff@test.com',
        password: 'Test123456!',
        role: 'STAFF',
        fullName: 'Staff Test User'
      }
    ];
    
    console.log('⚠️  NOTE: To create users in auth.users, you need to:');
    console.log('   1. Go to: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/users');
    console.log('   2. Click "Add user" → "Create new user"');
    console.log('   3. Create these test users:\n');
    
    for (const user of testUsers) {
      console.log(`   📧 Email: ${user.email}`);
      console.log(`   🔑 Password: ${user.password}`);
      console.log(`   👤 Full Name: ${user.fullName}`);
      console.log(`   🎭 Role: ${user.role}\n`);
    }
    
    console.log('\n💡 After creating users in Supabase Dashboard, run this SQL to update their roles:\n');
    
    for (const user of testUsers) {
      console.log(`-- ${user.fullName}`);
      console.log(`UPDATE users SET`);
      console.log(`  user_role = '${user.role}',`);
      console.log(`  company_id = '${companyId}',`);
      console.log(`  branch_id = '${branchId}',`);
      console.log(`  full_name = '${user.fullName}'`);
      console.log(`WHERE email = '${user.email}';\n`);
    }
    
    console.log('\n✅ Setup instructions complete!');
    console.log('\n📋 Next steps:');
    console.log('   1. Create users in Supabase Dashboard Auth section');
    console.log('   2. Run the SQL updates above');
    console.log('   3. Test login: node test-login-jwt.js ceo@test.com Test123456!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

createTestUsers().catch(console.error);
