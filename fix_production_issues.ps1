#!/usr/bin/env pwsh
# Fix Production Issues - Remove Print Statements
# This script wraps all print() calls with kDebugMode checks

Write-Host "SABOHUB - Fix Production Issues" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0
$FixCount = 0

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
        "SUCCESS" { "[OK]" }
        "ERROR" { "[ERROR]" }
        "WARNING" { "[WARN]" }
        default { "[INFO]" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $color
}

# Get all dart files
Write-Status "Finding all Dart files..." "INFO"
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | Where-Object { 
    $_.FullName -notlike "*\.g\.dart*" -and 
    $_.FullName -notlike "*\.freezed\.dart*" -and
    $_.Name -ne "debug_manager.dart"
}

Write-Status "Found $($dartFiles.Count) Dart files to process" "INFO"
Write-Host ""

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        
        # Check if file already has kDebugMode import
        $hasKDebugModeImport = $content -match "import 'package:flutter/foundation.dart';"
        
        # Find all print statements that are not already wrapped
        $printPattern = '(?<!if \(kDebugMode\) \{ )print\([^)]*\);'
        $printMatches = [regex]::Matches($content, $printPattern)
        
        if ($printMatches.Count -gt 0) {
            Write-Status "Processing $($file.Name) - Found $($printMatches.Count) print statements" "WARNING"
            
            # Add import if not present
            if (-not $hasKDebugModeImport) {
                if ($content -match "import 'package:flutter/material.dart';") {
                    $content = $content -replace "(import 'package:flutter/material.dart';)", "`$1`nimport 'package:flutter/foundation.dart';"
                } elseif ($content -match "import 'package:flutter/") {
                    $content = $content -replace "(import 'package:flutter/[^']*';)", "`$1`nimport 'package:flutter/foundation.dart';"
                } else {
                    $content = "import 'package:flutter/foundation.dart';`n" + $content
                }
            }
            
            # Wrap print statements with kDebugMode
            $content = [regex]::Replace($content, $printPattern, { 
                param($match)
                "if (kDebugMode) { $($match.Value) }"
            })
            
            # Write back to file
            Set-Content $file.FullName $content -NoNewline -ErrorAction Stop
            
            Write-Status "Fixed $($printMatches.Count) print statements in $($file.Name)" "SUCCESS"
            $FixCount += $printMatches.Count
        }
    }
    catch {
        Write-Status "Error processing $($file.Name): $($_.Exception.Message)" "ERROR"
        $ErrorCount++
    }
}

Write-Host ""
Write-Status "=== SUMMARY ===" "INFO"
Write-Status "Fixed print statements: $FixCount" "SUCCESS"
if ($ErrorCount -gt 0) {
    Write-Status "Errors encountered: $ErrorCount" "ERROR"
}

# Run flutter analyze to check
Write-Host ""
Write-Status "Running flutter analyze to verify fixes..." "INFO"
try {
    flutter analyze
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Flutter analyze completed successfully!" "SUCCESS"
    } else {
        Write-Status "Flutter analyze found issues. Check output above." "WARNING"
    }
} catch {
    Write-Status "Could not run flutter analyze" "ERROR"
}

Write-Host ""
Write-Status "Production fix script completed!" "SUCCESS"
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the app to ensure it still works" -ForegroundColor Yellow
Write-Host "2. Commit the changes" -ForegroundColor Yellow  
Write-Host "3. Deploy to production" -ForegroundColor Yellow