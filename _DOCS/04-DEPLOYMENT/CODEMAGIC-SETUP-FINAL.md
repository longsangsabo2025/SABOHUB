# 🚀 CODEMAGIC ENVIRONMENT VARIABLES - SETUP GUIDE

## ✅ Code đã được push lên GitHub!

**Commit**: `340e175`  
**Status**: Successfully pushed to master

---

## 📋 NEXT STEP: Add Environment Variables to Codemagic

### 🔗 URL
https://codemagic.io/apps

---

## 🔑 Environment Variables cần thêm

### Bước 1: Login và chọn app SABOHUB

1. Vào https://codemagic.io/apps
2. Login với GitHub account
3. Click vào app **SABOHUB**

### Bước 2: Vào Environment Variables

1. Click **"App settings"** (⚙️ icon)
2. Click **"Environment variables"** (bên trái)
3. Click **"Add variable"** hoặc **"Add group"**

---

## 📦 Option A: Add từng biến (Recommended)

### Group: `app_store` (Tạo mới nếu chưa có)

Click **"Add new group"** → Đặt tên: `app_store`

**Thêm các biến sau:**

#### 1. SUPABASE_URL
```
Variable name: SUPABASE_URL
Value: https://dqddxowyikefqcdiioyh.supabase.co
Group: app_store
Secure: ✅ (check)
```

#### 2. SUPABASE_ANON_KEY
```
Variable name: SUPABASE_ANON_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y
Group: app_store
Secure: ✅ (check)
```

#### 3. SUPABASE_SERVICE_ROLE_KEY
```
Variable name: SUPABASE_SERVICE_ROLE_KEY
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI
Group: app_store
Secure: ✅ (check)
```

#### 4. GOOGLE_DRIVE_CLIENT_ID_IOS
```
Variable name: GOOGLE_DRIVE_CLIENT_ID_IOS
Value: 321771498359-ocllju34h6cd4040ipoeq41j8mmg08p8.apps.googleusercontent.com
Group: app_store
Secure: ✅ (check)
```

#### 5. GOOGLE_DRIVE_CLIENT_ID_WEB
```
Variable name: GOOGLE_DRIVE_CLIENT_ID_WEB
Value: 321771498359-gcm0og29knjjmaevr7uv0aa27vam765u.apps.googleusercontent.com
Group: app_store
Secure: ✅ (check)
```

#### 6. GOOGLE_DRIVE_CLIENT_ID_ANDROID
```
Variable name: GOOGLE_DRIVE_CLIENT_ID_ANDROID
Value: 321771498359-tmnp2ks7n6ipjp10fsrjrefrilr6ts15.apps.googleusercontent.com
Group: app_store
Secure: ✅ (check)
```

---

## 📦 Option B: Import từ file (Nhanh hơn)

### Bước 1: Copy đoạn này
```env
SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI
GOOGLE_DRIVE_CLIENT_ID_IOS=321771498359-ocllju34h6cd4040ipoeq41j8mmg08p8.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_WEB=321771498359-gcm0og29knjjmaevr7uv0aa27vam765u.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_ANDROID=321771498359-tmnp2ks7n6ipjp10fsrjrefrilr6ts15.apps.googleusercontent.com
```

### Bước 2: Import vào Codemagic
1. Trong **Environment variables** page
2. Click **"Import from .env"** (nếu có)
3. Paste đoạn trên
4. Chọn group: `app_store`
5. Click **"Import"**

---

## 🔐 App Store Connect API Keys (Nếu chưa có)

**⚠️ CHỈ CẦN nếu bạn muốn tự động submit lên TestFlight**

Nếu đã setup Automatic Code Signing, bạn CÓ THỂ bỏ qua phần này.

### Tạo API Key trên App Store Connect

