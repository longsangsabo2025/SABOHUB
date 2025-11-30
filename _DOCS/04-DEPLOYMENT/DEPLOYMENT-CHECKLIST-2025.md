# 🚀 SABOHUB - CHECKLIST DEPLOYMENT APP STORE & GOOGLE PLAY (2025)

## 📅 **Cập nhật**: 5 tháng 11, 2025
## ✅ **Trạng thái**: Ready for deployment

---

## 📋 **PHẦN 1: KIỂM TRA TRƯỚC KHI DEPLOY**

### 1.1 ✅ Code Quality & Testing

- [x] **Flutter analyze**: Không có error nghiêm trọng
- [x] **Flutter test**: Unit tests pass
- [x] **Manual testing**: Đã test trên iOS & Android emulator
- [x] **Features complete**: 
  - ✅ Task management với recurrence
  - ✅ Change assignee
  - ✅ 2-row compact task cards
  - ✅ Priority & deadline indicators
  - ✅ Employee management
  - ✅ Company management
  - ✅ Authentication flow
  - ✅ Document management
  - ✅ Attendance tracking
  - ✅ AI Assistant

### 1.2 ✅ App Configuration

- [x] **pubspec.yaml**: Version `1.0.0+1` ✓
- [x] **Bundle ID iOS**: `com.sabohub.app` ✓
- [x] **Package name Android**: `com.sabohub.app` ✓
- [x] **App name**: `SABOHUB` ✓
- [x] **Info.plist**: Display name & permissions đã setup ✓

### 1.3 ⚠️ Environment Variables (CẦN SETUP TRÊN CODEMAGIC)

