# 📋 APP STORE SUBMISSION CHECKLIST - SABOHUB

## ✅ **PRE-SUBMISSION CHECKLIST**

### 🔧 **1. Technical Requirements**
- [ ] ✅ Location permissions fixed (removed NSLocationAlwaysAndWhenInUse)
- [ ] ✅ Deprecated location APIs updated
- [ ] ✅ Print statements wrapped with kDebugMode
- [ ] ⚠️ Build and test on physical iOS device
- [ ] ⚠️ Ensure app works without internet (graceful degradation)
- [ ] ⚠️ Test all core features work with demo account

### 📚 **2. Required Documents & URLs**
- [ ] ⚠️ **CRITICAL: Privacy Policy URL must be live**: https://sabohub.com/privacy
- [ ] ⚠️ **CRITICAL: Support URL must be live**: https://sabohub.com/support  
- [ ] ⚠️ **CRITICAL: Terms of Service URL**: https://sabohub.com/terms
- [ ] ⚠️ **CRITICAL: Demo account working**: demo@sabohub.com / Demo@123

### 🎨 **3. App Store Assets**
- [ ] ⚠️ App icon (1024x1024 PNG)
- [ ] ⚠️ Screenshots for iPhone 6.7" (iPhone 14 Pro Max) - Min 3 required
- [ ] ⚠️ Screenshots for iPhone 6.5" (iPhone 11 Pro Max) - Min 3 required
- [ ] ⚠️ Screenshots for iPad Pro 12.9" (if supporting iPad)

### 📝 **4. App Store Connect Setup**
- [ ] ⚠️ App created on App Store Connect
- [ ] ⚠️ Bundle ID matches: com.sabohub.app
- [ ] ⚠️ App Store Connect API Key configured in CodeMagic
- [ ] ⚠️ Certificates and Provisioning Profiles ready

---

## 🚨 **CRITICAL FIXES NEEDED**

### **PRIORITY 1: Privacy Policy & Support URLs** ⚠️
**Status**: NOT IMPLEMENTED
**Issue**: Apple REQUIRES these URLs to be accessible
**Fix needed**:

1. **Create actual website or GitHub pages**:
   ```bash
   # Quick option: Use GitHub Pages
   # 1. Create repository: sabohub-website
   # 2. Upload privacy_policy.html and support.html
   # 3. Enable GitHub Pages
   # 4. URLs will be: https://yourusername.github.io/sabohub-website/privacy.html
   ```

2. **OR create simple Firebase Hosting**:
   ```bash
   npm install -g firebase-tools
   firebase init hosting
   # Upload HTML files
   firebase deploy
   ```

3. **Update Info.plist if URLs change**

### **PRIORITY 2: Demo Account** ⚠️
**Status**: UNKNOWN
**Issue**: Apple testers need working credentials
**Fix needed**:
1. Create demo@sabohub.com account in your system
2. Ensure it has sample data (company, employees, tasks)  
3. Test login works on TestFlight build
4. Document credentials in App Store Connect

### **PRIORITY 3: Screenshots** ⚠️
**Status**: NOT CREATED
**Issue**: Required for App Store submission
**Fix needed**:
1. Use iPhone 14 Pro Max simulator or device
2. Take 3-5 screenshots showing key features:
   - Login screen
   - Dashboard
   - Employee management
   - Task management
   - Reports
3. Upload to App Store Connect

---

## 📱 **APP STORE CONNECT CONFIGURATION**

### **App Information**
```
Name: SABOHUB
Subtitle: Quản lý quán bida chuyên nghiệp  
Bundle ID: com.sabohub.app
Category: Business
Secondary: Productivity
```

### **Pricing & Availability**
```
Price: Free
Availability: All countries
Age Rating: 4+ (No objectionable content)
```

### **App Privacy Configuration**
Apple requires detailed privacy declarations:

**Data Collected:**
- ✅ **Contact Info**: Email addresses (for account creation)
- ✅ **Location**: Precise location (for check-in verification) 
- ✅ **User Content**: Files and documents (uploaded to Google Drive)
- ✅ **Identifiers**: User ID (for app functionality)
- ✅ **Usage Data**: Analytics (for app improvement)

**Data Uses:**
- ✅ **App Functionality**: All collected data
- ✅ **Analytics**: Usage data only
- ❌ **Third-Party Advertising**: None
- ❌ **Developer's Advertising**: None

