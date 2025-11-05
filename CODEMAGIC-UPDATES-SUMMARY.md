# 📝 CẬP NHẬT CODEMAGIC.YAML CHO DEPLOYMENT

## 📅 Ngày: 5 tháng 11, 2025

---

## ✅ **CÁC THAY ĐỔI ĐÃ THỰC HIỆN**

### 1. ✅ Cập nhật Email Notifications

**iOS Workflow:**
```yaml
# TRƯỚC:
recipients:
  - your-email@example.com

# SAU:
recipients:
  - longsangsabo2025@gmail.com # ⚠️ THAY ĐỔI EMAIL CỦA BẠN Ở ĐÂY
```

**Android Workflow:**
```yaml
# TRƯỚC:
recipients:
  - your-email@example.com

# SAU:
recipients:
  - longsangsabo2025@gmail.com # ⚠️ THAY ĐỔI EMAIL CỦA BẠN Ở ĐÂY
```

### 2. ✅ Fix iOS Build Command

**TRƯỚC:**
```yaml
flutter build ipa --release \
  --build-name=1.0.$BUILD_NUMBER \
  --build-number=$BUILD_NUMBER \
  --export-options-plist=/Users/builder/export_options.plist
```

**Vấn đề**: 
- Version number không đúng format: `1.0.$BUILD_NUMBER` nên là `1.0.0`
- Tham chiếu file `export_options.plist` không tồn tại

**SAU:**
```yaml
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=$BUILD_NUMBER
```

**Giải thích**:
- `build-name`: Semantic version (1.0.0) - hiển thị cho user
- `build-number`: Auto-increment từ Codemagic - dùng để track builds

### 3. ✅ Fix Android Build Command

**TRƯỚC:**
```yaml
flutter build appbundle --release \
  --build-name=1.0.$BUILD_NUMBER \
  --build-number=$BUILD_NUMBER
```

**SAU:**
```yaml
flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=$BUILD_NUMBER
```

### 4. ✅ App Store Submission Setting

**SAU:**
```yaml
app_store_connect:
  api_key: $APP_STORE_CONNECT_PRIVATE_KEY
  key_id: $APP_STORE_CONNECT_KEY_IDENTIFIER
  issuer_id: $APP_STORE_CONNECT_ISSUER_ID
  submit_to_testflight: true
  submit_to_app_store: false # Set to true when ready for App Store submission
```

**Giải thích**:
- `submit_to_testflight: true` - Tự động upload lên TestFlight sau build
- `submit_to_app_store: false` - Không tự động submit lên App Store (đổi thành `true` khi ready)

---

## 📋 **NHỮNG GÌ CẦN LÀM TIẾP**

### ⚠️ QUAN TRỌNG - Trước khi deploy:

#### 1. Setup Environment Variables trên Codemagic

Vào **Codemagic Dashboard** → Your App → **Environment variables**, thêm:

**Supabase (Required):**
```
SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
SUPABASE_ANON_KEY=<your-anon-key-from-.env>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key-from-.env>
```

**Google Drive (Required):**
```
GOOGLE_DRIVE_CLIENT_ID_IOS=<your-ios-client-id>
GOOGLE_DRIVE_CLIENT_ID_WEB=<your-web-client-id>
GOOGLE_DRIVE_CLIENT_ID_ANDROID=<your-android-client-id>
```

**iOS - App Store Connect API (Required cho iOS build):**
```
APP_STORE_CONNECT_ISSUER_ID=<issuer-id-from-app-store-connect>
APP_STORE_CONNECT_KEY_IDENTIFIER=<key-id>
APP_STORE_CONNECT_PRIVATE_KEY=<paste-entire-.p8-file-content>
```

**Android - Google Play (Required cho Android build):**
```
CM_KEYSTORE_PATH=<path-to-uploaded-keystore>
CM_KEYSTORE_PASSWORD=<your-keystore-password>
CM_KEY_ALIAS=<your-key-alias>
CM_KEY_PASSWORD=<your-key-password>
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS=<paste-service-account-json>
```

#### 2. iOS Code Signing

