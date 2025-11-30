# 📱 APP STORE DEPLOYMENT - READY TO GO

## ✅ Đã hoàn thành

### 1. **Codemagic Configuration** ✅
- ✅ File `codemagic.yaml` đã update
- ✅ iOS workflow configured
- ✅ Environment variables setup
- ✅ Auto upload to TestFlight
- ✅ Email notifications

### 2. **iOS Configuration** ✅
- ✅ Bundle ID: `com.sabohub.app`
- ✅ Display Name: `SABOHUB`
- ✅ Info.plist configured
- ✅ Export Compliance: Set to FALSE (no encryption)

### 3. **Documentation** ✅
- ✅ `APP-STORE-DEPLOYMENT-GUIDE.md` - Hướng dẫn chi tiết đầy đủ
- ✅ `GOOGLE-DRIVE-SETUP-GUIDE.md` - Setup Google Drive
- ✅ `GOOGLE-DRIVE-INTEGRATION-COMPLETE.md` - Tài liệu tính năng

---

## 🚀 Bước tiếp theo

### Bước 1: Apple Developer Account (BẮT BUỘC)

**Cost**: $99/năm

**Link**: https://developer.apple.com/programs/enroll/

**Steps**:
1. Đăng ký Apple Developer Program
2. Đợi approve (~24-48 giờ)
3. Login vào Apple Developer Portal

### Bước 2: Tạo App trên App Store Connect

**Link**: https://appstoreconnect.apple.com

**Steps**:
1. Click **"My Apps"** → **"+"** → **"New App"**
2. Điền thông tin:
   - **Platform**: iOS
   - **Name**: SABOHUB
   - **Primary Language**: Vietnamese
   - **Bundle ID**: `com.sabohub.app` (select from dropdown)
   - **SKU**: sabohub-001 (unique identifier)
   - **User Access**: Full Access

### Bước 3: Tạo App Store Connect API Key

**Link**: https://appstoreconnect.apple.com/access/api

**Steps**:
1. Click **"Keys"** tab → **"+"** (Generate API Key)
2. **Name**: Codemagic CI/CD
3. **Access**: App Manager (hoặc Admin)
4. Click **"Generate"**
5. **QUAN TRỌNG**: Download file `.p8` NGAY (chỉ download được 1 lần!)
6. Lưu lại 3 thông tin:
   ```
   Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   Key ID: XXXXXXXXXX
   Private Key: (nội dung file .p8)
   ```

### Bước 4: Setup Codemagic

**Link**: https://codemagic.io

**Steps**:

#### 4.1. Create Account
1. Sign up với GitHub account
2. Authorize Codemagic to access `SABOHUB` repo

#### 4.2. Add Application
1. Dashboard → **"Add application"**
2. Select repository: `longsangsabo2025/SABOHUB`
3. Select project type: **Flutter**
4. Click **"Finish"**

#### 4.3. Setup Environment Variables

Vào **App settings** → **Environment variables** → Add các biến sau:

**Group: app_store** (tạo group mới)

```env
# App Store Connect API
APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_KEY_IDENTIFIER=XXXXXXXXXX
APP_STORE_CONNECT_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg...
-----END PRIVATE KEY-----

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Google Drive (for documents feature)
GOOGLE_DRIVE_CLIENT_ID_IOS=xxxx.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_WEB=xxxx.apps.googleusercontent.com
GOOGLE_DRIVE_CLIENT_ID_ANDROID=xxxx.apps.googleusercontent.com
```

**⚠️ LƯU Ý**: 
- Paste TOÀN BỘ nội dung file .p8 vào `APP_STORE_CONNECT_PRIVATE_KEY`
- Bao gồm cả `-----BEGIN PRIVATE KEY-----` và `-----END PRIVATE KEY-----`
- Không có khoảng trắng thừa

#### 4.4. Setup iOS Code Signing

**Option A: Automatic (Khuyến nghị)**

