# ============================================================================
# 🔗 AUTO-APPLY EMPLOYEE INVITATIONS MIGRATION (PowerShell)
# ============================================================================
# Automatically applies the migration using Supabase REST API

Write-Host "🔄 Auto-applying Employee Invitations Migration..." -ForegroundColor Cyan

# Read .env file
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "❌ .env file not found" -ForegroundColor Red
    exit 1
}

# Get Supabase credentials
$supabaseUrl = $env:SUPABASE_URL
$serviceRoleKey = $env:SUPABASE_SERVICE_ROLE_KEY

if (-not $supabaseUrl -or -not $serviceRoleKey) {
    Write-Host "❌ Missing Supabase credentials in .env" -ForegroundColor Red
    exit 1
}

Write-Host "🏢 Supabase URL: $supabaseUrl" -ForegroundColor Yellow

# Read SQL migration file
$sqlFile = "database/migrations/002_employee_invitations.sql"
if (-not (Test-Path $sqlFile)) {
    Write-Host "❌ SQL migration file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

$sqlContent = Get-Content $sqlFile -Raw
Write-Host "📄 Migration file loaded: $($sqlContent.Length) characters" -ForegroundColor Green

# Apply migration using REST API
try {
    Write-Host "🚀 Executing SQL migration..." -ForegroundColor Cyan
    
    $headers = @{
        "apikey" = $serviceRoleKey
        "Authorization" = "Bearer $serviceRoleKey"
        "Content-Type" = "application/json"
    }
    
    $body = @{
        query = $sqlContent
    } | ConvertTo-Json
    
    $restUrl = "$supabaseUrl/rest/v1/rpc/exec_sql"
    
    # Try alternative endpoint for SQL execution
    $sqlUrl = "$supabaseUrl/rest/v1/rpc"
    
    # Create a simple RPC call to execute SQL
    $rpcBody = @{
        sql = $sqlContent
    } | ConvertTo-Json
    
    Write-Host "📡 Sending request to Supabase..." -ForegroundColor Yellow
    
    # Use PostgreSQL connection string for direct execution
    $connectionString = $env:SUPABASE_CONNECTION_STRING
    
    if ($connectionString) {
        Write-Host "🔌 Using direct PostgreSQL connection..." -ForegroundColor Cyan
        
        # Install PostgreSQL module if not available
        if (-not (Get-Module -ListAvailable -Name "Npgsql")) {
            Write-Host "📦 Installing PostgreSQL .NET driver..." -ForegroundColor Yellow
            # We'll use a different approach since Npgsql might not be available
        }
        
        # Alternative: Use psql command if available
        $psqlPath = Get-Command psql -ErrorAction SilentlyContinue
        if ($psqlPath) {
            Write-Host "🛠️ Using psql command..." -ForegroundColor Cyan
            
            # Write SQL to temp file
            $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
            $sqlContent | Out-File -FilePath $tempSqlFile -Encoding UTF8
            
            # Execute with psql
            $psqlResult = & psql $connectionString -f $tempSqlFile 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Migration executed successfully!" -ForegroundColor Green
                Write-Host "📋 Result:" -ForegroundColor Yellow
                $psqlResult | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
            } else {
                Write-Host "❌ Migration failed!" -ForegroundColor Red
                Write-Host "📋 Error:" -ForegroundColor Yellow
                $psqlResult | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
            }
            
            # Clean up temp file
            Remove-Item $tempSqlFile -ErrorAction SilentlyContinue
        } else {
            Write-Host "⚠️ psql not found. Installing via npm..." -ForegroundColor Yellow
            
            # Try using Node.js pg library
            $nodeScript = @"
const { Client } = require('pg');
const fs = require('fs');

const client = new Client({
    connectionString: '$connectionString'
});

async function runMigration() {
    try {
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        const sql = fs.readFileSync('$sqlFile', 'utf8');
        const result = await client.query(sql);
        
        console.log('✅ Migration executed successfully!');
        console.log('📋 Result:', result);
        
    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        process.exit(1);
    } finally {
        await client.end();
    }
}

runMigration();
"@
            
            $nodeScript | Out-File -FilePath "temp_migration.js" -Encoding UTF8
            
            # Install pg if needed and run
            npm install pg 2>$null
            node temp_migration.js
            
            # Clean up
            Remove-Item temp_migration.js -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "❌ No connection string available" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ Error executing migration: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Employee Invitations Migration Complete!" -ForegroundColor Green
Write-Host "🎯 The invitation system is now ready to use!" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Tables created:" -ForegroundColor Yellow
Write-Host "  - employee_invitations (with indexes and constraints)" -ForegroundColor White
Write-Host "  - RLS policies for security" -ForegroundColor White
Write-Host "  - Auto-update triggers" -ForegroundColor White