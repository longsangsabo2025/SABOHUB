# 🚀 Google Drive Integration Setup Guide

## Bước 1: Tạo Google Cloud Project

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Click **"Select a project"** → **"New Project"**
3. Nhập tên project: **"SABOHUB"**
4. Click **"Create"**

## Bước 2: Enable Google Drive API

1. Trong project vừa tạo, vào **"APIs & Services"** → **"Library"**
2. Tìm **"Google Drive API"**
3. Click vào và nhấn **"Enable"**

## Bước 3: Tạo OAuth 2.0 Credentials

### 3.1. Configure OAuth Consent Screen
1. Vào **"APIs & Services"** → **"OAuth consent screen"**
2. Chọn **"External"** → Click **"Create"**
3. Điền thông tin:
   - App name: **SABOHUB**
   - User support email: **your-email@gmail.com**
   - Developer contact: **your-email@gmail.com**
4. Click **"Save and Continue"**
5. Thêm Scopes:
   - Click **"Add or Remove Scopes"**
   - Tìm và chọn:
     - `https://www.googleapis.com/auth/drive.file`
     - `https://www.googleapis.com/auth/drive.appdata`
   - Click **"Update"** → **"Save and Continue"**
6. Add Test Users (để test):
   - Click **"Add Users"**
   - Nhập email của bạn
   - Click **"Save and Continue"**

### 3.2. Tạo OAuth Client ID

#### For Android:
1. Vào **"APIs & Services"** → **"Credentials"**
2. Click **"Create Credentials"** → **"OAuth client ID"**
3. Chọn **"Android"**
4. Package name: `com.sabohub.app` (hoặc package name trong android/app/build.gradle)
5. SHA-1: Lấy bằng lệnh:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Hoặc trên Windows:
   ```powershell
   cd android
   .\gradlew.bat signingReport
   ```
   Copy SHA-1 từ debug hoặc release
6. Click **"Create"**

#### For iOS:
1. Click **"Create Credentials"** → **"OAuth client ID"**
2. Chọn **"iOS"**
3. Bundle ID: `com.sabohub.app` (hoặc bundle ID trong ios/Runner.xcodeproj)
4. Click **"Create"**
5. Download file plist và lưu vào `ios/Runner/GoogleService-Info.plist`

#### For Web:
1. Click **"Create Credentials"** → **"OAuth client ID"**
2. Chọn **"Web application"**
3. Authorized JavaScript origins:
   - `http://localhost`
   - `http://localhost:3000`
4. Authorized redirect URIs:
   - `http://localhost`
5. Click **"Create"**
6. **LƯU LẠI CLIENT_ID** - sẽ cần dùng trong code

## Bước 4: Lưu Credentials

Tạo file `.env` trong root project với nội dung:

```env
GOOGLE_DRIVE_CLIENT_ID_WEB=your-web-client-id-here.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_ANDROID=your-android-client-id-here.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_IOS=your-ios-client-id-here.apps.googleusercontent.com
```

## ✅ Hoàn thành!

Sau khi làm xong các bước trên, quay lại VS Code và báo cho AI assistant biết để tiếp tục implement code!

## 📝 Notes

- **QUAN TRỌNG**: Không commit file `.env` lên Git
- Thêm `.env` vào `.gitignore`
- Để production, cần publish OAuth consent screen (chuyển từ Testing sang Production)
