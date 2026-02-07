import https from 'https';

const TOKEN = 'oo1EcKsmpnbAN9bD0jBvsDQr';
const PROJECT_ID = 'prj_3Jei9UiqQhPS7UVmQbyNWib7oYMx';
const DOMAIN = 'hub.saboarena.com';

console.log('🔄 Triggering domain verification...\n');

// Verify domain
const options = {
  hostname: 'api.vercel.com',
  path: `/v9/projects/${PROJECT_ID}/domains/${DOMAIN}/verify`,
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${TOKEN}`,
    'Content-Type': 'application/json'
  }
};

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Status Code:', res.statusCode);
    
    if (res.statusCode === 200) {
      const result = JSON.parse(data);
      console.log('\n✅ VERIFICATION SUCCESSFUL!');
      console.log(`\n🌐 Domain: ${result.name || DOMAIN}`);
      console.log(`✓ Verified: ${result.verified ? 'YES' : 'NO'}`);
      
      if (result.verified) {
        console.log('\n🎉 YOUR SITE IS NOW LIVE!');
        console.log(`🔗 https://${DOMAIN}`);
      } else {
        console.log('\n⏳ Verification in progress...');
        console.log('Wait 30 seconds and try accessing the site.');
      }
    } else if (res.statusCode === 400) {
      console.log('\n⚠️  Verification pending');
      console.log('DNS records might not be propagated yet.');
      console.log('\nPlease wait 1-2 minutes and run: node verify-domain.js');
    } else {
      console.log('\n❌ Verification failed');
      try {
        const error = JSON.parse(data);
        console.log('Error:', error.error?.message || data);
      } catch {
        console.log('Response:', data);
      }
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

req.end();
