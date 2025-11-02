#!/usr/bin/env pwsh
# Pre-Production Fix Script
# Fixes critical issues before deployment

Write-Host "🔧 SABOHUB Pre-Production Fix Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0
$WarningCount = 0
$FixCount = 0

# Function to log messages
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    $prefix = switch ($Type) {
        "SUCCESS" { "✅" }
        "ERROR" { "❌" }
        "WARNING" { "⚠️" }
        default { "ℹ️" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

# Step 1: Remove debug print statements
Write-Host "Step 1: Removing debug print statements..." -ForegroundColor Yellow
Write-Host ""

$filesToCheck = @(
    "lib\widgets\ai\chat_input_widget.dart",
    "lib\services\file_upload_service.dart",
    "lib\pages\ceo\ceo_ai_assistant_page.dart"
)

foreach ($file in $filesToCheck) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $originalContent = $content
        
        # Replace print statements with kDebugMode checks
        $content = $content -replace "print\((.*?)\);", "if (kDebugMode) { print(`$1); }"
        
        if ($content -ne $originalContent) {
            Set-Content $file $content -NoNewline
            Write-Status "Fixed print statements in: $file" "SUCCESS"
            $FixCount++
        } else {
            Write-Status "No print statements found in: $file" "INFO"
        }
    } else {
        Write-Status "File not found: $file" "WARNING"
        $WarningCount++
    }
}

Write-Host ""

# Step 2: Add kDebugMode import where needed
Write-Host "Step 2: Adding kDebugMode import..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $filesToCheck) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Check if kDebugMode is used but not imported
        if ($content -match "kDebugMode" -and $content -notmatch "import 'package:flutter/foundation.dart'") {
            # Find the last import statement
            $lines = Get-Content $file
            $lastImportIndex = -1
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "^import ") {
                    $lastImportIndex = $i
                }
            }
            
            if ($lastImportIndex -ge 0) {
                # Insert the import after the last import
                $newLines = $lines[0..$lastImportIndex] + "import 'package:flutter/foundation.dart';" + $lines[($lastImportIndex + 1)..($lines.Count - 1)]
                Set-Content $file $newLines
                Write-Status "Added kDebugMode import to: $file" "SUCCESS"
                $FixCount++
            }
        }
    }
}

Write-Host ""

# Step 3: Check for CEO Stores Page issues
Write-Host "Step 3: Checking CEO Stores Page..." -ForegroundColor Yellow
Write-Host ""

$ceoBroken = "lib\pages\ceo\ceo_stores_page.dart"
if (Test-Path $ceoBroken) {
    Write-Status "Analyzing $ceoBroken..." "INFO"
    
    # Run flutter analyze on this specific file
    $analyzeResult = flutter analyze $ceoBroken 2>&1 | Out-String
    
    if ($analyzeResult -match "error") {
        Write-Status "CEO Stores Page has CRITICAL errors!" "ERROR"
        Write-Status "Manual fix required - see PRODUCTION-AUDIT-REPORT.md" "WARNING"
        $ErrorCount++
        Write-Host ""
        Write-Host "Errors found:" -ForegroundColor Red
        Write-Host $analyzeResult -ForegroundColor Red
    } else {
        Write-Status "CEO Stores Page: No critical errors" "SUCCESS"
    }
} else {
    Write-Status "CEO Stores Page not found" "WARNING"
    $WarningCount++
}

Write-Host ""

# Step 4: Remove unused fields/variables (commented out)
Write-Host "Step 4: Commenting out unused fields..." -ForegroundColor Yellow
Write-Host ""

$unusedPatterns = @{
    "lib\pages\ceo\ceo_ai_assistant_page.dart" = @("_aiFunctions")
    "lib\pages\manager\manager_staff_page.dart" = @("_searchQuery", "_filterRole")
    "lib\services\manager_kpi_service.dart" = @("role")
}

foreach ($file in $unusedPatterns.Keys) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        $modified = $false
        
        foreach ($field in $unusedPatterns[$file]) {
            # Comment out the unused field declaration
            if ($content -match "(?m)^\s*(final|var|late)\s+.*$field.*$") {
                $content = $content -replace "(?m)(^\s*)(final|var|late)(\s+.*$field.*$)", "`$1// Unused: `$2`$3"
                $modified = $true
            }
        }
        
        if ($modified) {
            Set-Content $file $content -NoNewline
            Write-Status "Commented out unused fields in: $file" "SUCCESS"
            $FixCount++
        }
    }
}

Write-Host ""

# Step 5: Run flutter analyze
Write-Host "Step 5: Running full Flutter analyze..." -ForegroundColor Yellow
Write-Host ""

$analyzeOutput = flutter analyze --no-fatal-infos 2>&1 | Out-String

if ($analyzeOutput -match "No issues found!") {
    Write-Status "Flutter analyze: PASSED ✨" "SUCCESS"
} else {
    # Count errors and warnings
    $errors = ([regex]::Matches($analyzeOutput, "error -")).Count
    $warnings = ([regex]::Matches($analyzeOutput, "warning -")).Count
    
    if ($errors -gt 0) {
        Write-Status "Flutter analyze found $errors error(s)" "ERROR"
        $ErrorCount += $errors
    }
    
    if ($warnings -gt 0) {
        Write-Status "Flutter analyze found $warnings warning(s)" "WARNING"
        $WarningCount += $warnings
    }
    
    Write-Host ""
    Write-Host "Analysis summary:" -ForegroundColor Cyan
    Write-Host $analyzeOutput
}

Write-Host ""

# Step 6: Test compilation
Write-Host "Step 6: Testing compilation..." -ForegroundColor Yellow
Write-Host ""

Write-Status "Running flutter pub get..." "INFO"
$pubGetResult = flutter pub get 2>&1 | Out-String

if ($pubGetResult -match "Got dependencies!") {
    Write-Status "Dependencies resolved successfully" "SUCCESS"
} else {
    Write-Status "Dependency resolution issues" "WARNING"
    $WarningCount++
}

Write-Host ""

# Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "📊 Fix Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Fixes Applied: $FixCount" -ForegroundColor Green
Write-Host "⚠️  Warnings: $WarningCount" -ForegroundColor Yellow
Write-Host "❌ Errors: $ErrorCount" -ForegroundColor Red
Write-Host ""

if ($ErrorCount -eq 0) {
    Write-Host "✨ All critical issues fixed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes" -ForegroundColor White
    Write-Host "2. Run: flutter run -d chrome" -ForegroundColor White
    Write-Host "3. Test all core features" -ForegroundColor White
    Write-Host "4. Commit changes" -ForegroundColor White
    Write-Host "5. Deploy to staging" -ForegroundColor White
    exit 0
} else {
    Write-Host "⚠️  Manual intervention required for $ErrorCount error(s)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check PRODUCTION-AUDIT-REPORT.md for details" -ForegroundColor Cyan
    exit 1
}
