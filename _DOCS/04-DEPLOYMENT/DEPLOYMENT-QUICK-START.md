# ⚡ SABOHUB - DEPLOYMENT QUICK START

## 🎯 TÓM TẮT 5 PHÚT

### ✅ Những gì đã sẵn sàng:

- ✅ Code quality: Clean, no critical errors
- ✅ App version: `1.0.0+1` trong pubspec.yaml
- ✅ Bundle ID: `com.sabohub.app` (iOS & Android)
- ✅ Codemagic config: `codemagic.yaml` đã update
- ✅ Features complete: Task management, employees, documents, attendance, AI

### ⚠️ Những gì CẦN LÀM NGAY:

1. **Setup Codemagic Environment Variables**
2. **Setup Apple Developer & App Store Connect** (iOS)
3. **Setup Google Play Console** (Android)
4. **Trigger builds trên Codemagic**

---

## 📱 **iOS - APP STORE (30 phút)**

### Bước 1: Apple Developer Account (5 phút)
```
✓ Đăng ký: https://developer.apple.com ($99/năm)
✓ Tạo app trên App Store Connect
✓ Bundle ID: com.sabohub.app
```

### Bước 2: App Store Connect API Key (5 phút)
```
1. Vào: https://appstoreconnect.apple.com/access/api
2. Generate API Key (role: App Manager)
3. Download file .p8 (CHỈ 1 LẦN!)
4. Lưu: Issuer ID, Key ID, Private Key content
```

### Bước 3: Codemagic Setup (10 phút)
```
1. Đăng ký Codemagic: https://codemagic.io
2. Connect GitHub repo: SABOHUB
3. Add Environment Variables:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SERVICE_ROLE_KEY
   - GOOGLE_DRIVE_CLIENT_ID_IOS
   - GOOGLE_DRIVE_CLIENT_ID_WEB
   - APP_STORE_CONNECT_ISSUER_ID
   - APP_STORE_CONNECT_KEY_IDENTIFIER
   - APP_STORE_CONNECT_PRIVATE_KEY
4. Setup iOS Code Signing: Enable Automatic
```

### Bước 4: Deploy (10 phút + waiting time)
```bash
# Push code
git push origin master

# Trên Codemagic Dashboard:
1. Select workflow: ios-workflow
2. Click "Start new build"
3. Wait ~20-30 minutes
4. Build → TestFlight automatically
5. Test trên TestFlight
6. Submit to App Store
```

---

## 🤖 **ANDROID - GOOGLE PLAY (25 phút)**

### Bước 1: Google Play Console (5 phút)
```
✓ Đăng ký: https://play.google.com/console ($25 một lần)
✓ Create app
✓ Package name: com.sabohub.app
```

### Bước 2: Create Keystore (5 phút)
```bash
keytool -genkey -v -keystore sabohub-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sabohub

# Lưu password và alias!
# BACKUP file .jks này cẩn thận!
```

### Bước 3: Service Account (5 phút)
```
1. Vào Google Play Console → Setup → API access
2. Create Service Account
3. Grant role: Release Manager
4. Create JSON key
5. Download JSON file
```

### Bước 4: Codemagic Setup (5 phút)
```
1. Upload keystore file (.jks)
2. Add Environment Variables:
   - SUPABASE_URL
   - SUPABASE_ANON_KEY
   - SUPABASE_SERVICE_ROLE_KEY
   - GOOGLE_DRIVE_CLIENT_ID_ANDROID
   - GOOGLE_DRIVE_CLIENT_ID_WEB
   - CM_KEYSTORE_PATH
   - CM_KEYSTORE_PASSWORD
   - CM_KEY_ALIAS
   - CM_KEY_PASSWORD
   - GCLOUD_SERVICE_ACCOUNT_CREDENTIALS (paste JSON)
```

### Bước 5: Deploy (5 phút + waiting time)
```bash
# Push code
git push origin master

# Trên Codemagic Dashboard:
1. Select workflow: android-workflow
2. Click "Start new build"
3. Wait ~15-20 minutes
4. Build → Internal testing track
5. Add testers & test
6. Promote to production
```

---

## 🔥 **FASTEST PATH (Nếu đã có accounts)**

```bash
# 1. Setup environment variables trên Codemagic (10 phút)
# 2. Push code
git add .
git commit -m "chore: deployment v1.0.0"
git push origin master

# 3. Trigger cả 2 builds parallel trên Codemagic
# 4. Đợi ~30 phút
# 5. Test trên TestFlight (iOS) & Internal testing (Android)
# 6. Submit to stores
```

---

## 📊 **DEPLOYMENT STATUS**

### Current Version
- **Version**: `1.0.0`
- **Build Number**: Auto-increment từ Codemagic (`$BUILD_NUMBER`)

### Email Notifications
- **Email**: `longsangsabo2025@gmail.com`
- Change trong `codemagic.yaml` nếu cần

### Build Settings
- **iOS**: TestFlight enabled, App Store disabled (change when ready)
- **Android**: Internal testing track, submit as draft

---

## 🚨 **TROUBLESHOOTING**

### Build failed?
```bash
# Check logs trên Codemagic
# Verify environment variables
# Test local build:
flutter build ios --release
flutter build appbundle --release
```

### Code signing issues (iOS)?
```
→ Use Automatic signing trong Codemagic
→ Verify Bundle ID matches: com.sabohub.app
→ Check API Key permissions
```

### Keystore issues (Android)?
```
→ Verify keystore password correct
→ Check key alias matches
→ Ensure keystore file uploaded
```

---

## 📞 **CẦN TRỢ GIÚP?**

**Tài liệu chi tiết**: 
- `DEPLOYMENT-CHECKLIST-2025.md` (Full checklist)
- `APP-STORE-DEPLOYMENT-GUIDE.md` (Detailed iOS guide)

**Support**:
- Codemagic Docs: https://docs.codemagic.io/
- Flutter Deployment: https://docs.flutter.dev/deployment/

---

**Ready? Let's deploy! 🚀**
