import https from 'https';

const TOKEN = 'oo1EcKsmpnbAN9bD0jBvsDQr';
const PROJECT_ID = 'prj_2qbO3hge84LQb55u6JxUC94BGScc';

console.log('🔍 Checking Vercel deployment status...\n');

// Check project domains
const domainsOptions = {
  hostname: 'api.vercel.com',
  path: `/v10/projects/${PROJECT_ID}/domains`,
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${TOKEN}`,
    'Content-Type': 'application/json'
  }
};

const domainsReq = https.request(domainsOptions, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('📋 DOMAINS STATUS:');
    console.log('Status Code:', res.statusCode);
    
    if (res.statusCode === 200) {
      const result = JSON.parse(data);
      console.log('\n✅ Domains configured:', result.domains?.length || 0);
      
      if (result.domains) {
        result.domains.forEach(domain => {
          console.log(`\n🌐 ${domain.name}`);
          console.log(`  - Verified: ${domain.verified ? '✅' : '❌'}`);
          console.log(`  - Created: ${new Date(domain.createdAt).toLocaleString()}`);
          
          if (domain.verification && domain.verification.length > 0) {
            console.log(`\n  📝 VERIFICATION REQUIRED:`);
            domain.verification.forEach((v, i) => {
              console.log(`\n  Record ${i + 1}:`);
              console.log(`    Type: ${v.type}`);
              console.log(`    Domain: ${v.domain}`);
              console.log(`    Value: ${v.value}`);
              console.log(`    Reason: ${v.reason || 'Domain verification'}`);
            });
            
            if (domain.name === 'hub.saboarena.com') {
              console.log('\n  🔥 ADD THIS TO CLOUDFLARE DNS:');
              console.log('  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              domain.verification.forEach((v) => {
                console.log(`  Type: ${v.type}`);
                console.log(`  Name: _vercel`);
                console.log(`  Value: ${v.value}`);
                console.log(`  TTL: Auto`);
                console.log('  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              });
            }
          }
        });
      }
    } else {
      console.log('❌ Error:', data);
    }
    
    // Check latest deployment
    checkLatestDeployment();
  });
});

domainsReq.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

domainsReq.end();

function checkLatestDeployment() {
  console.log('\n\n🚀 Checking latest deployment...\n');
  
  const deployOptions = {
    hostname: 'api.vercel.com',
    path: `/v6/deployments?projectId=${PROJECT_ID}&limit=1`,
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/json'
    }
  };

  const deployReq = https.request(deployOptions, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Status Code:', res.statusCode);
      
      if (res.statusCode === 200) {
        const result = JSON.parse(data);
        
        if (result.deployments && result.deployments.length > 0) {
          const latest = result.deployments[0];
          console.log('\n📦 Latest Deployment:');
          console.log(`  - URL: ${latest.url}`);
          console.log(`  - State: ${latest.state}`);
          console.log(`  - Ready State: ${latest.readyState}`);
          console.log(`  - Created: ${new Date(latest.createdAt).toLocaleString()}`);
          
          if (latest.aliasAssigned !== undefined) {
            console.log(`  - Alias Assigned: ${latest.aliasAssigned ? '✅' : '❌'}`);
          }
          
          console.log('\n🔗 Access URLs:');
          console.log(`  - Vercel URL: https://${latest.url}`);
          console.log(`  - Custom Domain: https://hub.saboarena.com`);
        }
      } else {
        console.log('❌ Error:', data);
      }
    });
  });

  deployReq.on('error', (error) => {
    console.error('❌ Request failed:', error.message);
  });

  deployReq.end();
}