**Data Sharing:**
- ❌ **We do NOT sell or share data with third parties**
- ✅ **Google Drive**: Only documents user explicitly uploads
- ✅ **Supabase**: Database hosting (encrypted)

### **App Description Template**
```
SABOHUB - Ứng dụng quản lý quán bida thông minh

🎯 TÍNH NĂNG CHÍNH:
• Quản lý nhân viên và lịch làm việc
• Theo dõi check-in/check-out bằng GPS
• Giao và theo dõi nhiệm vụ
• Báo cáo doanh thu chi tiết
• Quản lý nhiều chi nhánh
• Lưu trữ tài liệu trên cloud

🚀 DÀNH CHO:
✓ Chủ quán bida
✓ Quản lý chuỗi quán
✓ Nhân viên và ca trưởng

🔐 BẢO MẬT:
• Mã hóa dữ liệu đầu cuối
• Phân quyền theo vai trò
• Backup tự động

📞 HỖ TRỢ 24/7:
support@sabohub.com
1900-SABO (1900-7226)

Tải ngay để quản lý quán bida hiệu quả!
```

### **Keywords**
```
billiards,pool,quản lý,business,quán bida,management,pos,nhân viên,doanh thu,báo cáo,check-in,gps,task,nhiệm vụ
```

### **Support URLs**
```
Support URL: https://sabohub.com/support
Marketing URL: https://sabohub.com  
Privacy Policy URL: https://sabohub.com/privacy
```

---

## 🔄 **DEPLOYMENT PROCESS**

### **Step 1: Fix Critical Issues**
1. ⚠️ Create and host privacy policy website
2. ⚠️ Create demo account with sample data
3. ⚠️ Take required screenshots
4. ✅ Code issues already fixed

### **Step 2: CodeMagic Build** 
1. Push code to GitHub
2. Trigger CodeMagic build
3. Wait for TestFlight upload (~20 minutes)
4. Test on TestFlight with multiple devices

### **Step 3: App Store Connect**
1. Select TestFlight build for App Store
2. Complete app information and screenshots
3. Configure privacy settings
4. Submit for review

### **Step 4: Review Process**
- **Timeline**: 24-72 hours typically
- **Status**: Monitor in App Store Connect
- **Notifications**: Apple sends email updates

---

## ⏰ **ESTIMATED TIMELINE**

| Task | Time | Priority |
|------|------|----------|
| Create privacy policy website | 2-4 hours | 🚨 HIGH |
| Setup demo account | 1 hour | 🚨 HIGH |  
| Take screenshots | 1-2 hours | 🚨 HIGH |
| CodeMagic build & test | 2-3 hours | 🟡 MEDIUM |
| App Store submission | 1 hour | 🟡 MEDIUM |
| Apple review wait | 24-72 hours | ⏳ WAITING |

**Total prep time**: ~8-12 hours
**Total to App Store**: ~1-2 days
**Apple review**: ~1-3 days

---

## 🚨 **COMMON REJECTION REASONS TO AVOID**

### ❌ **What Apple Rejects**
1. **Missing Privacy Policy** - URLs not working
2. **Demo Account Issues** - Login fails during review
3. **Crashes on Launch** - App not tested properly  
4. **Missing Functionality** - Features mentioned but not working
5. **Poor Screenshots** - Low quality or misleading
6. **Location Permissions** - Not justified properly
7. **Spam/Low Quality** - App doesn't provide value

### ✅ **How We're Avoiding These**
1. ✅ Fixed location permission description  
2. ✅ Removed unnecessary "Always" location permission
3. ✅ Fixed deprecated APIs and print statements
4. ⚠️ Need to create working privacy policy URL
5. ⚠️ Need to ensure demo account works
6. ⚠️ Need quality screenshots

---

## 📞 **EMERGENCY CONTACTS**

**If app gets rejected:**
- Read rejection reason carefully
- Fix issues mentioned
- Reply to Apple with explanations if needed
- Resubmit (usually faster review ~24h)

**Resources:**
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- CodeMagic Support: https://docs.codemagic.io/
- Apple Developer Support: https://developer.apple.com/support/

---

**🎯 NEXT ACTION ITEMS:**
1. **🚨 URGENT**: Create privacy policy website (https://sabohub.com/privacy)
2. **🚨 URGENT**: Create demo account and test it works
3. **🚨 URGENT**: Take required screenshots on iPhone simulators
4. **🟡 MEDIUM**: Complete App Store Connect setup
5. **🟡 MEDIUM**: Submit for review

**Estimated ready for submission: 1-2 days** (after completing above items)