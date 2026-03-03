# SABOHUB Flutter Web App - Auto Deploy to Vercel
# Usage: .\deploy.ps1 [-SkipBuild]

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "`nSABOHUB APP - AUTO DEPLOY SCRIPT`n" -ForegroundColor Cyan

# Configuration
$TOKEN = "oo1EcKsmpnbAN9bD0jBvsDQr"
$PROJECT_DIR = "D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB"
$BUILD_DIR = "$PROJECT_DIR\build\web"

# Step 1: Navigate to project
Write-Host "Step 1: Checking project directory..." -ForegroundColor Yellow
if (!(Test-Path "$PROJECT_DIR\pubspec.yaml")) {
    Write-Host "ERROR: Flutter project not found at $PROJECT_DIR" -ForegroundColor Red
    exit 1
}
Set-Location $PROJECT_DIR
Write-Host "OK: $PROJECT_DIR" -ForegroundColor Green

# Step 2: Build Flutter web
if (!$SkipBuild) {
    Write-Host "`nStep 2: Building Flutter web (release)..." -ForegroundColor Yellow
    flutter build web --no-tree-shake-icons --release
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Flutter build failed!" -ForegroundColor Red
        exit 1
    }
    
    $buildSize = (Get-ChildItem -Path $BUILD_DIR -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "OK: Build complete ($([math]::Round($buildSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "`nStep 2: Skipping build (using existing build/web/)" -ForegroundColor Yellow
}

# Step 3: Verify build output
Write-Host "`nStep 3: Verifying build..." -ForegroundColor Yellow
if (!(Test-Path "$BUILD_DIR\index.html")) {
    Write-Host "ERROR: build/web/index.html not found!" -ForegroundColor Red
    exit 1
}
if (!(Test-Path "$BUILD_DIR\main.dart.js")) {
    Write-Host "ERROR: build/web/main.dart.js not found!" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Build output verified" -ForegroundColor Green

# Step 4: Deploy to Vercel
Write-Host "`nStep 4: Deploying to Vercel (sabohub-app)..." -ForegroundColor Yellow
Set-Location $BUILD_DIR

# Ensure linked to correct project
if (!(Test-Path ".vercel\project.json")) {
    Write-Host "Linking to Vercel project..." -ForegroundColor Yellow
    npx vercel link --project sabohub-app --token $TOKEN --yes
}

$deployOutput = npx vercel --prod --token $TOKEN --yes 2>&1 | Out-String

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Deployment failed!" -ForegroundColor Red
    Write-Host $deployOutput
    exit 1
}

$deploymentUrl = $deployOutput | Select-String -Pattern "https://sabohub-[a-z0-9]+-dsmhs-projects\.vercel\.app" | ForEach-Object { $_.Matches.Value } | Select-Object -First 1
Write-Host "OK: Deployment successful!" -ForegroundColor Green

# Step 5: Verify live site
Write-Host "`nStep 5: Verifying live site..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
try {
    $response = Invoke-WebRequest -Uri "https://sabohub-app.vercel.app" -Method Head -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "OK: Site is live and responding!" -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Site verification failed (may need cache clear)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Production: https://sabohub-app.vercel.app" -ForegroundColor Blue
if ($deploymentUrl) {
    Write-Host "  Vercel URL: $deploymentUrl" -ForegroundColor Gray
}
Write-Host "  Dashboard:  https://vercel.com/dsmhs-projects/sabohub-app" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next Steps:" -ForegroundColor Yellow
Write-Host "    1. Open https://sabohub-app.vercel.app" -ForegroundColor White
Write-Host "    2. Test login with employee credentials" -ForegroundColor White
Write-Host "    3. Add custom domain in Vercel dashboard if needed" -ForegroundColor White
Write-Host ""
