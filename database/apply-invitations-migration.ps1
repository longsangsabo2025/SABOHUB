# ============================================================================
# 🔗 EMPLOYEE INVITATIONS MIGRATION SCRIPT (PowerShell)
# ============================================================================

Write-Host "🔄 Applying Employee Invitations Migration..." -ForegroundColor Cyan

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

# Apply Employee Invitations migration
$sqlFile = "database/migrations/002_employee_invitations.sql"
if (Test-Path $sqlFile) {
    Write-Host "📊 Employee Invitations Migration Ready..." -ForegroundColor Cyan
    
    Write-Host "📋 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Open Supabase Dashboard: $supabaseUrl" -ForegroundColor White
    Write-Host "2. Go to SQL Editor" -ForegroundColor White
    Write-Host "3. Copy and run the SQL from: $sqlFile" -ForegroundColor White
    Write-Host ""
    Write-Host "📄 This migration creates:" -ForegroundColor Green
    Write-Host "  - employee_invitations table" -ForegroundColor White
    Write-Host "  - Proper indexes and constraints" -ForegroundColor White
    Write-Host "  - RLS policies for security" -ForegroundColor White
    Write-Host "  - Triggers for auto-updates" -ForegroundColor White
    
    # Open the SQL file in notepad for easy copying
    Write-Host ""
    Write-Host "📝 Opening SQL file for copying..." -ForegroundColor Cyan
    Start-Process "notepad.exe" -ArgumentList $sqlFile
    
    # Open Supabase dashboard
    Start-Process "$supabaseUrl"
    
} else {
    Write-Host "❌ SQL migration file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Employee Invitations Migration Ready!" -ForegroundColor Green
Write-Host "🎯 After applying the migration, the invitation system will be fully functional!" -ForegroundColor Cyan