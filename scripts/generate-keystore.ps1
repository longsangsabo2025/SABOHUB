# SABOHUB - Generate Android Keystore Script (PowerShell)
# This script generates a keystore file for signing Android release builds

Write-Host "🔐 Generating Android Keystore for SABOHUB" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$KEYSTORE_PATH = "$env:USERPROFILE\upload-keystore.jks"
$KEY_ALIAS = "upload"
$VALIDITY_DAYS = 10000

# Check if keytool is available
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Host "❌ Error: keytool not found!" -ForegroundColor Red
    Write-Host "Please install Java JDK first." -ForegroundColor Yellow
    Write-Host "Download from: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "📝 Please provide the following information:" -ForegroundColor Yellow
Write-Host ""

# Generate keystore
& keytool -genkey -v `
    -keystore $KEYSTORE_PATH `
    -keyalg RSA `
    -keysize 2048 `
    -validity $VALIDITY_DAYS `
    -alias $KEY_ALIAS

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Keystore generated successfully!" -ForegroundColor Green
    Write-Host "📁 Location: $KEYSTORE_PATH" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Keep this information safe!" -ForegroundColor Yellow
    Write-Host "   - Keystore file: $KEYSTORE_PATH" -ForegroundColor White
    Write-Host "   - Key alias: $KEY_ALIAS" -ForegroundColor White
    Write-Host "   - Passwords you just entered" -ForegroundColor White
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "   1. Create android\key.properties file" -ForegroundColor White
    Write-Host "   2. Add the following content:" -ForegroundColor White
    Write-Host ""
    Write-Host "      storePassword=YOUR_STORE_PASSWORD" -ForegroundColor Gray
    Write-Host "      keyPassword=YOUR_KEY_PASSWORD" -ForegroundColor Gray
    Write-Host "      keyAlias=$KEY_ALIAS" -ForegroundColor Gray
    Write-Host "      storeFile=$KEYSTORE_PATH" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Never commit key.properties to git!" -ForegroundColor Red
    Write-Host "   4. Upload keystore to CodeMagic securely" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ Failed to generate keystore" -ForegroundColor Red
    exit 1
}
