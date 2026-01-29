# 🚀 SABOHUB - Hướng Dẫn Deploy Lên Google Play

> **Tham khảo từ**: SABO Arena deployment workflow
> **Cập nhật**: 30/01/2026

---

## 📋 Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Chuẩn Bị](#chuẩn-bị)
3. [Build Local (Nhanh Nhất)](#build-local-nhanh-nhất)
4. [Deploy lên Internal Testing](#deploy-lên-internal-testing)
5. [Codemagic CI/CD (Tự Động)](#codemagic-cicd-tự-động)
6. [Troubleshooting](#troubleshooting)

---

## 📱 Tổng Quan

### Các phương án deploy cho nội bộ:

| Phương án | Thời gian | Độ khó | Phù hợp |
|-----------|-----------|--------|---------|
| **APK trực tiếp** | 5 phút | ⭐ | Test nhanh, ít người |
| **Firebase App Distribution** | 15 phút | ⭐⭐ | Nhóm nhỏ, cập nhật thường xuyên |
| **Google Play Internal Testing** | 30 phút | ⭐⭐⭐ | Nội bộ công ty, chuyên nghiệp |
| **Codemagic CI/CD** | 1 lần setup | ⭐⭐⭐⭐ | Tự động hóa hoàn toàn |

**Khuyến nghị**: Bắt đầu với **APK trực tiếp** để test nhanh, sau đó setup **Internal Testing** cho nội bộ.

---

## 🔧 Chuẩn Bị

### 1. Kiểm tra Keystore (Đã có sẵn ✅)

```
android/app/sabohub-release-key.keystore
android/key.properties
```

### 2. Kiểm tra môi trường

```powershell
# Verify Flutter
flutter doctor -v

# Check version hiện tại
Get-Content pubspec.yaml | Select-String "version:"
```

### 3. Cấu hình đã được cập nhật:

- ✅ `AndroidManifest.xml` - Permissions & app label
- ✅ `build.gradle` - Signing config, minSdk 23
- ✅ `proguard-rules.pro` - Obfuscation rules
- ✅ `key.properties` - Release signing credentials

---

## ⚡ Build Local (Nhanh Nhất)

### Option A: Sử dụng Script (Khuyến nghị)

```powershell
# Build APK (cho test trực tiếp)
cd D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB
.\scripts\build_android_release.ps1 -Apk

# Build AAB (cho Google Play)
.\scripts\build_android_release.ps1
```

### Option B: Build thủ công

```powershell
cd D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB

# Clean & get dependencies
flutter clean
flutter pub get

# Build APK (split by CPU architecture)
flutter build apk --release --split-per-abi

# HOẶC Build App Bundle cho Google Play
flutter build appbundle --release
```

### Output files:

- **APK**: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~20-30MB)
- **AAB**: `build/app/outputs/bundle/release/app-release.aab` (~15-20MB)

---

## 📲 Deploy lên Internal Testing

### Bước 1: Tạo Google Play Developer Account

> Nếu chưa có, đăng ký tại: https://play.google.com/console
> Phí: $25 (một lần)

### Bước 2: Tạo App mới

1. Vào **Google Play Console** → **Create app**
2. Điền thông tin:
   - **App name**: SABOHUB
   - **Default language**: Vietnamese
   - **App or game**: App
   - **Free or paid**: Free

### Bước 3: Hoàn thành Store Listing (Tối thiểu)

```
📁 Cần chuẩn bị:
├── App icon: 512x512 PNG
├── Feature graphic: 1024x500 PNG
├── Screenshots: 2-8 ảnh (điện thoại)
├── Short description: < 80 ký tự
└── Full description: Mô tả app
```

**Short description gợi ý:**
```
Quản lý quán bida chuyên nghiệp - Theo dõi nhân viên, đơn hàng, GPS
```

### Bước 4: Setup Internal Testing

1. Vào **Testing** → **Internal testing**
2. Click **Create new release**
3. Upload file AAB
4. Add **Release notes** (changelog)
5. Click **Review and rollout**

### Bước 5: Thêm Testers

1. Vào **Internal testing** → **Testers**
2. Create email list hoặc thêm từng email
3. Gửi link cho team:
   ```
   https://play.google.com/apps/internaltest/...
   ```

---

## 🤖 Codemagic CI/CD (Tự Động)

### Đã cấu hình sẵn trong `codemagic.yaml`

### Setup Google Play API:

1. **Tạo Service Account**:
   - Vào **Google Cloud Console** → IAM
   - Tạo Service Account với role "Service Account User"
   - Download JSON key

2. **Link với Google Play**:
   - **Play Console** → **Settings** → **API access**
   - Link Google Cloud project
   - Grant "Release to production" permission

3. **Add credentials to Codemagic**:
   - **Codemagic** → **Teams** → **Global variables**
   - Tạo group `google_play`
   - Add `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (paste JSON content)

### Trigger build tự động:

```bash
# Push to main branch để trigger
git add .
git commit -m "Release v1.0.4"
git push origin main
```

---

## 🆘 Troubleshooting

### Lỗi: "Version code already exists"

```powershell
# Tăng version trong pubspec.yaml
# Ví dụ: version: 1.0.3+5 → version: 1.0.3+6
```

### Lỗi: "Keystore not found"

```powershell
# Kiểm tra key.properties
cat android\key.properties

# Đảm bảo đường dẫn đúng:
# storeFile=sabohub-release-key.keystore
```

### Lỗi: "minSdk too low"

```
# Đã fix trong build.gradle: minSdk = 23
```

### Lỗi: "Proguard issues"

Thêm vào `android/app/proguard-rules.pro`:
```
-keep class your.package.** { *; }
-dontwarn your.package.**
```

### Build quá chậm

```powershell
# Skip clean
.\scripts\build_android_release.ps1 -Apk -NoClean -SkipVersionBump
```

---

## 📊 So sánh với SABO Arena

| Tính năng | SABO Arena | SABOHUB |
|-----------|------------|---------|
| Application ID | com.saboarena.official | com.sabohub.app |
| Min SDK | 21 | 23 |
| Codemagic | ✅ iOS + Android | ✅ iOS + Android |
| Auto version bump | ✅ | ✅ |
| Internal testing | ✅ | ✅ (setup guide) |

---

## 📞 Quick Commands

```powershell
# === QUICK BUILD ===
cd D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB

# Build APK nhanh (test)
flutter build apk --release --target-platform android-arm64

# Build AAB (Google Play)  
flutter build appbundle --release

# === INSTALL TRỰC TIẾP ===
# Kết nối điện thoại qua USB, bật USB debugging
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# === CHECK VERSION ===
Get-Content pubspec.yaml | Select-String "version:"
```

---

**Tạo bởi**: GitHub Copilot  
**Tham khảo**: SABO Arena deployment workflow
