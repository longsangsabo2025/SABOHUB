# 🚀 HƯỚNG DẪN DEPLOY SABOHUB LÊN APP STORE

## 📋 Checklist trước khi deploy

### 1. ✅ Chuẩn bị Apple Developer Account

- [ ] Đã có **Apple Developer Account** ($99/năm)
- [ ] Đã tạo **App ID**: `com.sabohub.app`
- [ ] Đã tạo **App** trên App Store Connect
- [ ] Đã setup **App Store Connect API Key**

### 2. ✅ Chuẩn bị Certificates & Provisioning Profiles

Bạn có 2 cách:

#### Cách 1: Automatic (Khuyến nghị - Dễ hơn)
Codemagic sẽ tự động tạo certificates và provisioning profiles.

#### Cách 2: Manual
- [ ] Tạo **Distribution Certificate** (.p12 file)
- [ ] Tạo **Provisioning Profile** (App Store Distribution)
- [ ] Upload lên Codemagic

### 3. ✅ Setup Codemagic

#### Bước 1: Tạo tài khoản Codemagic
1. Truy cập: https://codemagic.io
2. Sign up bằng GitHub account
3. Connect repository `SABOHUB`

#### Bước 2: Setup Environment Variables
Vào **Codemagic Dashboard** → Your App → **Environment variables**

Thêm các biến sau:

**Supabase:**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

**Google Drive:**
```
GOOGLE_DRIVE_CLIENT_ID_IOS=your-ios-client-id.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_WEB=your-web-client-id.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_ANDROID=your-android-client-id.apps.googleusercontent.com
```

**App Store Connect API:**
```
APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_KEY_IDENTIFIER=XXXXXXXXXX
APP_STORE_CONNECT_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
```

#### Bước 3: Setup iOS Signing

**Option A: Automatic Signing (Khuyến nghị)**

1. Vào **Codemagic Dashboard** → Your App → **iOS code signing**
2. Chọn **Automatic code signing**
3. Connect Apple Developer account
4. Codemagic sẽ tự động tạo và manage certificates

**Option B: Manual Signing**

1. Tạo certificates trên Apple Developer Portal
2. Export certificates (.p12 file) và provisioning profile
3. Upload lên Codemagic

#### Bước 4: Lấy App Store Connect API Key

1. Truy cập: https://appstoreconnect.apple.com/access/api
2. Click **"Generate API Key"** hoặc chọn key có sẵn
3. Lưu lại:
   - **Issuer ID**
   - **Key ID** 
   - **Private Key** (file .p8 - download ngay, chỉ download được 1 lần!)

4. Thêm vào Codemagic Environment Variables:
   ```
   APP_STORE_CONNECT_ISSUER_ID=your-issuer-id
   APP_STORE_CONNECT_KEY_IDENTIFIER=your-key-id
   APP_STORE_CONNECT_PRIVATE_KEY=<paste-content-of-.p8-file>
   ```

---

## 🚀 Deploy Flow

### 1. Local Build Test (Optional)

Test build IPA trên máy local trước:

```bash
# Clean project
flutter clean
flutter pub get

# Build iOS (cần macOS + Xcode)
flutter build ios --release

# Hoặc build IPA
flutter build ipa --release
```

### 2. Push code lên GitHub

```bash
git add .
git commit -m "chore: prepare for App Store deployment"
git push origin master
```

### 3. Trigger Build trên Codemagic

#### Cách 1: Automatic (Khuyến nghị)
- Mỗi khi push code lên `master` branch
- Codemagic sẽ tự động trigger build

#### Cách 2: Manual
1. Vào Codemagic Dashboard
2. Select app: **SABOHUB**
3. Click **"Start new build"**
4. Chọn workflow: **ios-workflow**
5. Click **"Start build"**

### 4. Theo dõi Build Process

Codemagic sẽ thực hiện các bước sau:

