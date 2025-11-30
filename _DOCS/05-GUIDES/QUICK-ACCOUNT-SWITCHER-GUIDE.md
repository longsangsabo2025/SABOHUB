# 🔄 Quick Account Switcher - Chuyển đổi tài khoản nhanh

## 📋 Tổng quan

Widget **Quick Account Switcher** cho phép bạn lưu và chuyển đổi nhanh giữa nhiều tài khoản đã được xác thực (CEO, Manager, Staff, Shift Leader) mà không cần đăng nhập lại.

## ✨ Tính năng

### 1. **Lưu tài khoản**
- Lưu email, password và role của tài khoản
- Hiển thị tên tùy chỉnh cho mỗi tài khoản
- Lưu trữ bảo mật trong SharedPreferences

### 2. **Chuyển đổi nhanh**
- Click vào nút tài khoản để chuyển đổi ngay lập tức
- Hiển thị icon ✅ cho tài khoản đang hoạt động
- Loading indicator khi đang chuyển đổi

### 3. **Quản lý tài khoản**
- Long press để xóa tài khoản
- Thêm tài khoản mới bằng nút "+"
- Mỗi tài khoản có màu riêng theo role

## 🎨 Giao diện

### Vị trí hiển thị
- **Bottom Right**: Phía trên nút DevRoleSwitcher
- **Floating**: Các nút nổi xếp chồng lên nhau

### Màu sắc theo Role
- 🔵 **CEO**: Blue (`Colors.blue.shade700`)
- 🟢 **Manager**: Green (`Colors.green.shade700`)
- 🟠 **Shift Leader**: Orange (`Colors.orange.shade700`)
- 🟣 **Staff**: Purple (`Colors.purple.shade700`)

### Icons theo Role
- 💼 **CEO**: `Icons.business_center`
- 👔 **Manager**: `Icons.manage_accounts`
- 👨‍💼 **Shift Leader**: `Icons.supervisor_account`
- 👤 **Staff**: `Icons.person`

## 📝 Cách sử dụng

### **Bước 1: Thêm tài khoản**

1. Click vào nút **+** (màu xanh dương)
2. Nhập thông tin:
   ```
   Tên hiển thị: CEO Chính
   Email: ceo@sabohub.com
   Mật khẩu: your_password
   Role: CEO
   ```
3. Click **Thêm**
4. Tài khoản sẽ xuất hiện ở danh sách

### **Bước 2: Thêm tài khoản thứ 2**

1. Click vào nút **+** lần nữa
2. Nhập thông tin Manager:
   ```
   Tên hiển thị: Manager Chi nhánh
   Email: manager@sabohub.com
   Mật khẩu: your_password
   Role: Manager
   ```
3. Click **Thêm**

### **Bước 3: Chuyển đổi tài khoản**

- **Click** vào nút tài khoản để chuyển ngay
- Hệ thống sẽ tự động đăng nhập
- Thông báo ✅ hiện lên khi thành công
- Tài khoản đang dùng có icon ✅

### **Bước 4: Xóa tài khoản**

- **Long press** (giữ lâu) vào nút tài khoản
- Confirm xóa trong dialog
- Tài khoản sẽ bị xóa khỏi danh sách

## 🔧 Cài đặt

### Files đã tạo

1. **Widget chính**
   ```
   lib/widgets/quick_account_switcher.dart
   ```

2. **Integration**
   - `lib/pages/ceo/ceo_main_layout.dart` ✅
   - `lib/layouts/manager_main_layout.dart` ✅

### Code Integration

```dart
// Trong Stack của body
body: Stack(
  children: [
    PageView(...),
    const DevRoleSwitcher(),
    const QuickAccountSwitcher(), // ← Added
  ],
),
```

## 🧪 Testing

### Scenario 1: Thêm 2 tài khoản và chuyển đổi

```dart
// Tài khoản 1 - CEO
Email: ceo@sabohub.com
Password: demo (hoặc mật khẩu thật)
Name: CEO Chính
Role: CEO

// Tài khoản 2 - Manager  
Email: manager@sabohub.com
Password: demo (hoặc mật khẩu thật)
Name: Manager Chi nhánh
Role: Manager
```

**Expected Result:**
- ✅ 2 nút hiển thị ở bottom-right
- ✅ Click vào CEO → Chuyển sang CEO dashboard
- ✅ Click vào Manager → Chuyển sang Manager dashboard
- ✅ Icon ✅ hiển thị ở tài khoản đang dùng

