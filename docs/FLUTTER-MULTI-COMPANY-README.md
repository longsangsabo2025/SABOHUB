# 🚀 SABOHUB - Multi-Company Management Platform

## 📱 Flutter App - CEO Dashboard với Multi-Tenant Architecture

### ✅ Hoàn Thành

**Version**: 1.0.0  
**Platform**: Flutter (Pure Dart - NO native plugins)  
**State Management**: Riverpod  
**Architecture**: Multi-Company/Multi-Tenant

---

## 🎯 Tính Năng Chính

### 1. **Multi-Company Management** (CEO)

- ✅ CEO quản lý **NHIỀU doanh nghiệp** khác nhau
- ✅ Mỗi doanh nghiệp có loại hình riêng:
  - 🎱 **Quán Bida** (Billiards)
  - 🍽️ **Nhà Hàng** (Restaurant)
  - 🏨 **Khách Sạn** (Hotel)
  - ☕ **Quán Cafe** (Cafe)
  - 🏪 **Cửa Hàng** (Retail)

### 2. **Company Selection Screen**

- ✅ CEO có thể **chuyển đổi** giữa các doanh nghiệp
- ✅ Hiển thị thông tin chi tiết:
  - Tên doanh nghiệp
  - Loại hình kinh doanh
  - Địa chỉ
  - Số lượng bàn/phòng
  - Số nhân viên
  - Doanh thu tháng

### 3. **Role-Based Access**

- ✅ **CEO**: Quản lý nhiều doanh nghiệp
- ✅ **Manager**: Quản lý 1 doanh nghiệp
- ✅ **Shift Leader**: Quản lý ca
- ✅ **Staff**: Nhân viên

### 4. **Dynamic Dashboard**

- ✅ Hiển thị thông tin doanh nghiệp hiện tại
- ✅ Theme color thay đổi theo loại hình doanh nghiệp
- ✅ Stats dashboard real-time

---

## 🎨 UI/UX Features

### Dark Theme

- ✅ Material 3 Design System
- ✅ Gradient backgrounds
- ✅ Smooth animations
- ✅ Card-based layout

### Navigation

- ✅ SliverAppBar với gradient header
- ✅ Company selector button (CEO only)
- ✅ Logout confirmation dialog

---

## 👥 Demo Accounts

### CEO Account (Multi-Company)

```
Email: ceo@sabohub.com
Password: demo123
Companies:
  - Sabo Billiards Premium (Quận 1)
  - Sabo Billiards VIP (Quận 3)
  - Nhà Hàng Sabo Garden (Quận 7)
  - Sabo Coffee & Lounge (Quận 2)
```

### Manager Account (Single Company)

```
Email: manager@sabohub.com
Password: demo123
Company: Sabo Billiards Premium
```

### Shift Leader Account

```
Email: shift@sabohub.com
Password: demo123
Company: Sabo Billiards Premium
```

### Staff Account

```
Email: staff@sabohub.com
Password: demo123
Company: Sabo Billiards Premium
```

---

## 🏗️ Architecture

### State Management Structure

```dart
AuthState {
  - isLoggedIn: bool
  - email: String?
  - name: String?
  - role: String?
  - icon: String?
  - companies: List<Company>
  - selectedCompany: Company?
}
```

### Company Model

```dart
Company {
  - id: String
  - name: String
  - type: BusinessType
  - address: String
  - tableCount: int
  - monthlyRevenue: double
  - employeeCount: int
}
```

### Business Types

```dart
enum BusinessType {
  billiards (🎱, #3B82F6),
  restaurant (🍽️, #10B981),
  hotel (🏨, #F59E0B),
  cafe (☕, #8B5CF6),
  retail (🏪, #EF4444)
}
```

---

## 📊 Demo Data

### CEO Companies (Demo)

1. **Sabo Billiards Premium**

   - Type: Billiards
   - Location: Quận 1, TP.HCM
   - Tables: 20
   - Revenue: 150M/month
   - Staff: 12

2. **Sabo Billiards VIP**

   - Type: Billiards
   - Location: Quận 3, TP.HCM
   - Tables: 15
   - Revenue: 120M/month
   - Staff: 8

3. **Nhà Hàng Sabo Garden**

   - Type: Restaurant
   - Location: Quận 7, TP.HCM
   - Tables: 30
   - Revenue: 250M/month
   - Staff: 25

4. **Sabo Coffee & Lounge**
   - Type: Cafe
   - Location: Quận 2, TP.HCM
   - Tables: 25
   - Revenue: 80M/month
   - Staff: 10

---

## 🚀 Run Instructions

### Prerequisites

- Flutter SDK 3.24.5+
- Android SDK
- Emulator or Physical Device

### Run Command

```bash
cd flutter_sabohub
flutter run
```

Or use batch file:

```bash
.\run.bat
```

### Hot Reload

Press `r` in terminal to hot reload changes.

---

## 📝 Technical Notes

### Pure Flutter Architecture

- ✅ **NO native plugins** để tránh build issues
- ✅ In-memory state management (Riverpod)
- ✅ NO SharedPreferences dependency
- ✅ NO Google Fonts dependency
- ✅ Sử dụng system fonts và Material icons

### Giải pháp vấn đề

- ❌ Loại bỏ `shared_preferences` → Native Android conflict
- ❌ Loại bỏ `google_fonts` → path_provider_android issue
- ❌ Loại bỏ `supabase_flutter` → app_links build failed
- ✅ **Solution**: Pure Dart + Riverpod state = ZERO build issues

---

## 🎯 Next Steps

### Phase 2 - Company Management

- [ ] Add new company
- [ ] Edit company details
- [ ] Delete company
- [ ] Company statistics

### Phase 3 - Table/Room Management

- [ ] View tables/rooms status
- [ ] Assign customer to table
- [ ] Calculate billing
- [ ] Payment processing

### Phase 4 - Staff Management

- [ ] Add/remove staff
- [ ] Shift scheduling
- [ ] Performance tracking
- [ ] Salary management

### Phase 5 - Reporting

- [ ] Daily reports
- [ ] Monthly reports
- [ ] Revenue charts
- [ ] Export to Excel

---

## 📞 Support

**Project**: SABOHUB  
**Version**: 1.0.0  
**Status**: ✅ Production Ready (Demo)  
**Architecture**: Multi-Tenant (CEO manages multiple companies)

---

## 🎉 Success Metrics

- ✅ App builds successfully
- ✅ Hot reload works
- ✅ CEO can switch between companies
- ✅ Role-based access control
- ✅ Dynamic theming per business type
- ✅ Clean architecture with Riverpod
- ✅ ZERO native plugin dependencies
