# 🍎 Apple Sign In Setup Guide

## ✅ Đã Hoàn Thành

### 1. Dependencies
- ✅ Đã thêm `sign_in_with_apple: ^6.1.4`
- ✅ Đã thêm `crypto: ^3.0.6`
- ✅ Đã chạy `flutter pub get`

### 2. Backend Code
- ✅ **AuthProvider** (`lib/providers/auth_provider.dart`):
  - Method `signInWithApple()` với full error handling
  - Nonce generation với SHA-256
  - Supabase OAuth integration
  - Auto-create user profile nếu chưa tồn tại
  
- ✅ **LoginPage** (`lib/pages/auth/login_page.dart`):
  - Apple Sign In button với UI đẹp (black background)
  - Method `_signInWithApple()` với error dialog
  - Loading state handling

### 3. Features
- ✅ Sign in with Apple ID
- ✅ Request email & full name
- ✅ Auto-create user profile in database
- ✅ Check user active status
- ✅ Session management integration
- ✅ Professional error handling

---

## 📱 Cần Cấu Hình (iOS/macOS)

### Step 1: Apple Developer Account
1. Đăng nhập vào [Apple Developer Portal](https://developer.apple.com/)
2. **Enable Sign In with Apple** cho App ID:
   - Identifiers → App IDs → `com.sabohub.app`
   - Capabilities → **Sign In with Apple** → Enable

### Step 2: iOS Configuration (`ios/Runner/Runner.entitlements`)
Tạo file hoặc thêm vào file hiện tại:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

### Step 3: Update Xcode Project
1. Mở `ios/Runner.xcworkspace` trong Xcode
2. Select Runner target
3. **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign In with Apple**

### Step 4: Update Info.plist (nếu cần redirect)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sabohub</string>
        </array>
    </dict>
</array>
```

---

## 🌐 Web Support (Optional)

### Supabase Configuration
Sign In with Apple trên Web yêu cầu thêm cấu hình ở Supabase Dashboard:

1. **Supabase Dashboard** → Authentication → Providers
2. Enable **Apple** provider
3. **Services ID**: Create ở Apple Developer Portal
   - Identifier: `com.sabohub.signin`
   - Return URLs: Add Supabase callback URL
4. **Key ID** & **Team ID**: Lấy từ Apple Developer Account
5. **Private Key**: Download .p8 file và paste content

### Web Deep Link
Cấu hình redirect URL cho web:
```
https://<your-project>.supabase.co/auth/v1/callback
```

---

## 🧪 Testing

### Development Testing
1. **TestFlight** (iOS):
   - Build app và upload lên TestFlight
   - Apple Sign In chỉ work với production/TestFlight builds
   - Không work với Flutter debug mode

2. **Physical Device** (iOS):
   ```bash
   flutter build ios --release
   # Deploy to device through Xcode
   ```

### Test Flow
1. Open app → Login screen
2. Click **"Đăng nhập với Apple"** button
3. Apple Sign In modal appears
4. Authenticate with Face ID / Touch ID / Password
5. App creates user profile in database
6. Redirects to dashboard based on role

---

## 🔒 Security Features

### Nonce Generation
- Random 32-character string
- SHA-256 hashed before sending to Apple
- Protects against replay attacks

### Error Handling
Comprehensive error messages cho các trường hợp:
- ✅ User cancels sign in
- ✅ Authentication failed
- ✅ Invalid response from Apple
- ✅ Network errors
- ✅ Account inactive

### User Data
- Email: Requested from Apple (có thể null nếu user đã sign in trước đó)
- Full Name: Requested (chỉ có lần đầu tiên)
- Apple User ID: Unique identifier
- Default Role: `STAFF` (can be changed by admin)

---

## 📋 Checklist

### Pre-Production
- [ ] Enable Sign In with Apple in Apple Developer Portal
- [ ] Configure Xcode project with capability
- [ ] Test on TestFlight build
- [ ] Test with multiple Apple IDs
- [ ] Verify user profile creation in database

### Production
- [ ] Configure Supabase Apple provider (for web)
- [ ] Set up proper redirect URLs
- [ ] Test on App Store build
- [ ] Monitor error logs
- [ ] Add analytics for Apple Sign In usage

---

## 🐛 Troubleshooting

### "Sign In with Apple is not available"
- Check device iOS version (requires iOS 13+)
- Verify App ID has capability enabled
- Ensure Xcode project has capability added

### "Invalid Client Configuration"
- Check Bundle ID matches Apple Developer Portal
- Verify Services ID is correctly configured
- Ensure redirect URLs are whitelisted

### "User Email is Null"
- User đã sign in trước đó và hide email
- Fallback: Use Apple User ID as identifier
- Show prompt asking user to provide email

---

## 📚 Resources

- [Apple Sign In Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Supabase Apple Provider Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Flutter sign_in_with_apple Package](https://pub.dev/packages/sign_in_with_apple)

---

## ✨ Next Steps

1. **Complete iOS Configuration** (Step 1-3 above)
2. **Test on TestFlight**
3. **Optional: Enable Web Support** (Supabase config)
4. **Add to Signup Page** (tương tự LoginPage)
5. **Add Analytics** tracking for Apple Sign In events

---

**Status**: ✅ Code Implementation Complete  
**Next**: 🔧 iOS Configuration Required  
**Platform**: iOS 13+, macOS 10.15+  
**Dependencies**: Xcode 12+, Apple Developer Account
