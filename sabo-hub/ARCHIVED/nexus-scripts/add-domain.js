import https from 'https';

const VERCEL_TOKEN = 'oo1EcKsmpnbAN9bD0jBvsDQr';
const PROJECT_ID = 'prj_2qbO3hge84LQb55u6JxUC94BGScc';
const DOMAIN = 'hub.saboarena.com';

console.log('🌐 Adding domain to Vercel project...\n');

// Add domain to project
const data = JSON.stringify({
  name: DOMAIN
});

const options = {
  hostname: 'api.vercel.com',
  port: 443,
  path: `/v10/projects/${PROJECT_ID}/domains`,
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${VERCEL_TOKEN}`,
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, (res) => {
  let responseData = '';

  res.on('data', (chunk) => {
    responseData += chunk;
  });

  res.on('end', () => {
    console.log(`Status Code: ${res.statusCode}\n`);
    
    if (res.statusCode === 200 || res.statusCode === 201) {
      const response = JSON.parse(responseData);
      console.log('✅ Domain added successfully!');
      console.log(`\n🌐 Domain: ${DOMAIN}`);
      console.log('🔒 SSL will be generated automatically (1-5 minutes)');
      console.log(`\n🎉 Your site will be live at: https://${DOMAIN}`);
    } else if (res.statusCode === 409) {
      console.log('ℹ️  Domain already added to project!');
      console.log(`\n🌐 Check status at: https://vercel.com/team-ttm2xg2kvn43kfcxzw6je77p/manager-portal/settings/domains`);
    } else {
      console.error('❌ Failed to add domain');
      console.error('Response:', responseData);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

req.write(data);
req.end();
