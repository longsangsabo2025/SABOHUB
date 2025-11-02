# AI Features Test Script (PowerShell)
# This script helps you test all AI features locally

Write-Host "🚀 Starting AI Features Test..." -ForegroundColor Green
Write-Host ""

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "❌ Error: .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with OPENAI_API_KEY"
    exit 1
}

# Check if OpenAI API key is set
$envContent = Get-Content ".env" -Raw
if ($envContent -notmatch "OPENAI_API_KEY=") {
    Write-Host "❌ Error: OPENAI_API_KEY not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Environment configured" -ForegroundColor Green
Write-Host ""

# Function to test AI chat
function Test-Chat {
    Write-Host "🧪 Testing AI Chat..." -ForegroundColor Cyan
    Write-Host "1. Run app: flutter run -d chrome"
    Write-Host "2. Navigate to Company Details → AI Assistant"
    Write-Host "3. Send message: 'Xin chào! Phân tích doanh thu.'"
    Write-Host ""
}

# Function to test file upload
function Test-Files {
    Write-Host "🧪 Testing File Upload..." -ForegroundColor Cyan
    Write-Host "1. Click 📎 icon in chat"
    Write-Host "2. Select an image file"
    Write-Host "3. Wait for AI analysis (10-15 seconds)"
    Write-Host "4. Check file gallery (folder icon)"
    Write-Host ""
}

# Function to test recommendations
function Test-Recommendations {
    Write-Host "🧪 Testing Recommendations..." -ForegroundColor Cyan
    Write-Host "1. Click 💡 icon in header"
    Write-Host "2. View recommendations list"
    Write-Host "3. Click on a recommendation"
    Write-Host "4. Accept or Reject"
    Write-Host ""
}

# Main menu
Write-Host "Select test to run:" -ForegroundColor Yellow
Write-Host "1. All tests (recommended)"
Write-Host "2. Chat only"
Write-Host "3. File upload only"
Write-Host "4. Recommendations only"
Write-Host "5. Run Flutter app"
Write-Host ""

$choice = Read-Host "Enter choice (1-5)"

switch ($choice) {
    "1" {
        Write-Host ""
        Test-Chat
        Test-Files
        Test-Recommendations
        Write-Host "✅ All test instructions displayed" -ForegroundColor Green
        Write-Host ""
        $runApp = Read-Host "Run Flutter app now? (y/n)"
        if ($runApp -eq "y") {
            flutter run -d chrome
        }
    }
    "2" {
        Test-Chat
    }
    "3" {
        Test-Files
    }
    "4" {
        Test-Recommendations
    }
    "5" {
        Write-Host "🚀 Starting Flutter app..." -ForegroundColor Green
        flutter run -d chrome
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}
