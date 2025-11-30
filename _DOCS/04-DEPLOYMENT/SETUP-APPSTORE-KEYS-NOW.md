# 🚀 HƯỚNG DẪN NHANH - SETUP APP STORE CONNECT API

## ✅ ĐÃ HOÀN THÀNH

- [x] ✅ Certificate uploaded (`ios_distribution_sabohub`)
- [x] ✅ Provisioning profile uploaded (`sabohub_appstore_profile`)
- [x] ✅ API Key file (.p8) đã lưu local: `AuthKey_JL9L6RNRXB.p8`
- [x] ✅ Key ID: `JL9L6RNRXB`

## ⚠️ CẦN LÀM NGAY

### Bước 1: Lấy Issuer ID

1. Đăng nhập: https://appstoreconnect.apple.com/access/api
2. **Issuer ID** nằm ở **phía trên trang** (dạng: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
3. **Copy Issuer ID** này

### Bước 2: Thêm Environment Variables vào CodeMagic

1. Vào **CodeMagic** → **Teams** → **Personal account**
2. Click vào **Integrations** hoặc **Team settings**
3. Tìm phần **"Environment variables"**
4. Tạo/Edit group: **"app_store"**
5. Thêm 3 variables sau:

#### ✅ Variable 1: Issuer ID

```
Name: APP_STORE_CONNECT_ISSUER_ID
Value: [Paste Issuer ID từ bước 1]
Group: app_store
Secure: ✅ (check vào ô này)
```

#### ✅ Variable 2: Key ID

```
Name: APP_STORE_CONNECT_KEY_IDENTIFIER
Value: JL9L6RNRXB
Group: app_store
Secure: ✅ (check vào ô này)
```

#### ✅ Variable 3: Private Key

```
Name: APP_STORE_CONNECT_PRIVATE_KEY
Value: [Copy toàn bộ nội dung file AuthKey_JL9L6RNRXB.p8, 
       bao gồm dòng -----BEGIN PRIVATE KEY----- 
       và -----END PRIVATE KEY-----]
Group: app_store
Secure: ✅ (check vào ô này)
```

**Nội dung Private Key cần paste:**
```
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgODcxzeojG2ZCyrp5
IUQYz9Hmt1j1SP+ir+/7F4Xyf2+gCgYIKoZIzj0DAQehRANCAATvHGwxR+IIQMjz
grkecL92Sc33Hu7CmCHNEWS/G/eUKtYL03bpH4dZ/HdBNGnovyRKI3GvTzHGC461
gsx6uVPf
-----END PRIVATE KEY-----
```

### Bước 3: Lưu và Test

1. Click **"Save"** sau khi thêm cả 3 variables
2. Quay lại project **SABOHUB**
3. Click **"Start new build"** để test

---

## 🎯 CHECKLIST CUỐI CÙNG

Trước khi build, đảm bảo:

- [ ] Đã có Issuer ID từ App Store Connect
- [ ] Đã thêm cả 3 environment variables vào group "app_store"
- [ ] Đã check "Secure" cho cả 3 variables
- [ ] Group name chính xác là "app_store" (không viết hoa, không dấu cách)
- [ ] Certificate `ios_distribution_sabohub` đang active
- [ ] Provisioning profile `sabohub_appstore_profile` đang active

---

## 📱 SAU KHI BUILD THÀNH CÔNG

Build sẽ tự động:
1. ✅ Build ipa file
2. ✅ Upload lên App Store Connect
3. ✅ Submit to TestFlight
4. ✅ Gửi email thông báo

Bạn có thể test app ngay trên TestFlight!

---

## 🆘 NẾU GẶP LỖI

### Lỗi: "No signing certificate"
→ Kiểm tra certificate đã upload và đang active

### Lỗi: "Invalid API key"
→ Kiểm tra lại 3 environment variables, đặc biệt là Issuer ID

### Lỗi: "Provisioning profile not found"
→ Kiểm tra Bundle ID trong profile khớp với `com.sabohub.app`

---

## 📚 File tham khảo

- `APP_STORE_CONNECT_CREDENTIALS.md` - Chi tiết đầy đủ về credentials
- `AuthKey_JL9L6RNRXB.p8` - Private key file (đã được gitignore)
- `codemagic.yaml` - Cấu hình workflow

---

**Chúc may mắn! 🚀**
