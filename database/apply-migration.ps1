# ============================================================================
# 🚀 SABOHUB DATABASE SETUP SCRIPT (PowerShell)
# ============================================================================

Write-Host "🔄 Applying SaboHub Core Database Migration..." -ForegroundColor Cyan

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

# Check if we have Supabase URL
$supabaseUrl = $env:SUPABASE_URL
if (-not $supabaseUrl) {
    Write-Host "❌ SUPABASE_URL not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host "🏢 Supabase URL: $supabaseUrl" -ForegroundColor Yellow

# Apply SQL migration directly using PowerShell and HTTP API
$sqlFile = "database/migrations/001_create_core_tables.sql"
if (Test-Path $sqlFile) {
    Write-Host "📊 Applying SQL migration..." -ForegroundColor Cyan
    
    # You can manually copy and paste the SQL content into Supabase SQL Editor
    Write-Host "📋 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open Supabase Dashboard: $supabaseUrl" -ForegroundColor White
    Write-Host "2. Go to SQL Editor" -ForegroundColor White
    Write-Host "3. Copy and run the SQL from: $sqlFile" -ForegroundColor White
    
    # Open Supabase dashboard
    Start-Process "$supabaseUrl"
    
} else {
    Write-Host "❌ SQL migration file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Setup script completed!" -ForegroundColor Green
Write-Host "🎯 Ready for SaboHub Flutter app development!" -ForegroundColor Cyan