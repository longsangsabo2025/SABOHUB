# 🚀 CodeMagic Deployment Guide - SABOHUB

## 📋 Overview

Hướng dẫn chi tiết để deploy ứng dụng SABOHUB lên App Store và Google Play sử dụng CodeMagic CI/CD.

## 🎯 Prerequisites

### 1. **CodeMagic Account**
- Đăng ký tài khoản tại [codemagic.io](https://codemagic.io)
- Connect với repository GitHub của bạn

### 2. **Apple Developer Account**
- Account type: **Individual** hoặc **Organization**
- Đã thanh toán phí hàng năm ($99/year)
- Access: [developer.apple.com](https://developer.apple.com)

### 3. **Google Play Console Account**
- Đã thanh toán phí một lần ($25)
- Access: [play.google.com/console](https://play.google.com/console)

---

## 🍎 iOS Setup (App Store)

### Step 1: Tạo App Store Connect API Key

1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. Vào **Users and Access** → **Keys** tab
3. Click **Generate API Key** hoặc dấu **+**
4. Điền thông tin:
   - **Name**: CodeMagic
   - **Access**: **App Manager** (recommended) hoặc **Admin**
5. Click **Generate**
6. **Download** API Key file (`.p8`) - CHỈ TẢI ĐƯỢC 1 LẦN!
7. Ghi lại:
   - **Issuer ID** (ở phía trên trang)
   - **Key ID** (cột bên trái của key vừa tạo)

### Step 2: Tạo App ID & Provisioning Profile

#### Option A: Tự động qua CodeMagic (Recommended)
CodeMagic sẽ tự động tạo khi bạn setup iOS code signing.

#### Option B: Thủ công (Manual)
1. Truy cập [Apple Developer Portal](https://developer.apple.com/account)
2. **Identifiers** → Click **+**
3. Chọn **App IDs** → **Continue**
4. Chọn **App** → **Continue**
5. Điền thông tin:
   - **Description**: SABOHUB
   - **Bundle ID**: `com.sabohub.app`
   - **Capabilities**: Chọn các capabilities cần thiết (Push Notifications, In-App Purchase, etc.)
6. Click **Continue** → **Register**

### Step 3: Tạo App trên App Store Connect

1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Điền thông tin:
   - **Platforms**: iOS
   - **Name**: SABOHUB - Quản lý quán bida
   - **Primary Language**: Vietnamese
   - **Bundle ID**: Chọn `com.sabohub.app`
   - **SKU**: `sabohub-001` (mã định danh nội bộ)
   - **User Access**: Full Access
4. Click **Create**

### Step 4: Cấu hình CodeMagic cho iOS

1. Đăng nhập [CodeMagic](https://codemagic.io)
2. Chọn repository **rork-sabohub-255**
3. Click **Start new build** → **Set up build configuration**
4. Chọn **Flutter App**
5. Vào **Environment variables**:

#### Add App Store Connect Integration:
- Vào **Integrations** → **App Store Connect**
- Click **Add key**
- Upload file `.p8` đã tải ở Step 1
- Nhập:
  - **Issuer ID**
  - **Key ID**
- Save as group: **app_store**

#### Add Environment Variables:
```yaml
SUPABASE_URL: https://your-project.supabase.co
SUPABASE_ANON_KEY: your-anon-key-here
BUNDLE_ID: com.sabohub.app
APP_NAME: SABOHUB
```

6. **iOS Code Signing**:
   - Chọn **Automatic** (recommended)
   - Hoặc upload manual certificates & provisioning profiles

### Step 5: Cập nhật Bundle Identifier

Sửa file `ios/Runner/Info.plist`:
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

Sửa file `ios/Runner.xcodeproj/project.pbxproj` (hoặc qua Xcode):
```
PRODUCT_BUNDLE_IDENTIFIER = com.sabohub.app;
```

### Step 6: Build & Deploy

1. Commit và push code lên GitHub
2. CodeMagic sẽ tự động trigger build
3. Hoặc click **Start new build** manually trên CodeMagic
4. Chọn workflow: **ios-workflow**
5. Click **Start new build**

Build sẽ:
- ✅ Run tests
- ✅ Build IPA file
- ✅ Upload lên TestFlight tự động
- ✅ Gửi email thông báo

### Step 7: TestFlight Testing

1. Truy cập [App Store Connect](https://appstoreconnect.apple.com)
2. Chọn app **SABOHUB**
3. Vào tab **TestFlight**
4. Thêm **Internal Testers** hoặc **External Testers**
5. Testers sẽ nhận được email invite
6. Download **TestFlight** app và test

### Step 8: Submit to App Store

1. Sau khi test OK trên TestFlight
2. Vào tab **App Store** trong App Store Connect
3. Click **+** → **New Version**
4. Điền đầy đủ thông tin:
   - Screenshots (iPhone 6.7", 6.5", 5.5")
   - Description
   - Keywords
   - Support URL
   - Privacy Policy URL
   - Category: Business
5. Chọn build từ TestFlight
6. Click **Submit for Review**

---

## 🤖 Android Setup (Google Play)

### Step 1: Tạo Keystore

Tạo keystore file để sign APK/AAB:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Điền thông tin khi được hỏi và **GHI NHỚ**:
- **Keystore password**
- **Key password**
- **Alias**: upload

### Step 2: Cấu hình Android Signing

Tạo file `android/key.properties` (LOCAL ONLY - KHÔNG commit):
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Cập nhật `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 3: Tạo App trên Google Play Console

1. Truy cập [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Điền thông tin:
   - **App name**: SABOHUB - Quản lý quán bida
   - **Default language**: Vietnamese
   - **App or game**: App
   - **Free or paid**: Free
4. Agree terms → **Create app**

### Step 4: Setup Google Play Console

#### 4.1. App Content
- **Privacy policy URL**: (bắt buộc)
- **App access**: Chọn loại access
- **Ads**: App có quảng cáo không?
- **Content rating**: Điền questionnaire
- **Target audience**: Chọn độ tuổi
- **News app**: No (nếu không phải)

#### 4.2. Store Listing
- **App name**: SABOHUB - Quản lý quán bida
- **Short description**: Mô tả ngắn (max 80 chars)
- **Full description**: Mô tả đầy đủ (max 4000 chars)
- **App icon**: 512x512 PNG
- **Feature graphic**: 1024x500 JPG/PNG
- **Screenshots**: Ít nhất 2 ảnh (Phone, Tablet nếu support)
- **Category**: Business
- **Contact details**: Email, website, phone

### Step 5: Tạo Service Account cho API Access

1. Truy cập [Google Cloud Console](https://console.cloud.google.com)
2. Chọn project của Google Play Console
3. **IAM & Admin** → **Service Accounts**
4. Click **Create Service Account**
5. Điền thông tin:
   - **Name**: CodeMagic
   - **Description**: Service account for CodeMagic CI/CD
6. Click **Create and Continue**
7. Grant role: **Service Account User**
8. Click **Done**
9. Click vào service account vừa tạo
10. Vào tab **Keys** → **Add Key** → **Create new key**
11. Chọn **JSON** → **Create**
12. Download file JSON (QUAN TRỌNG!)

### Step 6: Grant Permissions

1. Quay lại [Google Play Console](https://play.google.com/console)
2. **Users and permissions** → **Invite new users**
3. Nhập **Service Account Email** (từ step 5)
4. Chọn **App permissions** → chọn app của bạn
5. Grant permissions:
   - ✅ View app information
   - ✅ Manage store presence
   - ✅ Manage production releases
   - ✅ Manage testing track releases
6. Click **Invite user** → **Send invitation**

### Step 7: Cấu hình CodeMagic cho Android

1. Vào CodeMagic → chọn app
2. **Environment variables**:

#### Upload Keystore:
- Vào **Code signing identities**
- **Android** section
- Upload `upload-keystore.jks`
- Nhập:
  - **Keystore password**
  - **Key alias**: upload
  - **Key password**

#### Add Google Play Integration:
- Vào **Integrations** → **Google Play**
- Upload file **JSON** từ Step 5
- Save as group: **google_play**

#### Add Environment Variables:
```yaml
SUPABASE_URL: https://your-project.supabase.co
SUPABASE_ANON_KEY: your-anon-key-here
PACKAGE_NAME: com.sabohub.app
```

### Step 8: Cập nhật Package Name

Sửa `android/app/build.gradle`:
```gradle
android {
    namespace = "com.sabohub.app"
    defaultConfig {
        applicationId = "com.sabohub.app"
        ...
    }
}
```

Sửa `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.sabohub.app">
```

### Step 9: Build & Deploy

1. Commit và push code
2. CodeMagic trigger build tự động
3. Hoặc manual: Click **Start new build**
4. Chọn workflow: **android-workflow**
5. Click **Start new build**

Build sẽ:
- ✅ Run tests
- ✅ Build AAB (Android App Bundle)
- ✅ Upload lên Google Play Internal Testing
- ✅ Gửi email thông báo

### Step 10: Internal Testing

1. Truy cập Google Play Console
2. Vào app → **Testing** → **Internal testing**
3. **Create new release** (nếu chưa có)
4. Add testers:
   - Create email list
   - Add tester emails
5. Testers nhận được email với link cài đặt
6. Test app

### Step 11: Submit to Production

Sau khi test OK:

1. Vào **Production** → **Create new release**
2. Chọn AAB file từ Internal Testing
3. Điền **Release notes** (Vietnamese & English)
4. Review & **Roll out to Production**
5. Hoặc:
   - **Closed testing** (alpha/beta)
   - **Open testing** (public beta)

---

## 🔧 Cấu hình CI/CD Nâng cao

### Auto-increment Build Number

CodeMagic tự động tăng build number với biến `$BUILD_NUMBER`.

### Versioning Strategy

Format: **MAJOR.MINOR.PATCH+BUILD_NUMBER**

Example:
- **1.0.0+1** - First release
- **1.0.1+2** - Bug fix
- **1.1.0+3** - New features
- **2.0.0+4** - Breaking changes

### Environment-specific Builds

Tạo multiple workflows cho môi trường khác nhau:

```yaml
workflows:
  ios-dev:
    name: iOS Development
    environment:
      vars:
        SUPABASE_URL: $SUPABASE_DEV_URL
        
  ios-staging:
    name: iOS Staging
    environment:
      vars:
        SUPABASE_URL: $SUPABASE_STAGING_URL
        
  ios-production:
    name: iOS Production
    environment:
      vars:
        SUPABASE_URL: $SUPABASE_PROD_URL
```

### Slack/Discord Notifications

Thêm vào `codemagic.yaml`:

```yaml
publishing:
  slack:
    channel: '#builds'
    notify_on_build_start: true
    notify:
      success: true
      failure: true
```

---

## 📱 App Store Guidelines

### iOS App Store Review Guidelines

#### ✅ Phải có:
- Privacy Policy (URL)
- Terms of Service (nếu có accounts)
- Support URL/Email
- App demo account (nếu cần login)
- Complete app information
- High-quality screenshots
- App description rõ ràng

#### ❌ Không được:
- Mention Android hoặc platforms khác
- Placeholder content
- Bugs hoặc crashes
- Missing functionality
- Misleading information

### Android Google Play Guidelines

#### ✅ Phải có:
- Privacy Policy (URL)
- Target API level 33+ (Android 13)
- 64-bit support
- App icon, feature graphic
- Screenshots (min 2)
- Complete store listing

#### ❌ Không được:
- Malware/viruses
- Copyright infringement
- Misleading content
- Inappropriate content

---

## 🛠 Troubleshooting

### iOS Build Issues

#### Error: "No valid code signing certificates"
**Solution**:
- Check App Store Connect API key is correct
- Verify Bundle ID matches exactly
- Try "Automatic" code signing in CodeMagic

#### Error: "Could not find or use auto-linked library"
**Solution**:
```bash
cd ios
pod install
pod update
```

#### Error: "Export compliance missing"
**Solution**:
Add to `ios/Runner/Info.plist`:
```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Android Build Issues

#### Error: "Keystore was tampered with"
**Solution**:
- Verify keystore password is correct
- Re-upload keystore to CodeMagic
- Check key.properties format

#### Error: "Package name already exists"
**Solution**:
- Change package name in build.gradle
- Update AndroidManifest.xml
- Create new app in Google Play Console

#### Error: "Unsupported class file version"
**Solution**:
Update `android/app/build.gradle`:
```gradle
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

---

## 📊 Monitoring & Analytics

### Recommended Tools

1. **Firebase Crashlytics** - Crash reporting
2. **Firebase Analytics** - User analytics
3. **Sentry** - Error tracking
4. **Mixpanel** - Advanced analytics

### Setup Firebase

1. Add Firebase to your Flutter app
2. Add dependencies:
```yaml
dependencies:
  firebase_core: ^2.x.x
  firebase_analytics: ^10.x.x
  firebase_crashlytics: ^3.x.x
```

3. Add to CodeMagic environment variables:
```yaml
FIREBASE_OPTIONS: $FIREBASE_OPTIONS_JSON
```

---

## 🎉 Success Checklist

### Pre-launch
- [ ] All features work correctly
- [ ] No crashes or major bugs
- [ ] Tested on multiple devices
- [ ] Privacy policy published
- [ ] Terms of service ready
- [ ] Support email/website ready
- [ ] App icons & screenshots ready
- [ ] App descriptions written

### CodeMagic Setup
- [ ] Repository connected
- [ ] iOS workflow configured
- [ ] Android workflow configured
- [ ] Environment variables set
- [ ] Code signing configured
- [ ] Test builds successful

### iOS Launch
- [ ] App Store Connect app created
- [ ] Bundle ID registered
- [ ] TestFlight build uploaded
- [ ] Internal testing completed
- [ ] Store listing completed
- [ ] Submitted for review
- [ ] App approved
- [ ] Released to App Store

### Android Launch
- [ ] Google Play Console app created
- [ ] Service account created
- [ ] Internal testing completed
- [ ] Store listing completed
- [ ] Production release created
- [ ] App published

---

## 📞 Support

- **CodeMagic Docs**: https://docs.codemagic.io/
- **Flutter Docs**: https://docs.flutter.dev/
- **App Store Connect**: https://developer.apple.com/support/
- **Google Play Console**: https://support.google.com/googleplay/

---

## 🚀 Next Steps

Sau khi app đã live:

1. **Monitor performance** - Crashes, ANRs, loading times
2. **Collect feedback** - User reviews, support tickets
3. **Plan updates** - Bug fixes, new features
4. **Marketing** - App Store Optimization (ASO)
5. **Iterate** - Continuous improvement

**Chúc bạn deployment thành công! 🎉**
