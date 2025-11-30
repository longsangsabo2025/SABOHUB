# 🔄 Quick Account Switcher - Hướng dẫn nhanh

## 📱 Cách sử dụng

### **1. Thêm tài khoản CEO**
1. Mở app trong debug mode
2. Nhìn góc dưới bên phải, click nút **+** (màu xanh)
3. Nhập:
   - **Tên**: CEO Chính
   - **Email**: ceo@sabohub.com (hoặc email CEO của bạn)
   - **Password**: mật khẩu của tài khoản
   - **Role**: CEO
4. Click **Thêm**

### **2. Thêm tài khoản Manager**
1. Click nút **+** lần nữa
2. Nhập:
   - **Tên**: Manager Chi nhánh
   - **Email**: manager@sabohub.com (hoặc email Manager của bạn)
   - **Password**: mật khẩu của tài khoản
   - **Role**: Manager
3. Click **Thêm**

### **3. Chuyển đổi tài khoản**
- **Click** vào nút tên tài khoản để chuyển sang tài khoản đó
- Hệ thống tự động đăng nhập
- Tài khoản đang dùng có icon ✅ màu xanh lá

### **4. Xóa tài khoản**
- **Long press** (giữ lâu) vào nút tài khoản
- Confirm xóa

## 🎨 Giao diện

```
┌─────────────────────────┐
│                         │
│    App Content          │
│                         │
│                         │
│                         │
│               [Manager] │ ← Click để chuyển
│               [CEO ✅]  │ ← Tài khoản hiện tại
│               [+]       │ ← Thêm tài khoản
└─────────────────────────┘
```

## ⚠️ Lưu ý bảo mật

- ⚠️ **CHỈ DÙNG CHO TESTING/DEVELOPMENT**
- ⚠️ Mật khẩu được lưu dạng plain text
- ⚠️ Tự động ẩn trong production build
- ⚠️ Chỉ dùng với tài khoản test

## 📂 Files

- Widget: `lib/widgets/quick_account_switcher.dart`
- Added to: 
  - `lib/pages/ceo/ceo_main_layout.dart`
  - `lib/layouts/manager_main_layout.dart`

## 💡 Tips

- Tài khoản CEO màu xanh dương 🔵
- Tài khoản Manager màu xanh lá 🟢
- Icon ✅ = tài khoản đang dùng
- Loading indicator khi đang chuyển

---

**Status:** ✅ Ready to use  
**Created:** 2025-11-04
