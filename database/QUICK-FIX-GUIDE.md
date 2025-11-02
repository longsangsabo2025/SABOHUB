# 🚀 QUICK FIX - Apply via Supabase Dashboard

Vì chưa cài đặt PostgreSQL client, hãy áp dụng migration trực tiếp qua Supabase Dashboard:

## **Cách 1: Sử dụng Supabase SQL Editor (RECOMMENDED)**

### **Bước 1: Mở SQL Editor**

1. Truy cập: https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new
2. Copy toàn bộ nội dung file: `database/migrations/999_fix_rls_infinite_recursion.sql`
3. Paste vào SQL Editor
4. Click **"Run"** ▶️

### **Bước 2: Enable Auth Hook**

1. Truy cập: https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/auth/hooks
2. Tìm **"Custom Access Token"** hook
3. Toggle **"Enable Hook"**
4. Select function: `public.custom_access_token_hook`
5. Click **"Save"**

### **Bước 3: Test**

Re-login app để lấy JWT mới:

```dart
// Logout
await supabase.auth.signOut();

// Login lại
await supabase.auth.signInWithPassword(
  email: 'your-email@example.com',
  password: 'your-password',
);

// Test query
final users = await supabase.from('users').select();
// ✅ Should work without infinite recursion error
```

---

## **Cách 2: Sử dụng API Request (Alternative)**

Nếu không muốn dùng Dashboard:

```powershell
# Read SQL file
$sql = Get-Content "database\migrations\999_fix_rls_infinite_recursion.sql" -Raw

# Execute via Supabase API
$headers = @{
    "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
    "Authorization" = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    query = $sql
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "$env:SUPABASE_URL/rest/v1/rpc/exec_sql" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

---

## **Cách 3: Cài đặt PostgreSQL Client (For Future)**

### **Windows:**

```powershell
# Option 1: Winget
winget install PostgreSQL.PostgreSQL

# Option 2: Chocolatey
choco install postgresql

# Option 3: Direct download
# https://www.postgresql.org/download/windows/
```

Sau khi cài, restart terminal và chạy lại:

```powershell
.\database\apply-fix-rls.ps1
```

---

## ✅ **Verification**

Sau khi apply migration, check logs:

```powershell
# Test connection
$env:SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
$env:SUPABASE_ANON_KEY = "your-anon-key"

# Should work now (no infinite recursion)
curl "$env:SUPABASE_URL/rest/v1/users?select=*" `
    -H "apikey: $env:SUPABASE_ANON_KEY" `
    -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🔗 **Quick Links**

- **SQL Editor:** https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new
- **Auth Hooks:** https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/auth/hooks
- **Database Settings:** https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/settings/database
- **Logs:** https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/logs/postgres-logs

---

**Priority:** 🔥 CRITICAL  
**Estimated time:** 5-10 minutes  
**Difficulty:** ⭐⭐ (Easy with dashboard)
