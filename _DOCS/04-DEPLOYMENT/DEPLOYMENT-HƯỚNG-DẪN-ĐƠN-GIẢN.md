# 🚀 HƯỚNG DẪN DEPLOY SABOHUB - ĐƠN GIẢN NHẤT

## ✅ **ĐÃ XONG - Không cần làm gì thêm!**

Tất cả environment variables đã được **cấu hình sẵn** trong `codemagic.yaml`:

- ✅ Supabase URL & Keys
- ✅ Google Drive Client IDs (iOS, Android, Web)
- ✅ Bundle ID & Package Name

---

## 📋 **DEPLOYMENT CHECKLIST**

### 🍎 **iOS (App Store)**

#### Bước 1: Đăng ký Apple Developer (Bắt buộc)
```
💰 Giá: $99/năm
🔗 Link: https://developer.apple.com/programs/
```

**Làm gì:**
1. Truy cập link trên
2. Đăng ký với Apple ID
3. Thanh toán $99
4. Đợi ~24-48h để được approve

#### Bước 2: Tạo App trên App Store Connect
```
🔗 Link: https://appstoreconnect.apple.com
```

**Làm gì:**
1. Login vào App Store Connect
2. Click **"My Apps"** → **"+"** → **"New App"**
3. Điền thông tin:
   - **Platform**: iOS
   - **Name**: SABOHUB
   - **Primary Language**: Vietnamese
   - **Bundle ID**: Chọn `com.sabohub.app` (phải tạo trước trên developer.apple.com)
   - **SKU**: sabohub-app-001 (bất kỳ)

#### Bước 3: Tạo App Store Connect API Key
```
🔗 Link: https://appstoreconnect.apple.com/access/api
```

**Làm gì:**
1. Click **"Keys"** tab → **"+"** (Generate API Key)
2. Điền:
   - **Name**: Codemagic Deploy
   - **Access**: App Manager