1. ✅ **Clone repository** từ GitHub
2. ✅ **Setup environment** (Flutter, Xcode, CocoaPods)
3. ✅ **Create .env file** với environment variables
4. ✅ **Get Flutter packages** (`flutter pub get`)
5. ✅ **Install iOS dependencies** (`pod install`)
6. ✅ **Run Flutter analyze** (check code quality)
7. ✅ **Run tests** (`flutter test`)
8. ✅ **Build IPA** (`flutter build ipa`)
9. ✅ **Code sign** với certificates
10. ✅ **Upload to TestFlight** automatically
11. ✅ **Send email notification**

**⏱️ Thời gian build**: ~15-25 phút

### 5. Check Build Status

- **Success** ✅: IPA đã được upload lên TestFlight
- **Failed** ❌: Check logs để xem lỗi gì

**Xem logs:**
- Codemagic Dashboard → Build → View logs
- Tìm dòng có ERROR hoặc FAILED

---

## 📱 TestFlight & App Store

### 1. TestFlight (Internal Testing)

Sau khi build thành công:

1. Mở **App Store Connect**: https://appstoreconnect.apple.com
2. Vào app **SABOHUB**
3. Tab **TestFlight**
4. Build mới sẽ xuất hiện (processing ~10-30 phút)
5. Sau khi processing xong, thêm **Internal Testers**
6. Testers sẽ nhận notification để download TestFlight app

### 2. Submit lên App Store (Production)

Khi đã test xong trên TestFlight:

#### Bước 1: Prepare App Store Listing

Trên App Store Connect:

1. **App Information**:
   - Name: SABOHUB
   - Category: Business / Productivity
   - Subtitle: Quản lý quán bida chuyên nghiệp
   
2. **Pricing**: Free hoặc Paid

3. **App Privacy**: Khai báo data collection
   - Account creation
   - Location data (nếu dùng)
   - User data storage

4. **Screenshots**: (Bắt buộc)
   - iPhone 6.7" (iPhone 14 Pro Max)
   - iPhone 6.5" (iPhone 11 Pro Max)
   - iPad Pro 12.9"
   
5. **App Description**:
   ```
   SABOHUB - Giải pháp quản lý quán bida toàn diện
   
   🎱 Tính năng chính:
   • Quản lý bàn bi-a và đặt chỗ
   • Theo dõi doanh thu thời gian thực
   • Quản lý nhân viên và công việc
   • Báo cáo và phân tích kinh doanh
   • Hỗ trợ đa chi nhánh
   • Tích hợp AI Assistant
   ```

6. **Keywords**: billiards, pool, quản lý, business, quán bida

7. **Support URL**: Website hoặc email support

8. **Marketing URL**: Website chính

#### Bước 2: Submit for Review

1. Chọn build từ TestFlight
2. Click **"Submit for Review"**
3. Trả lời questionnaire về Export Compliance
4. Click **"Submit"**

**⏱️ Thời gian review**: 1-3 ngày (average ~24 giờ)

#### Bước 3: App Review Process

Apple sẽ review app:
- ✅ **Waiting for Review**: Đang chờ
- 🔄 **In Review**: Đang review (1-2 ngày)
- ✅ **Ready for Sale**: Approved! App đã live trên App Store
- ❌ **Rejected**: Bị từ chối, xem lý do và fix

---

## 🐛 Common Issues & Solutions

### Issue 1: Build Failed - Code Signing

**Error**: `No profiles for 'com.sabohub.app' were found`

**Solution**:
1. Check Apple Developer Portal
2. Verify Bundle ID matches: `com.sabohub.app`
3. Re-setup iOS code signing trong Codemagic
4. Try Automatic code signing

### Issue 2: Build Failed - Pod Install

**Error**: `pod install failed`

**Solution**:
```yaml
# Add to codemagic.yaml before pod install
- name: Update CocoaPods
  script: |
    sudo gem install cocoapods
    pod repo update
```

### Issue 3: Build Failed - Flutter Analyze

**Error**: `flutter analyze found issues`

**Solution**:
```bash
# Fix trên local
flutter analyze
# Fix tất cả issues
# Commit và push lại
```

### Issue 4: TestFlight Processing Stuck

