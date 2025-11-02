# Test Create Employee Edge Function
Write-Host "🧪 Testing create-employee Edge Function..." -ForegroundColor Green
Write-Host ""

# Configuration
$edgeFunctionUrl = "https://dqddxowyikefqcdiioyh.supabase.co/functions/v1/create-employee"

# Get CEO token
Write-Host "📋 Bạn cần CEO auth token để test." -ForegroundColor Yellow
Write-Host "Cách lấy token:" -ForegroundColor Cyan
Write-Host "1. Login as CEO trong browser" -ForegroundColor Gray
Write-Host "2. Mở DevTools (F12)" -ForegroundColor Gray
Write-Host "3. Vào Application > Local Storage > supabase.auth.token" -ForegroundColor Gray
Write-Host "4. Copy giá trị 'access_token'" -ForegroundColor Gray
Write-Host ""

$ceoToken = Read-Host "Nhập CEO auth token"

if (-not $ceoToken) {
    Write-Host "❌ Token không được để trống!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Nhập thông tin nhân viên cần tạo:" -ForegroundColor Yellow

$email = Read-Host "Email (để trống = auto-generate)"
if (-not $email) {
    $email = "staff$(Get-Random -Minimum 1000 -Maximum 9999)@sabohub.com"
    Write-Host "✓ Auto-generated email: $email" -ForegroundColor Gray
}

$password = Read-Host "Password (để trống = auto-generate)"
if (-not $password) {
    $password = "Temp$(Get-Random -Minimum 10000 -Maximum 99999)!"
    Write-Host "✓ Auto-generated password: $password" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Chọn role:" -ForegroundColor Yellow
Write-Host "1. STAFF (Nhân viên)" -ForegroundColor Gray
Write-Host "2. SHIFT_LEADER (Trưởng ca)" -ForegroundColor Gray
Write-Host "3. MANAGER (Quản lý)" -ForegroundColor Gray
$roleChoice = Read-Host "Nhập số (1-3)"

$role = switch ($roleChoice) {
    "1" { "STAFF" }
    "2" { "SHIFT_LEADER" }
    "3" { "MANAGER" }
    default { "STAFF" }
}

Write-Host "✓ Selected role: $role" -ForegroundColor Gray

$companyId = Read-Host "`nCompany ID (UUID)"
if (-not $companyId) {
    Write-Host "❌ Company ID là bắt buộc!" -ForegroundColor Red
    exit 1
}

$fullName = Read-Host "Full Name (để trống = auto-generate)"
if (-not $fullName) {
    $fullName = "Employee $(Get-Random -Minimum 100 -Maximum 999)"
    Write-Host "✓ Auto-generated name: $fullName" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📡 Sending request to Edge Function..." -ForegroundColor Cyan

# Prepare request
$headers = @{
    "Authorization" = "Bearer $ceoToken"
    "Content-Type" = "application/json"
}

$body = @{
    email = $email
    password = $password
    role = $role
    company_id = $companyId
    full_name = $fullName
} | ConvertTo-Json

Write-Host ""
Write-Host "Request body:" -ForegroundColor Gray
Write-Host $body -ForegroundColor DarkGray
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $edgeFunctionUrl `
        -Method Post `
        -Headers $headers `
        -Body $body `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Host "✅ SUCCESS! Employee created!" -ForegroundColor Green
    Write-Host ""
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📧 Email:    " -NoNewline -ForegroundColor Yellow
    Write-Host $response.user.email -ForegroundColor White
    Write-Host "🔒 Password: " -NoNewline -ForegroundColor Yellow
    Write-Host $password -ForegroundColor White
    Write-Host "👤 Role:     " -NoNewline -ForegroundColor Yellow
    Write-Host $response.user.role -ForegroundColor White
    Write-Host "🆔 User ID:  " -NoNewline -ForegroundColor Yellow
    Write-Host $response.user.id -ForegroundColor White
    Write-Host "🏢 Company:  " -NoNewline -ForegroundColor Yellow
    Write-Host $response.user.company_id -ForegroundColor White
    Write-Host "👨‍💼 Name:     " -NoNewline -ForegroundColor Yellow
    Write-Host $response.user.full_name -ForegroundColor White
    Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ Nhân viên có thể login với:" -ForegroundColor Green
    Write-Host "   Email:    $($response.user.email)" -ForegroundColor Gray
    Write-Host "   Password: $password" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: Failed to create employee" -ForegroundColor Red
    Write-Host ""
    Write-Host "Details:" -ForegroundColor Yellow
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Red
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "- Edge Function chưa được deploy" -ForegroundColor Gray
    Write-Host "- Secrets (SUPABASE_SERVICE_ROLE_KEY) chưa được set" -ForegroundColor Gray
    Write-Host "- CEO token không hợp lệ hoặc đã hết hạn" -ForegroundColor Gray
    Write-Host "- User không có role CEO" -ForegroundColor Gray
    Write-Host "- Company ID không tồn tại" -ForegroundColor Gray
    Write-Host "- Email đã tồn tại" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "✅ Test completed!" -ForegroundColor Green