1. Vào **App settings** → **Code signing identities** → **iOS**
2. Click **"Automatic code signing"**
3. Click **"Connect Apple Developer Portal"**
4. Login với Apple ID (cùng account với Developer Program)
5. Codemagic sẽ tự động:
   - Tạo certificates
   - Tạo provisioning profiles
   - Manage signing

**Option B: Manual**

1. Tạo Distribution Certificate trên Apple Developer Portal
2. Export certificate (.p12 file) với password
3. Tạo Provisioning Profile (App Store Distribution)
4. Upload lên Codemagic:
   - Certificate (.p12)
   - Password
   - Provisioning Profile (.mobileprovision)

#### 4.5. Configure Workflow

1. Vào **Workflow settings**
2. Select workflow: **ios-workflow**
3. **Build triggers**:
   - ✅ Enable **"Trigger on push"**
   - Branch: `master`
4. **Workflow editor**:
   - Verify `codemagic.yaml` is detected
   - All settings from file will be used
5. Click **"Save"**

### Bước 5: First Build & Deploy

#### 5.1. Trigger Build

**Option A: Push code**
```bash
git add .
git commit -m "chore: ready for App Store deployment"
git push origin master
```

Codemagic sẽ tự động trigger build.

**Option B: Manual trigger**
1. Codemagic Dashboard → SABOHUB app
2. Click **"Start new build"**
3. Select workflow: **ios-workflow**
4. Click **"Start build"**

#### 5.2. Monitor Build

Build sẽ mất ~15-25 phút:

```
✅ Clone repository (30s)
✅ Setup Flutter (2min)
✅ Setup Xcode (1min)
✅ Create .env file (5s)
✅ Get Flutter packages (1min)
✅ Install CocoaPods (2min)
✅ Flutter analyze (30s)
✅ Flutter test (1min)
✅ Build IPA (10min)
✅ Code sign (1min)
✅ Upload to TestFlight (2min)
✅ Email notification (5s)
```

**Check logs**: Real-time trên Codemagic Dashboard

#### 5.3. Check TestFlight

Sau khi build SUCCESS:

1. Mở **App Store Connect** → **SABOHUB** → **TestFlight**
2. Build mới sẽ xuất hiện với status **"Processing"**
3. Đợi ~10-30 phút cho processing xong
4. Status chuyển thành **"Ready to Test"**

### Bước 6: Internal Testing (TestFlight)

#### 6.1. Add Internal Testers

1. TestFlight → **"Internal Testing"** tab
2. Click **"+"** → Add testers bằng email
3. Or create group: **"Internal Team"**
4. Assign build to group

#### 6.2. Test App

1. Testers nhận email invitation
2. Download **TestFlight app** từ App Store
3. Accept invitation
4. Install SABOHUB build
5. Test tất cả features:
   - ✅ Login/Register
   - ✅ CEO Dashboard
   - ✅ Companies management
   - ✅ Tasks management
   - ✅ Documents (Google Drive)
   - ✅ AI Assistant
   - ✅ Analytics

#### 6.3. Collect Feedback

- Crashes (tự động report trong TestFlight)
- Bugs
- UX issues
- Feature requests

### Bước 7: App Store Submission

Khi đã test kỹ trên TestFlight:

#### 7.1. Prepare App Store Listing

**App Store Connect** → **SABOHUB** → **App Store** tab

**1. App Information:**
- Name: `SABOHUB`
- Subtitle: `Quản lý quán bida chuyên nghiệp`
- Category: **Business** (Primary) / **Productivity** (Secondary)

**2. Pricing and Availability:**
- Price: **Free**
- Availability: **All countries**

**3. App Privacy:**

Click **"Get Started"** và khai báo:

**Data Types Collected:**
- ✅ Contact Info (Email)
- ✅ User Content (Files uploaded to Google Drive)
- ✅ Identifiers (User ID)
- ✅ Location (if using geolocator)
- ✅ Usage Data (Analytics)

