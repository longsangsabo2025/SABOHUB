# Rename tables from stores to companies
# This script applies the table rename migration

param(
    [string]$ConnectionString = $null
)

# Colors for output
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

Write-Host "🏢 RENAMING TABLES: stores → companies" -ForegroundColor $InfoColor
Write-Host "===========================================" -ForegroundColor $InfoColor

# Check if connection string is provided
if (-not $ConnectionString) {
    Write-Host "❌ Error: Connection string not provided" -ForegroundColor $ErrorColor
    Write-Host "Usage: .\rename-tables.ps1 -ConnectionString 'your-connection-string'" -ForegroundColor $WarningColor
    exit 1
}

try {
    # Install required module if not present
    if (-not (Get-Module -ListAvailable -Name "npgsql")) {
        Write-Host "📦 Installing npgsql module..." -ForegroundColor $InfoColor
        Install-Module -Name npgsql -Force -Scope CurrentUser
    }

    # Read migration SQL
    $migrationFile = Join-Path $PSScriptRoot "migrations" "rename-stores-to-companies.sql"
    
    if (-not (Test-Path $migrationFile)) {
        Write-Host "❌ Migration file not found: $migrationFile" -ForegroundColor $ErrorColor
        exit 1
    }

    $migrationSQL = Get-Content $migrationFile -Raw
    Write-Host "📄 Migration SQL loaded from: $migrationFile" -ForegroundColor $InfoColor

    # Connect to database
    Write-Host "🔌 Connecting to database..." -ForegroundColor $InfoColor
    
    # Use psql command if available (simpler approach)
    if (Get-Command psql -ErrorAction SilentlyContinue) {
        Write-Host "🚀 Executing migration using psql..." -ForegroundColor $InfoColor
        
        # Save SQL to temp file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
        $migrationSQL | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Execute migration
        $result = psql $ConnectionString -f $tempFile
        
        # Clean up temp file
        Remove-Item $tempFile -Force
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Migration completed successfully!" -ForegroundColor $SuccessColor
            Write-Host "📊 Tables renamed: stores → companies" -ForegroundColor $SuccessColor
        } else {
            Write-Host "❌ Migration failed with exit code: $LASTEXITCODE" -ForegroundColor $ErrorColor
            Write-Host "Output: $result" -ForegroundColor $ErrorColor
            exit 1
        }
    } else {
        Write-Host "❌ psql command not found. Please install PostgreSQL client tools." -ForegroundColor $ErrorColor
        Write-Host "Or run the migration manually in your database client." -ForegroundColor $WarningColor
        Write-Host "Migration file: $migrationFile" -ForegroundColor $InfoColor
        exit 1
    }

} catch {
    Write-Host "❌ Error during migration: $($_.Exception.Message)" -ForegroundColor $ErrorColor
    exit 1
}

Write-Host "" -ForegroundColor $InfoColor
Write-Host "🎉 Database table rename completed!" -ForegroundColor $SuccessColor
Write-Host "Next steps:" -ForegroundColor $InfoColor
Write-Host "1. Update your application code to use 'companies' table name" -ForegroundColor $InfoColor
Write-Host "2. Test your application thoroughly" -ForegroundColor $InfoColor
Write-Host "3. Update any external integrations" -ForegroundColor $InfoColor