1. Vào https://appstoreconnect.apple.com/access/api
2. Click **"Keys"** → **"+"** (Generate API Key)
3. Name: `Codemagic CI/CD`
4. Access: **App Manager**
5. Click **"Generate"**
6. **QUAN TRỌNG**: Download file `.p8` NGAY!

### Add vào Codemagic

```
Variable name: APP_STORE_CONNECT_ISSUER_ID
Value: [Your Issuer ID from App Store Connect]
Group: app_store
Secure: ✅

Variable name: APP_STORE_CONNECT_KEY_IDENTIFIER
Value: [Your Key ID from App Store Connect]
Group: app_store
Secure: ✅

Variable name: APP_STORE_CONNECT_PRIVATE_KEY
Value: [Paste ENTIRE content of .p8 file including BEGIN/END lines]
Group: app_store
Secure: ✅
```

---

## 🎯 Sau khi add xong Environment Variables

### Bước 3: Setup iOS Code Signing

**Option A: Automatic (Recommended)**

1. Vào **"iOS code signing"** (bên trái menu)
2. Click **"Automatic code signing"**
3. Click **"Connect Apple Developer Portal"**
4. Login với Apple ID
5. Codemagic sẽ tự động setup certificates & profiles

**Option B: Manual**

1. Tạo Distribution Certificate trên Apple Developer
2. Export certificate (.p12) với password
3. Tạo Provisioning Profile
4. Upload lên Codemagic

---

### Bước 4: Trigger Build

**Option 1: Auto trigger (Đã setup)**
- Push đã trigger build tự động
- Check Codemagic dashboard xem build đang chạy

**Option 2: Manual trigger**
1. Codemagic Dashboard → SABOHUB app
2. Click **"Start new build"**
3. Select workflow: **ios-workflow**
4. Click **"Start build"**

---

## 📊 Build Status

### Monitor build:
1. Check real-time logs trong Codemagic
2. Build time: ~15-25 phút
3. Email notification khi xong

### Build Steps:
```
✅ Clone repository (30s)
✅ Setup Flutter (2min)
✅ Setup Xcode (1min)
✅ Create .env file (5s)      ← Environment variables được dùng ở đây
✅ Get Flutter packages (1min)
✅ Install CocoaPods (2min)
✅ Flutter analyze (30s)
✅ Flutter test (1min)
✅ Build IPA (10min)
✅ Code sign (1min)
✅ Upload to TestFlight (2min)
```

---

## ✅ Checklist

### Pre-build:
- ✅ Code pushed to GitHub
- ⏳ Environment variables added to Codemagic
- ⏳ iOS Code Signing setup
- ⏳ Build triggered

### Post-build:
- ⏳ Build success
- ⏳ IPA uploaded to TestFlight
- ⏳ Email notification received
- ⏳ App appears in App Store Connect

---

## 🆘 Troubleshooting

### Build fails với "Environment variable not found"
→ Check lại tên biến trong Codemagic (case-sensitive)

### Build fails với "Code signing error"
→ Use Automatic code signing hoặc check certificates

### Build success nhưng không thấy trên TestFlight
→ Check App Store Connect → TestFlight → Processing status

---

## 📱 Quick Access Links

- **Codemagic**: https://codemagic.io/apps
- **App Store Connect**: https://appstoreconnect.apple.com
- **Apple Developer**: https://developer.apple.com
- **Google Cloud Console**: https://console.cloud.google.com

---

## 🎯 NEXT IMMEDIATE ACTION

**Bây giờ bạn cần:**

1. ✅ Vào https://codemagic.io/apps
2. ✅ Login và chọn SABOHUB app
3. ✅ Add 6 environment variables (hoặc import từ .env)
4. ✅ Setup iOS Code Signing (Automatic recommended)
5. ✅ Check xem build đã auto trigger chưa
6. ✅ Nếu chưa → Click "Start new build"

**Mất khoảng 5-10 phút để setup!** 🚀

---

Good luck! Báo tôi nếu có vấn đề gì! 😊