**Purpose:**
- App Functionality
- Analytics
- Product Personalization

**4. Screenshots (BẮT BUỘC):**

Cần ít nhất cho 2 sizes:
- **6.7" iPhone** (iPhone 14 Pro Max): 1290 x 2796 pixels
- **6.5" iPhone** (iPhone 11 Pro Max): 1242 x 2688 pixels

**Cách tạo screenshots:**
1. Run app trên simulator với size phù hợp
2. Navigate đến màn hình quan trọng
3. Cmd + S để capture
4. Upload lên App Store Connect

**Gợi ý screenshots:**
- Login/Home screen
- CEO Dashboard với metrics
- Companies list
- Task management
- Documents/Files screen
- Analytics/Reports

**5. Description:**

```
🎱 SABOHUB - Giải pháp quản lý quán bida toàn diện

Ứng dụng quản lý quán bida chuyên nghiệp, giúp chủ quán và nhân viên quản lý mọi hoạt động kinh doanh dễ dàng.

🎯 TÍNH NĂNG CHÍNH:

📊 Dashboard Thông Minh
• Theo dõi doanh thu theo thời gian thực
• Thống kê số lượng khách hàng
• Phân tích xu hướng kinh doanh
• Báo cáo chi tiết theo ngày/tuần/tháng

🏢 Quản Lý Đa Chi Nhánh
• Quản lý nhiều quán/chi nhánh
• Theo dõi hiệu suất từng chi nhánh
• So sánh doanh thu giữa các cơ sở

👥 Quản Lý Nhân Viên
• Tạo tài khoản cho nhân viên
• Phân quyền theo vai trò (Manager/Employee)
• Theo dõi công việc được giao
• Quản lý lịch làm việc

✅ Quản Lý Công Việc
• Tạo và giao công việc
• Theo dõi tiến độ
• Thiết lập deadline
• Thông báo nhắc nhở

📁 Quản Lý Tài Liệu
• Upload files lên Google Drive
• Quản lý hợp đồng, hóa đơn
• Tìm kiếm và phân loại tài liệu
• Chia sẻ files trong team

🤖 AI Assistant
• Hỗ trợ tạo task tự động
• Phân tích dữ liệu thông minh
• Gợi ý tối ưu vận hành

🎱 Đặc biệt cho Quán Bida:
• Quản lý bàn chơi
• Tính toán giờ chơi
• Theo dõi bàn đang sử dụng
• Quản lý đặt chỗ

📈 Báo Cáo & Phân Tích:
• Doanh thu theo thời gian
• Top khách hàng
• Hiệu suất nhân viên
• Export báo cáo Excel/PDF

💼 PHÙ HỢP VỚI:
• Chủ quán bida
• Quản lý chuỗi quán bida
• Nhân viên quán
• Kế toán

🔒 BẢO MẬT:
• Mã hóa dữ liệu end-to-end
• Đăng nhập an toàn
• Phân quyền chi tiết
• Backup tự động

📞 HỖ TRỢ:
• Email: support@sabohub.com
• Website: https://sabohub.com
• Hotline: 1900-xxxx

SABOHUB - Giải pháp quản lý thông minh cho quán bida hiện đại!
```

**6. Keywords:**
```
billiards,pool,quản lý,business,quán bida,management,pos,nhân viên,doanh thu,báo cáo
```

**7. Support & Marketing URLs:**
- Support URL: `https://sabohub.com/support`
- Marketing URL: `https://sabohub.com`
- Privacy Policy URL: `https://sabohub.com/privacy`

**8. Age Rating:**
- 4+ (No objectionable content)

#### 7.2. Select Build

1. Trong **App Store** tab
2. Section **"Build"**
3. Click **"+"** select build từ TestFlight
4. Chọn build mới nhất đã test xong

#### 7.3. Submit for Review

1. Review tất cả thông tin
2. Click **"Save"**
3. Click **"Add for Review"**
4. Click **"Submit for Review"**