**Supabase:**
```bash
SUPABASE_URL=https://dqddxowyikefqcdiioyh.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

**Google Drive:**
```bash
GOOGLE_DRIVE_CLIENT_ID_IOS=<your-ios-client-id>
GOOGLE_DRIVE_CLIENT_ID_WEB=<your-web-client-id>
GOOGLE_DRIVE_CLIENT_ID_ANDROID=<your-android-client-id>
```

### 1.4 ⚠️ Assets & Resources

- [ ] **App Icon**: Đã có đầy đủ sizes (iOS & Android)
- [ ] **Splash Screen**: Đã setup launch screen
- [ ] **Screenshots**: Chuẩn bị screenshots cho App Store & Google Play
  - iPhone 6.7" (3 screenshots tối thiểu)
  - iPad 12.9" (3 screenshots tối thiểu)
  - Android Phone (tối thiểu 2 screenshots)
- [ ] **Marketing materials**: App description, keywords, promotional text

---

## 📋 **PHẦN 2: APPLE APP STORE DEPLOYMENT**

### 2.1 ⚠️ Apple Developer Account Setup

- [ ] **Tài khoản**: Đã đăng ký Apple Developer ($99/năm)
- [ ] **App Store Connect**: Đã tạo app với Bundle ID `com.sabohub.app`
- [ ] **App Information**:
  - App Name: `SABOHUB`
  - Primary Language: `Vietnamese`
  - Category: `Business` hoặc `Productivity`
  - Content Rights: Có

### 2.2 ⚠️ iOS Code Signing

**Cách 1: Automatic Signing (Khuyến nghị)**
- [ ] Connect Codemagic với Apple Developer account
- [ ] Enable automatic code signing trong Codemagic
- [ ] Chọn distribution type: `app_store`

**Cách 2: Manual Signing**
- [ ] Tạo Distribution Certificate (.p12)
- [ ] Tạo App Store Provisioning Profile
- [ ] Upload lên Codemagic

### 2.3 ⚠️ App Store Connect API Key

Để Codemagic có thể upload build lên App Store Connect:

1. Truy cập: https://appstoreconnect.apple.com/access/api
2. Tạo API Key với role `App Manager` hoặc `Admin`
3. Download file `.p8` (CHỈ DOWNLOAD ĐƯỢC 1 LẦN!)
4. Lưu thông tin:
   - **Issuer ID**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Key ID**: `XXXXXXXXXX`
   - **Private Key**: Nội dung file `.p8`

5. Setup trong Codemagic Environment Variables:
   ```
   APP_STORE_CONNECT_ISSUER_ID=<issuer-id>
   APP_STORE_CONNECT_KEY_IDENTIFIER=<key-id>
   APP_STORE_CONNECT_PRIVATE_KEY=<paste-entire-p8-content>
   ```

### 2.4 ✅ Codemagic iOS Workflow

- [x] **File**: `codemagic.yaml` - iOS workflow ✓
- [x] **Email notification**: Updated to `longsangsabo2025@gmail.com` ✓
- [x] **Build version**: `1.0.0` with build number from CI ✓
- [x] **TestFlight**: Enabled (`submit_to_testflight: true`) ✓
- [ ] **App Store**: Disabled (`submit_to_app_store: false`) - Enable khi ready

### 2.5 🎯 Deployment Steps - iOS

**Step 1: Push to GitHub**
```bash
git add .
git commit -m "chore: prepare for iOS App Store deployment"
git push origin master
```

**Step 2: Trigger build trên Codemagic**
- Vào Codemagic Dashboard
- Chọn workflow: `ios-workflow`
- Click **Start new build**

**Step 3: Monitor build process**
- Build duration: ~15-30 phút
- Theo dõi logs để xem có lỗi không

**Step 4: Kiểm tra TestFlight**
- Build sẽ tự động upload lên TestFlight
- Mở App Store Connect → TestFlight
- Build sẽ ở trạng thái "Processing" (~15-30 phút)
- Sau khi processing xong, add internal testers

**Step 5: Submit lên App Store**
- Sau khi test OK trên TestFlight
- Đổi `submit_to_app_store: true` trong `codemagic.yaml`
- Trigger build mới
- Hoặc submit manually từ App Store Connect

---

## 📋 **PHẦN 3: GOOGLE PLAY STORE DEPLOYMENT**

### 3.1 ⚠️ Google Play Console Setup

- [ ] **Tài khoản**: Đã đăng ký Google Play Console ($25 một lần)
- [ ] **Create App**: Đã tạo app với package name `com.sabohub.app`
- [ ] **App Information**:
  - App Name: `SABOHUB`
  - Default Language: `Vietnamese`
  - Category: `Business` hoặc `Productivity`
  - Target audience: Adults (18+)

### 3.2 ⚠️ Android App Signing

**Option A: Google Play App Signing (Khuyến nghị)**
- [ ] Enroll in Google Play App Signing
- [ ] Google sẽ quản lý production signing key
- [ ] Bạn chỉ cần upload key để sign upload

**Option B: Manual Signing**
- [ ] Tạo keystore file (.jks)
- [ ] Lưu thông tin keystore securely:
  ```
  storePassword=<your-password>
  keyPassword=<your-key-password>
  keyAlias=<your-alias>
  ```

### 3.3 ⚠️ Service Account Setup

Để Codemagic upload build lên Google Play:

1. Vào Google Play Console → Setup → API access
2. Create Service Account trên Google Cloud
3. Grant permissions: `Release Manager` role
4. Tạo JSON key file
5. Upload vào Codemagic Environment Variables:
   ```
   GCLOUD_SERVICE_ACCOUNT_CREDENTIALS=<paste-json-content>
   ```

### 3.4 ⚠️ Android Keystore Setup trong Codemagic

1. Upload keystore file (.jks) lên Codemagic
2. Setup environment variables:
   ```
   CM_KEYSTORE_PATH=<path-to-keystore>
   CM_KEYSTORE_PASSWORD=<store-password>
   CM_KEY_ALIAS=<key-alias>
   CM_KEY_PASSWORD=<key-password>
   ```

### 3.5 ✅ Codemagic Android Workflow

- [x] **File**: `codemagic.yaml` - Android workflow ✓
- [x] **Email notification**: Updated ✓
- [x] **Build version**: `1.0.0` with build number ✓
- [x] **Track**: `internal` (internal testing) ✓
- [x] **Submit as draft**: `true` ✓

### 3.6 🎯 Deployment Steps - Android

**Step 1: Push to GitHub**
```bash
git add .
git commit -m "chore: prepare for Google Play deployment"
git push origin master
```

**Step 2: Trigger build trên Codemagic**
- Vào Codemagic Dashboard
- Chọn workflow: `android-workflow`
- Click **Start new build**

**Step 3: Monitor build process**
- Build duration: ~10-20 phút
- Theo dõi logs

**Step 4: Kiểm tra Google Play Console**
- Build sẽ upload lên Internal testing track
- Mở Google Play Console → Testing → Internal testing
- Add internal testers để test

**Step 5: Promote to Production**
- Sau khi test OK
- Promote từ Internal → Closed testing → Open testing → Production
- Submit for review (~3-7 days)

---

## 📋 **PHẦN 4: DEPLOYMENT CHECKLIST CUỐI CÙNG**

### 4.1 Pre-Deployment

- [x] Code đã commit và push lên GitHub
- [x] `codemagic.yaml` đã update email
- [x] Version number trong `pubspec.yaml`: `1.0.0+1`
- [ ] Environment variables đã setup trên Codemagic
- [ ] App icons & splash screen ready
- [ ] Screenshots prepared

### 4.2 iOS Deployment

- [ ] Apple Developer account active
- [ ] App Store Connect app created
- [ ] API Key setup trong Codemagic
- [ ] Code signing setup (auto hoặc manual)
- [ ] Build triggered trên Codemagic
- [ ] TestFlight build uploaded
- [ ] Internal testing completed
- [ ] App Store submission

### 4.3 Android Deployment

- [ ] Google Play Console account active
- [ ] App created with correct package name
- [ ] Service account setup
- [ ] Keystore uploaded to Codemagic
- [ ] Build triggered trên Codemagic
- [ ] Internal testing track uploaded
- [ ] Internal testing completed
- [ ] Production submission

### 4.4 Post-Deployment

- [ ] Monitor crash reports (Firebase Crashlytics)
- [ ] Track analytics (Firebase Analytics)
- [ ] Respond to user reviews
- [ ] Plan for updates & bug fixes

---

## 🚨 **CÁC LƯU Ý QUAN TRỌNG**

### ⚠️ **Những thứ CẦN LÀM NGAY:**

1. **Thay đổi email trong codemagic.yaml**
   - Hiện tại: `longsangsabo2025@gmail.com`
   - Kiểm tra xem có đúng không

2. **Setup Environment Variables trên Codemagic**
   - Supabase credentials
   - Google Drive client IDs
   - App Store Connect API key (iOS)
   - Google Cloud service account (Android)
   - Android keystore info

3. **Chuẩn bị App Icons & Screenshots**
   - iOS: 6.7" và 12.9" screenshots
   - Android: Phone screenshots
   - App description (Vietnamese & English)

4. **Create keystore cho Android** (nếu chưa có)
   ```bash
   keytool -genkey -v -keystore sabohub-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias sabohub
   ```

### ⚠️ **Những thứ KHÔNG NÊN LÀM:**

1. ❌ Push service account JSON hoặc API keys vào Git
2. ❌ Hardcode sensitive data trong code
3. ❌ Submit trực tiếp lên production mà không test
4. ❌ Quên backup keystore file (Android)
5. ❌ Dùng debug signing cho production build

---

## 📞 **HỖ TRỢ**

### Tài liệu tham khảo:

- **Codemagic Docs**: https://docs.codemagic.io/
- **Flutter iOS Deployment**: https://docs.flutter.dev/deployment/ios
- **Flutter Android Deployment**: https://docs.flutter.dev/deployment/android
- **App Store Connect**: https://developer.apple.com/app-store-connect/
- **Google Play Console**: https://play.google.com/console/

### Nếu gặp lỗi:

1. Kiểm tra Codemagic build logs
2. Verify environment variables
3. Test local build trước:
   ```bash
   flutter build ios --release
   flutter build appbundle --release
   ```

---

## ✅ **READY TO DEPLOY?**

Nếu bạn đã hoàn thành tất cả checkboxes, chạy lệnh:

```bash
# Commit final changes
git add .
git commit -m "chore: ready for App Store & Google Play deployment"
git push origin master

# Trigger builds on Codemagic dashboard
# ios-workflow → TestFlight → App Store
# android-workflow → Internal testing → Production
```

**Chúc bạn deploy thành công! 🚀🎉**
