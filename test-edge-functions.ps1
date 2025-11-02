# Test Edge Functions Locally
# This script tests ai-chat and process-file Edge Functions

Write-Host "🧪 Testing Supabase Edge Functions..." -ForegroundColor Green
Write-Host ""

# Check if .env exists
if (-not (Test-Path "supabase\functions\.env")) {
    Write-Host "❌ Error: supabase/functions/.env not found!" -ForegroundColor Red
    Write-Host "Creating .env file..."
    
    $envContent = Get-Content ".env" -Raw
    if ($envContent -match "OPENAI_API_KEY=(.+)") {
        $apiKey = $matches[1].Trim()
        $supabaseUrl = if ($envContent -match "SUPABASE_URL=(.+)") { $matches[1].Trim() } else { "" }
        $anonKey = if ($envContent -match "SUPABASE_ANON_KEY=(.+)") { $matches[1].Trim() } else { "" }
        $serviceKey = if ($envContent -match "SUPABASE_SERVICE_ROLE_KEY=(.+)") { $matches[1].Trim() } else { "" }
        
        $newEnv = @"
OPENAI_API_KEY=$apiKey
SUPABASE_URL=$supabaseUrl
SUPABASE_ANON_KEY=$anonKey
SUPABASE_SERVICE_ROLE_KEY=$serviceKey
"@
        Set-Content "supabase\functions\.env" $newEnv
        Write-Host "✅ Created supabase/functions/.env" -ForegroundColor Green
    } else {
        Write-Host "❌ OPENAI_API_KEY not found in .env" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Environment configured" -ForegroundColor Green
Write-Host ""

# Menu
Write-Host "Select Edge Function to test:" -ForegroundColor Yellow
Write-Host "1. Test ai-chat function"
Write-Host "2. Test process-file function"
Write-Host "3. Deploy ai-chat to Supabase"
Write-Host "4. Deploy process-file to Supabase"
Write-Host "5. Deploy both functions"
Write-Host "6. Run local Supabase (supabase start)"
Write-Host ""

$choice = Read-Host "Enter choice (1-6)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "🧪 Testing ai-chat Edge Function..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "This function requires:" -ForegroundColor Yellow
        Write-Host "- Valid assistant_id (from ai_assistants table)"
        Write-Host "- Valid company_id (from companies table)"
        Write-Host "- User authentication token"
        Write-Host ""
        Write-Host "To test manually:" -ForegroundColor Yellow
        Write-Host "1. Start Supabase locally: supabase start"
        Write-Host "2. Get auth token from your app"
        Write-Host "3. Run:" -ForegroundColor Yellow
        Write-Host @"
curl -i --location --request POST 'http://localhost:54321/functions/v1/ai-chat' \
  --header 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "assistant_id": "xxx",
    "company_id": "xxx",
    "message": "Xin chào! Phân tích doanh thu."
  }'
"@ -ForegroundColor Gray
        Write-Host ""
    }
    "2" {
        Write-Host ""
        Write-Host "🧪 Testing process-file Edge Function..." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "This function requires:" -ForegroundColor Yellow
        Write-Host "- Valid file_id (from ai_uploaded_files table)"
        Write-Host "- File must be uploaded to Supabase Storage"
        Write-Host "- User authentication token"
        Write-Host ""
        Write-Host "To test manually:" -ForegroundColor Yellow
        Write-Host "1. Upload a file through the app"
        Write-Host "2. Get the file_id from ai_uploaded_files table"
        Write-Host "3. Get auth token from your app"
        Write-Host "4. Run:" -ForegroundColor Yellow
        Write-Host @"
curl -i --location --request POST 'http://localhost:54321/functions/v1/process-file' \
  --header 'Authorization: Bearer YOUR_AUTH_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{
    "file_id": "xxx"
  }'
"@ -ForegroundColor Gray
        Write-Host ""
    }
    "3" {
        Write-Host ""
        Write-Host "🚀 Deploying ai-chat to Supabase..." -ForegroundColor Cyan
        Write-Host ""
        
        # Check if supabase CLI is installed
        $supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
        if (-not $supabaseCli) {
            Write-Host "❌ Supabase CLI not installed!" -ForegroundColor Red
            Write-Host "Install from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Deploying ai-chat function..." -ForegroundColor Yellow
        supabase functions deploy ai-chat --no-verify-jwt
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Deployed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "⚠️ Don't forget to set secrets in Supabase Dashboard:" -ForegroundColor Yellow
            Write-Host "supabase secrets set OPENAI_API_KEY=your-key" -ForegroundColor Gray
        }
    }
    "4" {
        Write-Host ""
        Write-Host "🚀 Deploying process-file to Supabase..." -ForegroundColor Cyan
        Write-Host ""
        
        $supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
        if (-not $supabaseCli) {
            Write-Host "❌ Supabase CLI not installed!" -ForegroundColor Red
            Write-Host "Install from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Deploying process-file function..." -ForegroundColor Yellow
        supabase functions deploy process-file --no-verify-jwt
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Deployed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "⚠️ Don't forget to set secrets in Supabase Dashboard:" -ForegroundColor Yellow
            Write-Host "supabase secrets set OPENAI_API_KEY=your-key" -ForegroundColor Gray
        }
    }
    "5" {
        Write-Host ""
        Write-Host "🚀 Deploying both functions to Supabase..." -ForegroundColor Cyan
        Write-Host ""
        
        $supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
        if (-not $supabaseCli) {
            Write-Host "❌ Supabase CLI not installed!" -ForegroundColor Red
            Write-Host "Install from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Deploying ai-chat..." -ForegroundColor Yellow
        supabase functions deploy ai-chat --no-verify-jwt
        
        Write-Host ""
        Write-Host "Deploying process-file..." -ForegroundColor Yellow
        supabase functions deploy process-file --no-verify-jwt
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Both functions deployed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "⚠️ Set secrets in Supabase Dashboard:" -ForegroundColor Yellow
            Write-Host "supabase secrets set OPENAI_API_KEY=your-key" -ForegroundColor Gray
            Write-Host ""
            Write-Host "📝 Or use CLI:" -ForegroundColor Yellow
            $apiKey = (Get-Content ".env" | Select-String "OPENAI_API_KEY=").ToString().Replace("OPENAI_API_KEY=", "").Trim()
            Write-Host "supabase secrets set OPENAI_API_KEY=$apiKey" -ForegroundColor Gray
        }
    }
    "6" {
        Write-Host ""
        Write-Host "🚀 Starting local Supabase..." -ForegroundColor Cyan
        Write-Host ""
        
        $supabaseCli = Get-Command supabase -ErrorAction SilentlyContinue
        if (-not $supabaseCli) {
            Write-Host "❌ Supabase CLI not installed!" -ForegroundColor Red
            Write-Host "Install from: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
            exit 1
        }
        
        Write-Host "Starting Supabase (this may take a few minutes)..." -ForegroundColor Yellow
        supabase start
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Supabase running!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Access points:" -ForegroundColor Yellow
            Write-Host "- API: http://localhost:54321"
            Write-Host "- Studio: http://localhost:54323"
            Write-Host "- Functions: http://localhost:54321/functions/v1"
            Write-Host ""
            Write-Host "To stop: supabase stop" -ForegroundColor Gray
        }
    }
    default {
        Write-Host "Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✅ Done!" -ForegroundColor Green