### Scenario 2: Xóa tài khoản

1. Long press vào nút Manager
2. Confirm xóa
3. Expected: Nút Manager biến mất

### Scenario 3: Tài khoản không hợp lệ

1. Thêm tài khoản với email/password sai
2. Click chuyển đổi
3. Expected: Hiển thị thông báo lỗi ❌

## 📦 Data Storage

### SharedPreferences Key
```dart
'@saved_accounts'
```

### JSON Structure
```json
[
  {
    "email": "ceo@sabohub.com",
    "password": "demo",
    "name": "CEO Chính",
    "role": "CEO"
  },
  {
    "email": "manager@sabohub.com",
    "password": "demo",
    "name": "Manager Chi nhánh",
    "role": "Manager"
  }
]
```

## 🔒 Security Notes

### ⚠️ QUAN TRỌNG

1. **Chỉ dùng cho Development/Testing**
   - Widget này chỉ hiển thị trong debug mode
   - Tự động ẩn trong production build
   - Check: `const bool.fromEnvironment('dart.vm.product')`

2. **Lưu trữ mật khẩu**
   - Mật khẩu được lưu **PLAIN TEXT** trong SharedPreferences
   - **KHÔNG BAO GIỜ** dùng trong production
   - Chỉ phù hợp cho local testing

3. **Recommendations**
   - Chỉ dùng với tài khoản test
   - Không lưu mật khẩu thật
   - Xóa dữ liệu sau khi testing

### Production Checklist

Trước khi deploy production:
- [ ] Xóa tất cả saved accounts
- [ ] Clear SharedPreferences
- [ ] Verify widget không hiển thị (check `dart.vm.product`)
- [ ] Remove import nếu không cần

## 💡 Advanced Usage

### Thêm tài khoản bằng code

```dart
final account = SavedAccount(
  email: 'test@sabohub.com',
  password: 'test123',
  name: 'Test User',
  role: 'Staff',
);

// Trong QuickAccountSwitcher state
setState(() {
  _savedAccounts.add(account);
});
await _saveAccounts();
```

### Programmatic Switch

```dart
// Access auth provider
final authNotifier = ref.read(authProvider.notifier);

// Login with credentials
await authNotifier.login(
  'ceo@sabohub.com',
  'demo',
);
```

## 🐛 Troubleshooting

### Widget không hiển thị?
1. Check debug mode: `flutter run` (not release)
2. Verify import trong layout files
3. Check Stack children order

### Chuyển đổi thất bại?
1. Kiểm tra email/password đúng chưa
2. Check Supabase connection
3. Verify user tồn tại trong database
4. Check console logs: `🔵`, `🟢`, `🔴`

### Tài khoản không được lưu?
1. Check SharedPreferences permissions
2. Verify JSON serialization
3. Check console for errors

## 📊 Demo Accounts

### CEO Account (Demo)
```
Email: ceo@demo.com
Password: demo
Name: CEO Demo
Role: CEO
```

### Manager Account (Demo)
```
Email: manager@demo.com
Password: demo
Name: Manager Demo
Role: Manager
```

## ✅ Checklist Completion

- [x] Tạo `QuickAccountSwitcher` widget
- [x] Integration vào `CEOMainLayout`
- [x] Integration vào `ManagerMainLayout`
- [x] Thêm SharedPreferences storage
- [x] Add/Delete account functionality
- [x] Quick switch functionality
- [x] Visual indicators (colors, icons)
- [x] Loading states
- [x] Error handling
- [x] Long press to delete
- [x] Documentation

## 🎯 Next Steps (Optional)

1. **Encryption**: Encrypt passwords trước khi lưu
2. **Biometric**: Thêm fingerprint/face ID
3. **Cloud Sync**: Sync accounts across devices
4. **Auto-switch**: Auto switch based on time/location
5. **Quick Actions**: iOS/Android quick actions

## 📝 Notes

- Widget tự động load saved accounts khi khởi động
- Tài khoản hiện tại có màu xanh lá (green)
- Loading indicator hiển thị khi đang switch
- Toast notification cho mọi action
- Long press > 500ms để trigger delete

---

**Created:** 2025-11-04  
**Last Updated:** 2025-11-04  
**Author:** AI Assistant  
**Status:** ✅ Complete & Ready for Testing