**Option A: Automatic (Khuyến nghị)**
1. Vào Codemagic → iOS code signing
2. Connect Apple Developer account
3. Enable automatic code signing
4. Chọn distribution type: `app_store`

**Option B: Manual**
1. Tạo Distribution Certificate
2. Tạo Provisioning Profile
3. Upload lên Codemagic

#### 3. Android Keystore

**Create keystore nếu chưa có:**
```bash
keytool -genkey -v -keystore sabohub-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sabohub
```

**Upload lên Codemagic:**
1. Vào Codemagic → Android code signing
2. Upload file `.jks`
3. Set environment variables (password, alias)

#### 4. Verify Email

Đảm bảo email `longsangsabo2025@gmail.com` là đúng hoặc thay đổi trong `codemagic.yaml`

---

## 🚀 **DEPLOYMENT PROCESS**

### iOS (App Store):

```bash
# 1. Commit & push
git add .
git commit -m "chore: prepare for iOS deployment v1.0.0"
git push origin master

# 2. Trigger build trên Codemagic
# → Dashboard → ios-workflow → Start new build

# 3. Wait ~20-30 minutes
# → Build → Upload to TestFlight

# 4. Test trên TestFlight
# → App Store Connect → TestFlight → Add testers

# 5. Submit to App Store (khi ready)
# → Đổi submit_to_app_store: true trong codemagic.yaml
# → Trigger build mới
```

### Android (Google Play):

```bash
# 1. Commit & push
git add .
git commit -m "chore: prepare for Android deployment v1.0.0"
git push origin master

# 2. Trigger build trên Codemagic
# → Dashboard → android-workflow → Start new build

# 3. Wait ~15-20 minutes
# → Build → Upload to Internal testing

# 4. Test với internal testers
# → Google Play Console → Internal testing

# 5. Promote to production (khi ready)
# → Internal → Closed → Open → Production
```

---

## 📊 **BUILD CONFIGURATION SUMMARY**

| Platform | Version | Build # | Submit To | Status |
|----------|---------|---------|-----------|--------|
| iOS      | 1.0.0   | Auto    | TestFlight | ✅ Ready |
| iOS      | 1.0.0   | Auto    | App Store | ⚠️ Manual (change flag) |
| Android  | 1.0.0   | Auto    | Internal | ✅ Ready |
| Android  | 1.0.0   | Auto    | Production | ⚠️ Manual (promote) |

---

## 📁 **TÀI LIỆU LIÊN QUAN**

- **DEPLOYMENT-CHECKLIST-2025.md** - Full deployment checklist với tất cả steps
- **DEPLOYMENT-QUICK-START.md** - Quick reference guide (5 phút)
- **APP-STORE-DEPLOYMENT-GUIDE.md** - Chi tiết về iOS deployment
- **codemagic.yaml** - CI/CD configuration file

---

## ✅ **VERIFICATION CHECKLIST**

Trước khi trigger builds, verify:

- [x] ✅ `codemagic.yaml` đã update email
- [x] ✅ Version trong `pubspec.yaml`: `1.0.0+1`
- [x] ✅ Bundle ID: `com.sabohub.app` (iOS)
- [x] ✅ Package name: `com.sabohub.app` (Android)
- [ ] ⚠️ Environment variables đã setup trên Codemagic
- [ ] ⚠️ iOS code signing configured
- [ ] ⚠️ Android keystore uploaded
- [ ] ⚠️ App Store Connect API key added
- [ ] ⚠️ Google Play service account added

---

## 🎯 **NEXT STEPS**

1. **Setup accounts** (nếu chưa có):
   - Apple Developer ($99/năm)
   - Google Play Console ($25 một lần)

2. **Complete Codemagic setup**:
   - Environment variables
   - Code signing
   - Test connections

3. **Trigger test builds**:
   - Start với iOS workflow
   - Sau đó Android workflow
   - Monitor logs

4. **Internal testing**:
   - TestFlight (iOS)
   - Internal testing track (Android)

5. **Production deployment**:
   - Submit to App Store
   - Promote to Google Play production

---

**Ready to deploy! 🚀**