3. Click **"Generate"**
4. **QUAN TRỌNG**: Download file `.p8` NGAY (chỉ download được 1 lần!)
5. Lưu lại 3 thông tin:
   - **Issuer ID**: Ở phía trên (dạng `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
   - **Key ID**: Bên cạnh tên key (dạng `XXXXXXXXXX`)
   - **Private Key**: Nội dung file `.p8` (mở bằng Notepad)

#### Bước 4: Setup Codemagic (5 phút)

**4.1. Đăng ký Codemagic:**
```
🔗 Link: https://codemagic.io/signup
```
- Sign up bằng GitHub account
- Connect repository: `longsangsabo2025/SABOHUB`

**4.2. Setup iOS Code Signing:**
1. Vào **Applications** → SABOHUB → **Settings** → **Distribution**
2. Tab **iOS code signing** → **Enable**
3. Chọn **Automatic code signing** (đơn giản nhất!)
4. Click **Connect Apple Developer Portal**
5. Login bằng Apple ID của bạn
6. Codemagic sẽ tự động tạo certificates

**4.3. Setup App Store Connect API (Để tự động upload):**
1. Vào **Team settings** → **Integrations** → **App Store Connect**
2. Click **Add key**
3. Điền thông tin từ Bước 3:
   - **Issuer ID**: Paste issuer ID
   - **Key ID**: Paste key ID
   - **Private key**: Paste toàn bộ nội dung file `.p8` (bao gồm `-----BEGIN PRIVATE KEY-----` và `-----END PRIVATE KEY-----`)
4. Click **Save**

**4.4. Add vào Environment Group:**
1. Vào **Team settings** → **Environment variables**
2. Tạo group tên **"app_store"** (nếu chưa có)
3. Thêm 3 variables vào group:
   ```
   APP_STORE_CONNECT_ISSUER_ID = <issuer-id>
   APP_STORE_CONNECT_KEY_IDENTIFIER = <key-id>
   APP_STORE_CONNECT_PRIVATE_KEY = <toàn-bộ-nội-dung-.p8>
   ```
4. Check ☑️ **Secure** cho cả 3 biến

#### Bước 5: Deploy! 🚀

```bash
# Commit và push code
git add .
git commit -m "chore: ready for iOS deployment"
git push origin master
```

**Trên Codemagic:**
1. Vào **Applications** → SABOHUB
2. Click **Start new build**
3. Chọn workflow: **ios-workflow**
4. Chọn branch: **master**
5. Click **Start new build**

**Đợi ~20-30 phút:**
- ✅ Build sẽ chạy
- ✅ Upload lên TestFlight tự động
- ✅ Nhận email thông báo thành công

**Test trên TestFlight:**
1. Vào App Store Connect → TestFlight
2. Build sẽ ở trạng thái "Processing" (~10-20 phút)
3. Sau khi xong, add internal testers
4. Test app trên iPhone thật

**Submit lên App Store:**
1. Sau khi test OK, vào `codemagic.yaml`
2. Đổi dòng 76: `submit_to_app_store: false` → `submit_to_app_store: true`
3. Push code và trigger build mới
4. App sẽ tự động submit lên App Store để review

---

### 🤖 **Android (Google Play)**

#### Bước 1: Đăng ký Google Play Console (Bắt buộc)
```
💰 Giá: $25 (một lần duy nhất)
🔗 Link: https://play.google.com/console/signup
```

**Làm gì:**
1. Truy cập link
2. Đăng ký với Google account
3. Thanh toán $25
4. Đợi ~24-48h được approve

#### Bước 2: Tạo App trên Google Play Console
```
🔗 Link: https://play.google.com/console
```

**Làm gì:**
1. Login vào Google Play Console
2. Click **"Create app"**
3. Điền:
   - **App name**: SABOHUB
   - **Default language**: Vietnamese
   - **App or game**: App
   - **Free or paid**: Free
4. Check các policies boxes
5. Click **Create app**

#### Bước 3: Tạo Keystore (Android signing key)

**Chạy lệnh này trong PowerShell:**
```powershell
keytool -genkey -v -keystore sabohub-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias sabohub
```

**Sẽ hỏi:**
- **Password**: Nhập password (ghi nhớ!)
- **Re-enter**: Nhập lại password
- **First and last name**: SABOHUB
- **Organization**: Công ty của bạn
- **City**: Thành phố
- **State**: Tỉnh
- **Country code**: VN

**⚠️ QUAN TRỌNG:**
- File `sabohub-release.jks` được tạo ra
- **BACKUP file này cẩn thận** (mất file = mất app!)
- Lưu password vào chỗ an toàn

#### Bước 4: Setup Google Play API Access

**4.1. Tạo Service Account:**
1. Vào Google Play Console → **Setup** → **API access**
2. Click **Create new service account**
3. Click link **Google Cloud Platform**
4. Trong GCP Console:
   - Click **+ CREATE SERVICE ACCOUNT**
   - **Name**: Codemagic Deploy
   - **ID**: codemagic-deploy
   - Click **Create and Continue**
   - **Role**: Chọn **Service Account User**
   - Click **Done**
5. Sau khi tạo xong, click vào service account vừa tạo
6. Tab **KEYS** → **ADD KEY** → **Create new key**
7. **Key type**: JSON
8. Click **CREATE**
9. File JSON sẽ tự động download

**4.2. Grant Permissions:**
1. Quay lại Google Play Console → API access
2. Tìm service account vừa tạo
3. Click **Grant access**
4. Chọn permissions:
   - **Releases**: View, Create and edit releases
   - **App access**: View app information
5. Click **Invite user** → **Send invitation**

#### Bước 5: Upload Keystore lên Codemagic

1. Vào Codemagic → SABOHUB → **Settings** → **Distribution**
2. Tab **Android code signing**
3. Click **Upload keystore file** → chọn file `sabohub-release.jks`
4. Điền:
   - **Keystore password**: Password bạn đã tạo
   - **Key alias**: sabohub
   - **Key password**: Same as keystore password
5. Click **Save**

#### Bước 6: Add Service Account JSON vào Codemagic

1. Mở file JSON vừa download bằng Notepad
2. Copy toàn bộ nội dung (từ `{` đến `}`)
3. Vào Codemagic → **Team settings** → **Environment variables**
4. Tạo group **"google_play"** (nếu chưa có)
5. Add variable:
   - **Name**: `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`
   - **Value**: Paste toàn bộ nội dung JSON
   - Check ☑️ **Secure**
6. Click **Add**

**⚠️ Note về keystore:** Codemagic cũng cần biết path của keystore. Thêm các biến sau vào group `google_play`:
```
CM_KEYSTORE_PATH = /tmp/keystore.jks (Codemagic tự động assign path này khi upload)
CM_KEYSTORE_PASSWORD = <password-của-bạn>
CM_KEY_ALIAS = sabohub
CM_KEY_PASSWORD = <password-của-bạn>
```

#### Bước 7: Deploy! 🚀

```bash
# Commit và push code
git add .
git commit -m "chore: ready for Android deployment"
git push origin master
```

**Trên Codemagic:**
1. Vào **Applications** → SABOHUB
2. Click **Start new build**
3. Chọn workflow: **android-workflow**
4. Chọn branch: **master**
5. Click **Start new build**

**Đợi ~15-20 phút:**
- ✅ Build sẽ chạy
- ✅ Upload lên Internal testing track
- ✅ Nhận email thông báo

**Test trên Google Play:**
1. Vào Google Play Console → Testing → Internal testing
2. Add internal testers (email addresses)
3. Testers sẽ nhận email invite
4. Test app trên Android device

**Promote to Production:**
1. Sau khi test OK
2. Internal testing → **Promote to production** (hoặc Closed/Open testing trước)
3. Submit for review (~3-7 days)

---

## 🎯 **TÓM TẮT NHANH**

### iOS Steps:
1. ✅ Values đã có sẵn trong `codemagic.yaml`
2. ⏳ Đăng ký Apple Developer ($99)
3. ⏳ Tạo app trên App Store Connect
4. ⏳ Tạo API Key
5. ⏳ Setup Codemagic (code signing + API key)
6. 🚀 Push code → Trigger build → TestFlight → App Store

### Android Steps:
1. ✅ Values đã có sẵn trong `codemagic.yaml`
2. ⏳ Đăng ký Google Play Console ($25)
3. ⏳ Tạo app
4. ⏳ Create keystore
5. ⏳ Setup service account
6. ⏳ Upload keystore + JSON vào Codemagic
7. 🚀 Push code → Trigger build → Internal testing → Production

---

## ⚠️ **CHÚ Ý QUAN TRỌNG**

### File `.env` và Security:
- ✅ File `.env` đã có trong `.gitignore` (không push lên Git)
- ✅ Values đã hardcode trong `codemagic.yaml` nên Codemagic đọc được
- ⚠️ **Repository phải là PRIVATE** trên GitHub (đã private rồi)
- ⚠️ Không share `codemagic.yaml` công khai vì có credentials

### Keystore (Android):
- 🔴 **BACKUP file .jks ngay!** Mất file = không thể update app!
- 🔴 Lưu password ở nơi an toàn
- 🔴 Không commit keystore vào Git

### App Store Connect API Key (iOS):
- 🔴 File `.p8` chỉ download được 1 lần!
- 🔴 Backup file này cẩn thận

---

## 🆘 **TROUBLESHOOTING**

### iOS build failed:
```
❌ "No code signing identities found"
→ Giải pháp: Setup Automatic code signing trong Codemagic, connect Apple account lại
```

```
❌ "Invalid Bundle ID"
→ Giải pháp: Tạo Bundle ID `com.sabohub.app` trên developer.apple.com trước
```

### Android build failed:
```
❌ "Keystore not found"
→ Giải pháp: Upload lại keystore file trong Codemagic Settings
```

```
❌ "Invalid keystore password"
→ Giải pháp: Check lại password trong Environment variables
```

### Build thành công nhưng không upload:
```
iOS: Check API Key có đúng permissions không (App Manager role)
Android: Check service account có permissions "Release Manager" không
```

---

## ✅ **READY TO GO!**

Bây giờ bạn chỉ cần:
1. Đăng ký accounts (Apple + Google)
2. Setup API keys & signing
3. Push code
4. Click "Start new build"

**Done! 🎉**