**Issue**: Build uploaded nhưng processing lâu (>1 giờ)

**Solution**:
- Đợi thêm, thường do Apple server busy
- Nếu >2 giờ vẫn stuck, upload build mới

### Issue 5: App Review Rejected

**Common reasons**:
1. **Missing functionality**: Demo account không work
2. **Privacy policy**: Thiếu hoặc không đầy đủ
3. **Crashes**: App bị crash khi review
4. **Guideline violation**: Vi phạm App Store guidelines

**Solution**:
- Đọc kỹ rejection reason
- Fix issues
- Add notes cho reviewer
- Resubmit

---

## 📊 Build Monitoring

### Check Build Logs

```bash
# View real-time logs
# Trên Codemagic Dashboard → Build → Logs
```

### Key logs to watch:

```
✅ GET FLUTTER PACKAGES - Success
✅ INSTALL PODS - Success
✅ FLUTTER ANALYZE - No issues found
✅ FLUTTER BUILD IPA - Built successfully
✅ CODE SIGNING - Signed successfully
✅ UPLOAD TO APP STORE - Upload complete
```

---

## 🔧 Update codemagic.yaml

File đã được update với:

✅ Environment variables cho Supabase
✅ Environment variables cho Google Drive
✅ iOS workflow hoàn chỉnh
✅ Auto upload to TestFlight
✅ Email notifications

**Current workflow:**
- Build automatically khi push lên master
- Upload to TestFlight automatically
- Send email notification on success/failure

**To submit to App Store (production):**

Uncomment dòng này trong `codemagic.yaml`:

```yaml
publishing:
  app_store_connect:
    submit_to_testflight: true
    # submit_to_app_store: true  # <-- Uncomment dòng này
```

---

## 📝 Next Steps

### Immediate (Bây giờ):

1. [ ] Đăng ký Apple Developer Account ($99/năm)
2. [ ] Tạo app trên App Store Connect
3. [ ] Tạo App Store Connect API Key
4. [ ] Setup Codemagic account
5. [ ] Add environment variables to Codemagic

### Soon (Sắp tới):

6. [ ] Push code to GitHub
7. [ ] Trigger first build trên Codemagic
8. [ ] Test trên TestFlight
9. [ ] Prepare App Store listing (screenshots, description)
10. [ ] Submit for App Store review

### Later (Sau này):

11. [ ] Monitor crash reports
12. [ ] Collect user feedback
13. [ ] Plan updates và new features
14. [ ] Setup analytics (Firebase, Mixpanel)

---

## 💰 Chi phí

| Item | Cost | Frequency |
|------|------|-----------|
| Apple Developer Program | $99 | /năm |
| Codemagic Free Tier | $0 | Free (500 build minutes/month) |
| Codemagic Pro (if needed) | $39+ | /tháng |
| Total (Year 1) | ~$99-500 | - |

**Note**: Codemagic Free tier đủ cho ~10-15 builds/tháng

---

## 📞 Support

- **Codemagic Docs**: https://docs.codemagic.io/flutter/
- **App Store Connect**: https://developer.apple.com/support/
- **Flutter Docs**: https://docs.flutter.dev/deployment/ios

---

## ✅ Quick Checklist

Trước khi deploy lần đầu:

- [ ] Apple Developer Account active
- [ ] App created trên App Store Connect
- [ ] API Key created và lưu lại
- [ ] Codemagic account setup
- [ ] Environment variables added
- [ ] iOS code signing configured
- [ ] codemagic.yaml updated
- [ ] Code pushed to GitHub

Bắt đầu deploy:

- [ ] Trigger build trên Codemagic
- [ ] Wait for build to complete (~20 min)
- [ ] Check TestFlight for new build
- [ ] Test app trên TestFlight
- [ ] Submit to App Store
- [ ] Wait for review (~1-3 days)
- [ ] 🎉 App goes live!

---

**Good luck! 🚀**

Tạo bởi: AI Assistant
Ngày: 04/11/2025
Version: 1.0.0
