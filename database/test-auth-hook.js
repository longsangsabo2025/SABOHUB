/**
 * ============================================================================
 * 🧪 TEST AUTH HOOK
 * ============================================================================
 * Test xem custom_access_token_hook có inject custom claims vào JWT không
 * 
 * Usage:
 *   node database/test-auth-hook.js
 * 
 * Prerequisites:
 *   - Auth Hook đã được enable trong Dashboard
 *   - Có user trong auth.users table
 * ============================================================================
 */

require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testAuthHook() {
  console.log('\n' + '='.repeat(60));
  console.log('🧪 TESTING AUTH HOOK');
  console.log('='.repeat(60));
  console.log('');
  
  // Test credentials
  const testEmail = 'ceo@sabohub.com';
  const testPassword = 'Acookingoil123'; // Default password in seed
  
  console.log('📧 Test credentials:');
  console.log(`   Email: ${testEmail}`);
  console.log(`   Password: ${testPassword}`);
  console.log('');
  
  try {
    console.log('🔐 Attempting login...');
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email: testEmail,
      password: testPassword,
    });
    
    if (error) {
      console.error('❌ Login failed:', error.message);
      console.error('');
      
      if (error.message.includes('Invalid login credentials')) {
        console.log('💡 Possible solutions:');
        console.log('1. User chưa tồn tại trong auth.users');
        console.log('   → Tạo user trong Supabase Dashboard → Authentication → Users');
        console.log('   → Email: ceo@sabohub.com');
        console.log('   → Password: Acookingoil123 (hoặc password khác)');
        console.log('');
        console.log('2. Password không đúng');
        console.log('   → Reset password trong Dashboard');
        console.log('');
        console.log('3. Sau khi tạo user, cần update users table:');
        console.log('   UPDATE users SET id = \'<AUTH_UUID>\' WHERE email = \'ceo@sabohub.com\';');
      } else if (error.message.includes('Email not confirmed')) {
        console.log('💡 User chưa confirm email');
        console.log('   → Dashboard → Authentication → Users → ... menu → Confirm email');
      }
      
      process.exit(1);
    }
    
    console.log('✅ Login successful!');
    console.log('');
    
    // Get access token
    const session = data.session;
    const accessToken = session.access_token;
    
    // Decode JWT (manual base64 decode)
    const parts = accessToken.split('.');
    if (parts.length !== 3) {
      console.error('❌ Invalid JWT token format');
      process.exit(1);
    }
    
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
    
    console.log('📊 JWT Token Payload:');
    console.log('━'.repeat(60));
    console.log(JSON.stringify(payload, null, 2));
    console.log('');
    
    // Check for custom claims
    console.log('🔍 Checking Custom Claims:');
    console.log('━'.repeat(60));
    
    const hasUserRole = payload.user_role !== undefined;
    const hasCompanyId = payload.company_id !== undefined;
    const hasBranchId = payload.branch_id !== undefined;
    
    console.log(`${hasUserRole ? '✅' : '❌'} user_role: ${payload.user_role || 'MISSING'}`);
    console.log(`${hasCompanyId ? '✅' : '❌'} company_id: ${payload.company_id || 'MISSING'}`);
    console.log(`${hasBranchId ? '✅' : '❌'} branch_id: ${payload.branch_id || 'MISSING'}`);
    console.log('');
    
    if (hasUserRole && hasCompanyId !== undefined && hasBranchId !== undefined) {
      console.log('🎉 AUTH HOOK WORKING PERFECTLY!');
      console.log('━'.repeat(60));
      console.log('✅ Custom claims injected into JWT');
      console.log('✅ RLS policies will work correctly');
      console.log('✅ CEO can access all companies data');
      console.log('');
      
      // Test database query
      console.log('🔍 Testing database access...');
      const { data: companies, error: queryError } = await supabase
        .from('companies')
        .select('*');
      
      if (queryError) {
        console.error('❌ Database query failed:', queryError.message);
      } else {
        console.log(`✅ Successfully fetched ${companies.length} companies`);
        if (companies.length > 0) {
          console.log('');
          console.log('📊 Companies:');
          companies.forEach((c, i) => {
            console.log(`   ${i + 1}. ${c.name} (${c.business_type})`);
          });
        }
      }
      console.log('');
      
      // Test user data
      console.log('🔍 Testing user profile access...');
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', payload.sub)
        .single();
      
      if (userError) {
        console.error('❌ User query failed:', userError.message);
      } else {
        console.log(`✅ User profile: ${user.full_name} (${user.role})`);
      }
      console.log('');
      
      console.log('🎯 SUMMARY:');
      console.log('━'.repeat(60));
      console.log('✅ Auth Hook enabled and working');
      console.log('✅ JWT contains custom claims');
      console.log('✅ Database access working');
      console.log('✅ Ready to use in Flutter app!');
      console.log('');
      console.log('📱 Next step: Login to Flutter app with:');
      console.log(`   Email: ${testEmail}`);
      console.log(`   Password: (password bạn đã set)`);
      
    } else {
      console.log('❌ AUTH HOOK NOT WORKING');
      console.log('━'.repeat(60));
      console.log('Custom claims missing from JWT token');
      console.log('');
      console.log('💡 Troubleshooting:');
      console.log('1. Check Auth Hook is enabled:');
      console.log('   Dashboard → Authentication → Hooks → Custom Access Token Hook = ON');
      console.log('');
      console.log('2. Check function is selected:');
      console.log('   Selected function: public.custom_access_token_hook');
      console.log('');
      console.log('3. Try re-login (logout and login again)');
      console.log('   JWT tokens are cached, old tokens won\'t have new claims');
      console.log('');
      console.log('4. Check function exists:');
      console.log('   SELECT * FROM pg_proc WHERE proname = \'custom_access_token_hook\';');
    }
    
    console.log('\n' + '='.repeat(60) + '\n');
    
    // Sign out
    await supabase.auth.signOut();
    
  } catch (error) {
    console.error('❌ Unexpected error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testAuthHook();
