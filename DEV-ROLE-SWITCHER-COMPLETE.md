# ✅ DEV ROLE SWITCHER - HOÀN THÀNH

## 📋 Tổng quan
Đã thêm lại nút debug **DevRoleSwitcher** lên giao diện tất cả các role layouts và kích hoạt tính năng chuyển role.

---

## 🎯 Tính năng

### 1. **Nút Debug Floating**
- 🟣 Nút tròn màu purple ở góc dưới phải
- 📍 Position: `bottom: 80, right: 16`
- 🎨 Icon: `switch_account`
- ⚡ Mini FAB (compact size)

### 2. **Modal Chuyển Role**
- 📱 Bottom sheet với design đẹp
- 🎨 4 role cards với màu sắc khác nhau:
  - **CEO**: Blue - View all companies & analytics
  - **Manager**: Green - Manage staff & operations  
  - **Shift Leader**: Orange - Lead team & assign tasks
  - **Staff**: Purple - Check-in & complete tasks

### 3. **Navigation System**
- ✅ Click role → Navigate về home với query parameter
- ✅ RoleBasedDashboard tự động detect role từ URL
- ✅ Smooth transition giữa các roles
- ✅ Haptic feedback khi click

---

## 📁 Files đã sửa

### **1. DevRoleSwitcher Widget** (`lib/widgets/dev_role_switcher.dart`)
```dart
// Show only in debug mode
if (!const bool.fromEnvironment('dart.vm.product')) {
  return Positioned(
    bottom: 80,
    right: 16,
    child: FloatingActionButton(
      heroTag: 'dev_role_switcher',
      mini: true,
      backgroundColor: Colors.purple.shade700,
      onPressed: () => _showRoleSelector(context),
      child: const Icon(Icons.switch_account, size: 20),
    ),
  );
}
```

**Thay đổi:**
- ✅ Fixed navigation: `context.go('/?role=$roleIndex')`
- ✅ Added `roleIndex` parameter (0-3) cho mỗi role
- ✅ Removed hardcoded routes `/ceo`, `/manager`, etc.

### **2. CEO Main Layout** (`lib/pages/ceo/ceo_main_layout.dart`)
```dart
body: Stack(
  children: [
    PageView(...),
    const DevRoleSwitcher(), // ← Added
  ],
),
```

### **3. Manager Main Layout** (`lib/layouts/manager_main_layout.dart`)
```dart
body: Stack(
  children: [
    PageView(...),
    const DevRoleSwitcher(), // ← Added
  ],
),
```

### **4. Staff Main Layout** (`lib/pages/staff_main_layout.dart`)
```dart
body: Stack(
  children: [
    SafeArea(
      child: Column(...),
    ),
    const DevRoleSwitcher(), // ← Added
  ],
),
```

### **5. Shift Leader Main Layout** (`lib/layouts/shift_leader_main_layout.dart`)
```dart
body: Stack(
  children: [
    PageView(...),
    const DevRoleSwitcher(), // ← Added
  ],
),
```

### **6. RoleBasedDashboard** (`lib/pages/role_based_dashboard.dart`)
```dart
class RoleBasedDashboard extends ConsumerStatefulWidget {
  final String? roleParam; // ← Added parameter
  
  const RoleBasedDashboard({super.key, this.roleParam});
  
  @override
  void initState() {
    super.initState();
    // Parse role from URL parameter
    if (widget.roleParam != null) {
      final roleIndex = int.tryParse(widget.roleParam!);
      if (roleIndex != null && roleIndex >= 0 && roleIndex < UserRole.values.length) {
        _selectedRole = UserRole.values[roleIndex];
      }
    }
  }
}
```

### **7. App Router** (`lib/core/router/app_router.dart`)
```dart
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) {
    final roleParam = state.uri.queryParameters['role'];
    return RoleBasedDashboard(roleParam: roleParam);
  },
),
```

---

## 🧪 Cách sử dụng

### **Bước 1: Mở App**
- App đang chạy trên Chrome
- Login với bất kỳ account nào

### **Bước 2: Click Nút Debug**
- 🟣 Nút tròn purple ở góc dưới phải
- Hiển thị modal với 4 role options

### **Bước 3: Chọn Role**
- Click vào role card bất kỳ:
  - **CEO** → Xem CEO dashboard
  - **Manager** → Xem Manager dashboard
  - **Shift Leader** → Xem Shift Leader dashboard
  - **Staff** → Xem Staff dashboard

### **Bước 4: Test Navigation**
- ✅ App navigate về home với parameter `?role=0/1/2/3`
- ✅ RoleBasedDashboard tự động load layout cho role đó
- ✅ Bottom navigation hoạt động bình thường
- ✅ Click nút debug lại để switch role khác

---

## 🎨 URL Parameters

```
/?role=0  →  CEO
/?role=1  →  Manager
/?role=2  →  Shift Leader
/?role=3  →  Staff
```

---

## 🔍 Debug Only

```dart
if (!const bool.fromEnvironment('dart.vm.product')) {
  // Nút chỉ hiện trong DEBUG mode
  // Production build sẽ tự động ẩn
}
```

---

## ✅ Checklist

- ✅ DevRoleSwitcher widget hoạt động
- ✅ Navigation với query parameters
- ✅ RoleBasedDashboard parse role từ URL
- ✅ CEO layout có nút debug
- ✅ Manager layout có nút debug
- ✅ Staff layout có nút debug
- ✅ Shift Leader layout có nút debug
- ✅ Modal bottom sheet design đẹp
- ✅ 4 role cards với màu sắc riêng
- ✅ Smooth transitions
- ✅ Debug only (production sẽ ẩn)

---

## 📊 Testing

### **Test Scenarios:**

1. **Click nút debug từ CEO dashboard**
   - ✅ Modal hiển thị
   - ✅ Click Manager → Navigate đúng
   
2. **Click nút debug từ Manager dashboard**
   - ✅ Modal hiển thị
   - ✅ Click Staff → Navigate đúng

3. **Click nút debug từ Staff dashboard**
   - ✅ Modal hiển thị
   - ✅ Click CEO → Navigate đúng

4. **Refresh page với URL `/?role=1`**
   - ✅ App load Manager layout directly

---

## 🎯 Next Steps (Optional)

### **Enhancement Ideas:**
1. 🔔 Add notification badge on role switcher
2. 🎨 Add animation when switching roles
3. 💾 Save last selected role to SharedPreferences
4. 🔐 Add authentication check before role switch
5. 📱 Add keyboard shortcut (Ctrl+Shift+R) to open switcher

---

## 📝 Notes

- Nút debug **chỉ hiện trong DEBUG mode**
- Production build sẽ **tự động ẩn** nút này
- Position được tính để không chặn bottom navigation
- Mỗi layout có Stack wrapper để overlay nút debug
- URL parameters cho phép deep linking vào specific role

---

**Status:** ✅ **HOÀN THÀNH & ĐANG HOẠT ĐỘNG** 🚀

Bây giờ bạn có thể dễ dàng switch giữa các roles để test tất cả tính năng!
