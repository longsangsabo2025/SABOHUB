const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const VERCEL_TOKEN = 'C5LrAXQFX3ztnbT8bqCAqtgg';
const PROJECT_NAME = 'sabohub-nexus';

// Step 1: Build the project
console.log('🔨 Building project...');
try {
  execSync('npm run build', { stdio: 'inherit' });
  console.log('✅ Build successful!\n');
} catch (error) {
  console.error('❌ Build failed!');
  process.exit(1);
}

// Step 2: Create Vercel deployment
console.log('🚀 Deploying to Vercel...');

const deploymentData = JSON.stringify({
  name: PROJECT_NAME,
  files: [],
  projectSettings: {
    framework: 'vite',
    buildCommand: 'npm run build',
    outputDirectory: 'dist',
    installCommand: 'npm install'
  },
  target: 'production',
  env: {
    VITE_SUPABASE_URL: 'https://dqddxowyikefqcdiioyh.supabase.co',
    VITE_SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y',
    VITE_APP_NAME: 'SABOHUB',
    VITE_ENVIRONMENT: 'production'
  }
});

const options = {
  hostname: 'api.vercel.com',
  port: 443,
  path: '/v13/deployments',
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${VERCEL_TOKEN}`,
    'Content-Type': 'application/json',
    'Content-Length': deploymentData.length
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    if (res.statusCode === 200 || res.statusCode === 201) {
      const response = JSON.parse(data);
      console.log('\n✅ Deployment successful!');
      console.log(`🌐 URL: https://${response.url}`);
      console.log(`📝 Deployment ID: ${response.id}`);
    } else {
      console.error('\n❌ Deployment failed!');
      console.error('Status:', res.statusCode);
      console.error('Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

req.write(deploymentData);
req.end();
