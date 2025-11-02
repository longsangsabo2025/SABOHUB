/**
 * Check Auth Hook Configuration via Supabase Management API
 * This will verify if the hook is actually enabled and configured correctly
 */

require('dotenv').config({ path: '../.env' });

const supabaseProjectRef = 'dqddxowyikefqcdiioyh';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

async function checkHookConfig() {
  console.log('\n🔍 Checking Auth Hook Configuration...\n');
  
  if (!supabaseServiceKey) {
    console.error('❌ SUPABASE_SERVICE_ROLE_KEY not found!');
    process.exit(1);
  }
  
  try {
    // Try to fetch hook config via Management API
    const response = await fetch(
      `https://api.supabase.com/v1/projects/${supabaseProjectRef}/config/auth`,
      {
        headers: {
          'Authorization': `Bearer ${supabaseServiceKey}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    if (!response.ok) {
      console.log('⚠️  Cannot access Management API (this is normal)');
      console.log(`   Status: ${response.status}\n`);
    } else {
      const config = await response.json();
      console.log('✅ Auth Config:');
      console.log(JSON.stringify(config, null, 2));
    }
  } catch (error) {
    console.log('⚠️  API call failed:', error.message);
  }
  
  console.log('\n📋 MANUAL VERIFICATION CHECKLIST:\n');
  console.log('Please verify these settings in Supabase Dashboard:');
  console.log('Link: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/hooks\n');
  
  console.log('✓ Check 1: Is "Customize Access Token (JWT) Claims" hook ENABLED?');
  console.log('  - Toggle should be ON (green)');
  console.log('  - Status should show "Enabled"\n');
  
  console.log('✓ Check 2: Is the correct function selected?');
  console.log('  - Schema: public');
  console.log('  - Function: custom_access_token_hook');
  console.log('  - Should appear in dropdown\n');
  
  console.log('✓ Check 3: Did you click "Save" after enabling?\n');
  
  console.log('💡 COMMON ISSUES:\n');
  console.log('1. Hook enabled but function has runtime error');
  console.log('   → Function works when called directly');
  console.log('   → But fails when Supabase Auth calls it');
  console.log('   → Usually a permissions or schema issue\n');
  
  console.log('2. Function signature mismatch');
  console.log('   → Hook expects: function(event jsonb) RETURNS jsonb');
  console.log('   → Check function definition\n');
  
  console.log('3. Missing permissions');
  console.log('   → Function needs EXECUTE permission for supabase_auth_admin\n');
  
  console.log('🔧 NEXT STEPS:\n');
  console.log('1. Take a screenshot of the Auth Hooks page');
  console.log('2. I will help debug the exact issue');
  console.log('3. Or try disabling and re-enabling the hook\n');
}

checkHookConfig().catch(console.error);
