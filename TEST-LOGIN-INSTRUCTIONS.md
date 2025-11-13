# TEST LOGIN - DEMO USER

## Thử với Demo User:

**Email:** `ceo1@sabohub.com`  
**Password:** `demo`

Hoặc:

**Email:** `manager1@sabohub.com`  
**Password:** `demo`

## Debug trong Chrome Console:

Sau khi nhấn "Đăng nhập", bạn sẽ thấy:

```
🔵 [LOGIN] _login() called
✅ [LOGIN] Form validated, starting login...
📧 [LOGIN] Email: ceo1@sabohub.com
🔄 [LOGIN] Calling authProvider.login...
🔵 [AUTH] Login attempt for: ceo1@sabohub.com
✅ [AUTH] Demo user login successful
📊 [LOGIN] Login result: true
✅ [LOGIN] Login successful!
```

## Nếu có lỗi:

Lỗi sẽ hiện với format:
```
❌ [AUTH] AuthException: ...
💥 [AUTH] Unexpected error: ...
```

## Test với Real User (từ Database):

Dùng email từ bảng `users` trong database.