**Export Compliance:**
- Does your app use encryption? → **NO**
  (Vì đã set `ITSAppUsesNonExemptEncryption` = FALSE)

**Advertising Identifier:**
- Does your app use IDFA? → **NO**
  (Trừ khi dùng ads)

**Content Rights:**
- Confirm you own all content → **YES**

**Review Notes (Optional):**
```
Demo Account for Testing:
Email: demo@sabohub.com
Password: Demo@123

App is in Vietnamese language.
Main features:
- Business management for billiards halls
- Multi-branch support
- Employee management
- Task tracking
- Document storage via Google Drive
- AI-powered assistant

Please note: Google Drive integration requires Google Sign-In during first use.
```

#### 7.4. Wait for Review

**Timeline:**
- **Waiting for Review**: 0-2 days
- **In Review**: 1-3 days
- **Total**: Usually 24-72 hours

**Status tracking:**
- **Waiting for Review** 🟡: App in queue
- **In Review** 🔵: Apple is reviewing
- **Pending Developer Release** 🟢: Approved, ready to release
- **Ready for Sale** 🟢: Live on App Store!
- **Rejected** 🔴: Need to fix issues

**Email notifications:**
- When review starts
- When approved/rejected

---

## 🎉 Sau khi App Được Approve

### 1. Release Options

**Option A: Auto Release**
- App tự động public ngay khi approve

**Option B: Manual Release**
- Bạn control thời điểm release
- Click **"Release this version"** khi ready

### 2. Monitor

**First 24 hours:**
- Check crashes trong App Store Connect
- Monitor ratings/reviews
- Respond to user feedback

**Tools:**
- App Analytics (App Store Connect)
- Crash Reports (Xcode/App Store Connect)
- Reviews & Ratings

### 3. Updates

Khi cần update:

1. Increment version trong `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # 1.0.1 là version, 2 là build number
   ```

2. Push code → Codemagic auto build

3. Test trên TestFlight

4. Submit update lên App Store
   - Same process như lần đầu
   - Faster review (~24h)

---

## 📊 Current Status

### ✅ Completed
- [x] Code đã sẵn sàng
- [x] Codemagic config đã setup
- [x] Documentation đã complete
- [x] iOS config đã OK

### ⏳ Pending (Cần bạn làm)
- [ ] Apple Developer Account ($99)
- [ ] Tạo app trên App Store Connect
- [ ] Tạo API Key
- [ ] Setup Codemagic account
- [ ] Add environment variables
- [ ] Setup code signing
- [ ] Trigger first build
- [ ] Test on TestFlight
- [ ] Create App Store listing (screenshots, description)
- [ ] Submit for review

---

## 💡 Tips

### Build Faster
- Use Codemagic's cache
- Skip tests trong dev builds: `ignore_failure: true`

### Save Money
- Codemagic free tier: 500 min/month
- ~20 min/build → ~25 builds/month free
- Upgrade to Pro nếu cần more

### Better Reviews
- Respond to all reviews
- Fix bugs nhanh
- Update regularly
- Good screenshots matter!

---

## 🆘 Need Help?

**Common Issues:**
- Build fails → Check logs trong Codemagic
- Code signing error → Use automatic signing
- Review rejected → Read rejection reason carefully
- App crashes → Check TestFlight crash logs

**Resources:**
- Codemagic Docs: https://docs.codemagic.io
- Flutter iOS: https://docs.flutter.dev/deployment/ios
- App Store Guidelines: https://developer.apple.com/app-store/review/guidelines/

---

## ✅ Ready to Deploy!

**Tất cả đã sẵn sàng!** 🚀

Bây giờ chỉ cần:
1. Apple Developer Account
2. 30 phút setup trên Codemagic
3. Push button để build
4. Đợi review
5. 🎉 App lên App Store!

**Ước tính thời gian:** 3-7 ngày (từ khi có Apple Developer Account đến khi app live)

Good luck! 🍀
