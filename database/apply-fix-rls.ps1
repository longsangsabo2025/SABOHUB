# ============================================
# Apply RLS Fix Migration to Supabase
# ============================================

Write-Host "🔧 Applying RLS Infinite Recursion Fix..." -ForegroundColor Cyan
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

Write-Host "📊 Connection String: $($connectionString.Substring(0, 50))..." -ForegroundColor Gray
Write-Host ""

# Check if psql is installed
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psqlPath) {
    Write-Host "❌ PostgreSQL client (psql) not found!" -ForegroundColor Red
    Write-Host "   Please install PostgreSQL client tools first" -ForegroundColor Yellow
    Write-Host "   Download: https://www.postgresql.org/download/" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Found psql: $($psqlPath.Source)" -ForegroundColor Green
Write-Host ""

# Migration file
$migrationFile = "database\migrations\999_fix_rls_infinite_recursion.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Migration file: $migrationFile" -ForegroundColor Cyan
Write-Host ""

# Confirm before applying
Write-Host "⚠️  WARNING: This will modify RLS policies in your database!" -ForegroundColor Yellow
Write-Host "   - Drop existing policies on users and tasks tables" -ForegroundColor Yellow
Write-Host "   - Create new safe policies without recursion" -ForegroundColor Yellow
Write-Host "   - Add custom JWT token hook" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Do you want to proceed? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "❌ Migration cancelled" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🚀 Applying migration..." -ForegroundColor Cyan
Write-Host ""

# Apply migration
$env:PGPASSWORD = ""  # Password is in connection string
try {
    psql $connectionString -f $migrationFile -v ON_ERROR_STOP=1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Migration applied successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 NEXT STEPS:" -ForegroundColor Cyan
        Write-Host "   1. Go to Supabase Dashboard → Authentication → Hooks" -ForegroundColor Yellow
        Write-Host "   2. Enable 'Custom Access Token' hook" -ForegroundColor Yellow
        Write-Host "   3. Set function: public.custom_access_token_hook" -ForegroundColor Yellow
        Write-Host "   4. Save changes" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   5. All users MUST re-login to get new JWT tokens!" -ForegroundColor Red
        Write-Host "   6. Test with different roles (CEO, MANAGER, STAFF)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🔗 Dashboard: https://supabase.com/dashboard/project/vuxuqvgkfjemthbdwsnh/auth/hooks" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "❌ Migration failed!" -ForegroundColor Red
        Write-Host "   Check error messages above" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error applying migration: $_" -ForegroundColor Red
    exit 1
}
