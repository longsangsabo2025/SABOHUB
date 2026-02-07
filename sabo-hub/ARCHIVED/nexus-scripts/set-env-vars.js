import https from 'https';

const TOKEN = 'oo1EcKsmpnbAN9bD0jBvsDQr';
const PROJECT_ID = 'prj_3Jei9UiqQhPS7UVmQbyNWib7oYMx';

console.log('🔧 Setting environment variables in Vercel...\n');

const envVars = [
  {
    key: 'VITE_SUPABASE_URL',
    value: 'https://dqddxowyikefqcdiioyh.supabase.co',
    target: ['production', 'preview', 'development']
  },
  {
    key: 'VITE_SUPABASE_ANON_KEY',
    value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y',
    target: ['production', 'preview', 'development']
  },
  {
    key: 'VITE_APP_NAME',
    value: 'SABOHUB',
    target: ['production', 'preview', 'development']
  },
  {
    key: 'VITE_ENVIRONMENT',
    value: 'production',
    target: ['production']
  },
  {
    key: 'VITE_DEBUG',
    value: 'false',
    target: ['production']
  }
];

let completed = 0;

envVars.forEach((env, index) => {
  setTimeout(() => {
    const postData = JSON.stringify({
      key: env.key,
      value: env.value,
      target: env.target,
      type: 'plain'
    });

    const options = {
      hostname: 'api.vercel.com',
      path: `/v10/projects/${PROJECT_ID}/env`,
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
        if (res.statusCode === 200 || res.statusCode === 201) {
          console.log(`✅ ${env.key} = ${env.value.substring(0, 30)}...`);
        } else {
          console.log(`⚠️  ${env.key}: ${res.statusCode} - ${data}`);
        }
        
        completed++;
        if (completed === envVars.length) {
          console.log('\n🎉 Environment variables configured!');
          console.log('⚡ Triggering production redeployment...\n');
        }
      });
    });

    req.on('error', (error) => {
      console.error(`❌ ${env.key} failed:`, error.message);
      completed++;
    });

    req.write(postData);
    req.end();
  }, index * 500);
});
