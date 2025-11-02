# Quick test for OpenAI API Key
Write-Host "🧪 Testing OpenAI API Key..." -ForegroundColor Green
Write-Host ""

# Read API key from .env
$envContent = Get-Content ".env" -Raw
if ($envContent -match "OPENAI_API_KEY=(.+)") {
    $apiKey = $matches[1].Trim()
    Write-Host "✅ Found API key in .env" -ForegroundColor Green
    Write-Host "Key: $($apiKey.Substring(0, 20))..." -ForegroundColor Gray
} else {
    Write-Host "❌ OPENAI_API_KEY not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📡 Making test request to OpenAI API..." -ForegroundColor Cyan

# Test with a simple chat completion
$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $apiKey"
}

$body = @{
    model = "gpt-4-turbo-preview"
    messages = @(
        @{
            role = "system"
            content = "You are a helpful assistant that responds in Vietnamese."
        },
        @{
            role = "user"
            content = "Xin chào! Bạn là ai?"
        }
    )
    max_tokens = 100
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Host "✅ SUCCESS! OpenAI API is working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Response from GPT-4 Turbo:" -ForegroundColor Yellow
    Write-Host $response.choices[0].message.content -ForegroundColor White
    Write-Host ""
    Write-Host "Model: $($response.model)" -ForegroundColor Gray
    Write-Host "Usage: $($response.usage.total_tokens) tokens" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ Your OpenAI API key is working correctly!" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Failed to connect to OpenAI API" -ForegroundColor Red
    Write-Host ""
    Write-Host "Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response:" -ForegroundColor Yellow
        Write-Host $responseBody -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "- API key is invalid or expired"
    Write-Host "- API key doesn't have access to GPT-4 Turbo"
    Write-Host "- Network connection issues"
    Write-Host "- OpenAI API is down"
    exit 1
}
