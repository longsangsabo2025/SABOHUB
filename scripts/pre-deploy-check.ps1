# SABOHUB - Pre-deployment Check Script (PowerShell)
# This script validates the app is ready for deployment

Write-Host "🔍 SABOHUB Pre-Deployment Check" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

$ERRORS = 0
$WARNINGS = 0

# Check Flutter installation
Write-Host "📱 Checking Flutter installation..." -ForegroundColor Cyan
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "   ❌ Flutter not found" -ForegroundColor Red
    $ERRORS++
} else {
    $flutterVersion = (flutter --version | Select-Object -First 1)
    Write-Host "   ✅ $flutterVersion" -ForegroundColor Green
}

# Check Flutter doctor
Write-Host ""
Write-Host "🏥 Running Flutter doctor..." -ForegroundColor Cyan
$doctorOutput = flutter doctor 2>&1
if ($doctorOutput -match "\[!\]") {
    Write-Host "   ⚠️  Some issues found (check above)" -ForegroundColor Yellow
    $WARNINGS++
} else {
    Write-Host "   ✅ All checks passed" -ForegroundColor Green
}

# Check dependencies
Write-Host ""
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan
if (Test-Path "pubspec.lock") {
    Write-Host "   ✅ Dependencies locked" -ForegroundColor Green
} else {
    Write-Host "   ❌ pubspec.lock not found. Run: flutter pub get" -ForegroundColor Red
    $ERRORS++
}

# Check .env file
Write-Host ""
Write-Host "🔐 Checking environment configuration..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Write-Host "   ✅ .env file exists" -ForegroundColor Green
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "SUPABASE_URL" -and $envContent -match "SUPABASE_ANON_KEY") {
        Write-Host "   ✅ Environment variables configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Missing required environment variables" -ForegroundColor Yellow
        $WARNINGS++
    }
} else {
    Write-Host "   ⚠️  .env file not found" -ForegroundColor Yellow
    $WARNINGS++
}

# Run Flutter analyze
Write-Host ""
Write-Host "🔍 Running Flutter analyze..." -ForegroundColor Cyan
$analyzeResult = flutter analyze --no-fatal-warnings 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ No issues found" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Analysis found issues" -ForegroundColor Yellow
    $WARNINGS++
}

# Run Flutter tests
Write-Host ""
Write-Host "🧪 Running Flutter tests..." -ForegroundColor Cyan
$testResult = flutter test 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ All tests passed" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Some tests failed" -ForegroundColor Yellow
    $WARNINGS++
}

# Check iOS configuration
Write-Host ""
Write-Host "🍎 Checking iOS configuration..." -ForegroundColor Cyan
if (Test-Path "ios") {
    Write-Host "   ✅ iOS project exists" -ForegroundColor Green
    
    $infoPlist = Get-Content "ios\Runner\Info.plist" -Raw -ErrorAction SilentlyContinue
    if ($infoPlist -match "com.sabohub.app") {
        Write-Host "   ✅ Bundle ID configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Bundle ID not properly configured" -ForegroundColor Yellow
        $WARNINGS++
    }
    
    if (Test-Path "ios\Podfile.lock") {
        Write-Host "   ✅ CocoaPods installed" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  CocoaPods not installed. Run: cd ios && pod install" -ForegroundColor Yellow
        $WARNINGS++
    }
} else {
    Write-Host "   ❌ iOS project not found" -ForegroundColor Red
    $ERRORS++
}

# Check Android configuration
Write-Host ""
Write-Host "🤖 Checking Android configuration..." -ForegroundColor Cyan
if (Test-Path "android") {
    Write-Host "   ✅ Android project exists" -ForegroundColor Green
    
    $buildGradle = Get-Content "android\app\build.gradle" -Raw -ErrorAction SilentlyContinue
    if ($buildGradle -match "com.sabohub.app") {
        Write-Host "   ✅ Package name configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Package name not properly configured" -ForegroundColor Yellow
        $WARNINGS++
    }
    
    if (Test-Path "android\key.properties") {
        Write-Host "   ✅ Signing configuration exists" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  key.properties not found (needed for release build)" -ForegroundColor Yellow
        $WARNINGS++
    }
} else {
    Write-Host "   ❌ Android project not found" -ForegroundColor Red
    $ERRORS++
}

# Check codemagic.yaml
Write-Host ""
Write-Host "🔧 Checking CodeMagic configuration..." -ForegroundColor Cyan
if (Test-Path "codemagic.yaml") {
    Write-Host "   ✅ codemagic.yaml exists" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  codemagic.yaml not found" -ForegroundColor Yellow
    $WARNINGS++
}

# Summary
Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "📊 Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

if ($ERRORS -eq 0 -and $WARNINGS -eq 0) {
    Write-Host "✅ All checks passed! Ready for deployment." -ForegroundColor Green
    Write-Host ""
    exit 0
} elseif ($ERRORS -eq 0) {
    Write-Host "⚠️  $WARNINGS warning(s) found." -ForegroundColor Yellow
    Write-Host "   Review warnings before deployment." -ForegroundColor Yellow
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ $ERRORS error(s) and $WARNINGS warning(s) found." -ForegroundColor Red
    Write-Host "   Please fix errors before deployment." -ForegroundColor Red
    Write-Host ""
    exit 1
}
