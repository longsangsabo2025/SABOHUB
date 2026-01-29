# =============================================================================
# SABOHUB - Android Release Build Script
# =============================================================================
# Tham khảo từ SABO Arena deployment workflow
# Sử dụng: .\scripts\build_android_release.ps1
# =============================================================================

param(
    [switch]$Apk,           # Build APK thay vì AAB
    [switch]$NoClean,       # Không clean trước khi build
    [switch]$SkipVersionBump # Không tăng version
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "🚀 SABOHUB Android Release Build" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Change to project directory
Set-Location $ProjectRoot
Write-Host "📁 Working directory: $ProjectRoot" -ForegroundColor Gray

# Step 1: Check prerequisites
Write-Host "`n📋 Step 1: Checking prerequisites..." -ForegroundColor Yellow

# Check Flutter
try {
    $flutterVersion = flutter --version | Select-String "Flutter"
    Write-Host "✅ Flutter: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter not found! Please install Flutter." -ForegroundColor Red
    exit 1
}

# Check keystore
$keystorePath = "android\app\sabohub-release-key.keystore"
if (Test-Path $keystorePath) {
    Write-Host "✅ Release keystore found" -ForegroundColor Green
} else {
    Write-Host "❌ Keystore not found at: $keystorePath" -ForegroundColor Red
    Write-Host "   Run: keytool -genkey -v -keystore android\app\sabohub-release-key.keystore -alias sabohub -keyalg RSA -keysize 2048 -validity 10000" -ForegroundColor Yellow
    exit 1
}

# Check key.properties
$keyPropsPath = "android\key.properties"
if (Test-Path $keyPropsPath) {
    Write-Host "✅ key.properties found" -ForegroundColor Green
} else {
    Write-Host "❌ key.properties not found!" -ForegroundColor Red
    Write-Host "   Creating from example..." -ForegroundColor Yellow
    Copy-Item "android\key.properties.example" $keyPropsPath
    Write-Host "   ⚠️  Please update $keyPropsPath with correct credentials" -ForegroundColor Yellow
}

# Step 2: Auto-increment version (học từ SABO Arena)
if (-not $SkipVersionBump) {
    Write-Host "`n📋 Step 2: Auto-incrementing version..." -ForegroundColor Yellow
    
    $pubspecPath = "pubspec.yaml"
    $pubspec = Get-Content $pubspecPath -Raw
    
    if ($pubspec -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)") {
        $versionName = $Matches[1]
        $buildNumber = [int]$Matches[2]
        $newBuildNumber = $buildNumber + 1
        $newVersion = "$versionName+$newBuildNumber"
        
        $pubspec = $pubspec -replace "version:\s*\d+\.\d+\.\d+\+\d+", "version: $newVersion"
        Set-Content $pubspecPath $pubspec -NoNewline
        
        Write-Host "✅ Version updated: $versionName+$buildNumber → $newVersion" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Could not parse version, skipping..." -ForegroundColor Yellow
    }
}

# Step 3: Clean project (if not skipped)
if (-not $NoClean) {
    Write-Host "`n📋 Step 3: Cleaning project..." -ForegroundColor Yellow
    flutter clean
    Write-Host "✅ Project cleaned" -ForegroundColor Green
}

# Step 4: Get dependencies
Write-Host "`n📋 Step 4: Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencies fetched" -ForegroundColor Green

# Step 5: Build release
Write-Host "`n📋 Step 5: Building release..." -ForegroundColor Yellow

$buildStart = Get-Date

if ($Apk) {
    Write-Host "🔧 Building APK (for direct installation)..." -ForegroundColor Cyan
    flutter build apk --release --split-per-abi
    
    $outputPath = "build\app\outputs\flutter-apk"
    Write-Host "`n✅ APK Build Complete!" -ForegroundColor Green
    Write-Host "📦 APK files:" -ForegroundColor Cyan
    Get-ChildItem "$outputPath\*-release.apk" | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "   - $($_.Name) ($sizeMB MB)" -ForegroundColor White
    }
} else {
    Write-Host "🔧 Building App Bundle (for Google Play)..." -ForegroundColor Cyan
    flutter build appbundle --release
    
    $outputPath = "build\app\outputs\bundle\release"
    $aabFile = Get-ChildItem "$outputPath\*.aab" | Select-Object -First 1
    
    if ($aabFile) {
        $sizeMB = [math]::Round($aabFile.Length / 1MB, 2)
        Write-Host "`n✅ App Bundle Build Complete!" -ForegroundColor Green
        Write-Host "📦 AAB file: $($aabFile.FullName)" -ForegroundColor Cyan
        Write-Host "   Size: $sizeMB MB" -ForegroundColor White
    }
}

$buildTime = (Get-Date) - $buildStart
Write-Host "`n⏱️  Build time: $([math]::Round($buildTime.TotalMinutes, 1)) minutes" -ForegroundColor Gray

# Step 6: Next steps
Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
Write-Host "📱 NEXT STEPS FOR GOOGLE PLAY INTERNAL TESTING:" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan

if ($Apk) {
    Write-Host @"

🔹 OPTION 1: Direct APK Installation (Fastest)
   1. Copy APK to phone via USB/cloud
   2. Enable "Install from unknown sources"
   3. Install the APK

🔹 OPTION 2: Firebase App Distribution
   1. Go to: https://console.firebase.google.com
   2. Select/Create project → App Distribution
   3. Upload APK → Add testers → Send invites

"@ -ForegroundColor White
} else {
    Write-Host @"

🔹 Upload to Google Play Console:
   1. Go to: https://play.google.com/console
   2. Select SABOHUB app (or create new)
   3. Go to: Testing → Internal testing
   4. Create new release → Upload AAB
   5. Add internal testers (email list)
   6. Review and rollout

🔹 For faster iteration, use APK:
   .\scripts\build_android_release.ps1 -Apk

"@ -ForegroundColor White
}

Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
