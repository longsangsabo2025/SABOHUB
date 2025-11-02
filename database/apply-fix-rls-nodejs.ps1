# ============================================
# Apply RLS Fix using Node.js + PostgreSQL
# ============================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Applying RLS Infinite Recursion Fix via Transaction Pooler..." -ForegroundColor Cyan
Write-Host ""

# Load environment variables
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    Write-Host "✅ Loaded .env file" -ForegroundColor Green
} else {
    Write-Host "❌ .env file not found!" -ForegroundColor Red
    exit 1
}

$connectionString = $env:SUPABASE_CONNECTION_STRING
if (-not $connectionString) {
    Write-Host "❌ SUPABASE_CONNECTION_STRING not found in .env!" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Using Transaction Pooler connection" -ForegroundColor Gray
Write-Host ""

# Migration file
$migrationFile = "database\migrations\999_fix_rls_infinite_recursion.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Reading migration SQL..." -ForegroundColor Cyan
$migrationSQL = Get-Content $migrationFile -Raw

# Create Node.js script to execute SQL
$nodeScript = @"
const { Client } = require('pg');

const connectionString = process.env.SUPABASE_CONNECTION_STRING;
const sql = \`$migrationSQL\`;

async function applyMigration() {
  const client = new Client({
    connectionString: connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    console.log('🔌 Connecting to database...');
    await client.connect();
    console.log('✅ Connected successfully!');
    console.log('');
    
    console.log('🚀 Executing migration...');
    console.log('');
    
    await client.query(sql);
    
    console.log('');
    console.log('✅ Migration applied successfully!');
    console.log('');
    console.log('📝 NEXT STEPS:');
    console.log('   1. Go to Supabase Dashboard → Authentication → Hooks');
    console.log('   2. Enable "Custom Access Token" hook');
    console.log('   3. Set function: public.custom_access_token_hook');
    console.log('   4. Save changes');
    console.log('');
    console.log('   5. All users MUST re-login to get new JWT tokens!');
    console.log('');
    console.log('🔗 Dashboard: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/hooks');
    
  } catch (error) {
    console.error('');
    console.error('❌ Error applying migration:');
    console.error(error.message);
    console.error('');
    if (error.detail) {
      console.error('Details:', error.detail);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

applyMigration();
"@

# Save Node.js script
$nodeScriptFile = "database\temp-migration-runner.js"
$nodeScript | Out-File -Encoding UTF8 $nodeScriptFile

Write-Host "📝 Created temporary migration runner" -ForegroundColor Gray
Write-Host ""

# Check if Node.js is installed
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Write-Host "❌ Node.js not found!" -ForegroundColor Red
    Write-Host "   Please install Node.js from: https://nodejs.org/" -ForegroundColor Yellow
    Remove-Item $nodeScriptFile -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "✅ Found Node.js: $($nodePath.Source)" -ForegroundColor Green
Write-Host ""

# Check if pg module is installed
$packageJsonPath = "package.json"
if (-not (Test-Path $packageJsonPath)) {
    Write-Host "⚠️  package.json not found at project root" -ForegroundColor Yellow
    Write-Host "   Installing pg module..." -ForegroundColor Cyan
    npm install pg
    Write-Host ""
}

# Confirm before applying
Write-Host "⚠️  WARNING: This will modify RLS policies in your database!" -ForegroundColor Yellow
Write-Host "   - Drop existing policies on users and tasks tables" -ForegroundColor Yellow
Write-Host "   - Create new safe policies without recursion" -ForegroundColor Yellow
Write-Host "   - Add custom JWT token hook" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Do you want to proceed? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "❌ Migration cancelled" -ForegroundColor Red
    Remove-Item $nodeScriptFile -ErrorAction SilentlyContinue
    exit 0
}

Write-Host ""
Write-Host "🚀 Running migration..." -ForegroundColor Cyan
Write-Host ""

# Run the Node.js script
try {
    node $nodeScriptFile
    $exitCode = $LASTEXITCODE
    
    # Cleanup
    Remove-Item $nodeScriptFile -ErrorAction SilentlyContinue
    
    if ($exitCode -eq 0) {
        Write-Host ""
        Write-Host "🎉 Done!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Migration failed with exit code: $exitCode" -ForegroundColor Red
        exit $exitCode
    }
} catch {
    Remove-Item $nodeScriptFile -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "❌ Error running migration: $_" -ForegroundColor Red
    exit 1
}
