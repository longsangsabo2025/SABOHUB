# 🔍 AUDIT: Supabase Auth Usage - Tìm Lỗi Dùng Sai

## ⚠️ QUY TẮC
**CHỈ CEO MỚI CÓ SUPABASE AUTH!**
- ✅ CEO pages/services → OK to use `auth.currentUser`
- ❌ Manager/Employee pages → PHẢI dùng `authProvider.user`

---

## 🔴 CÁC FILE ĐANG DÙNG SAI - CẦN SỬA NGAY

### 1. **Manager Pages** (CRITICAL - Ảnh hưởng trực tiếp Manager)

#### ❌ `lib/pages/manager/employee_performance_page.dart` (Line 39)
```dart
// SAI - Manager không có auth account
final userId = supabase.client.auth.currentUser?.id;
```
**Cần sửa thành:**
```dart
final currentUser = ref.read(authProvider).user;
final userId = currentUser?.id; // employee.id
```

---

### 2. **Manager Services** (HIGH PRIORITY)

#### ❌ `lib/services/manager_kpi_service.dart` (Lines 12, 127, 192)
```dart
// SAI - Service cho Manager nhưng dùng auth
final userId = _supabase.auth.currentUser?.id;
```
**Vấn đề:** Service này dùng cho Manager Dashboard, nhưng lại dùng Supabase Auth

**Giải pháp:** Cần truyền `employeeId` vào từ caller thay vì lấy từ auth

---

#### ❌ `lib/services/management_task_service.dart` (Lines 22, 133, 228, 247, 264, 500)
```dart
// SAI - Có thể được dùng bởi Manager
final userId = _supabase.auth.currentUser?.id;
```
**Vấn đề:** Service này có method như `getCEOStrategicTasks()` (OK cho CEO) nhưng cũng có method khác có thể được Manager dùng

**Giải pháp:** 
- Method cho CEO: Giữ nguyên `auth.currentUser`
- Method cho Manager: Cần truyền `employeeId` parameter

---

### 3. **Shared Services** (MEDIUM PRIORITY - Cần Review)

#### ⚠️ `lib/services/business_document_service.dart` (Lines 59, 96)
```dart
final currentUser = _supabase.auth.currentUser;
```
**Cần kiểm tra:** Service này được dùng bởi ai? CEO only hay cả Manager?

#### ⚠️ `lib/services/bill_service.dart` (Lines 20, 77, 99)
```dart
final userId = _supabase.auth.currentUser?.id;
```
**Cần kiểm tra:** Ai tạo bills? Chỉ CEO hay cả Staff?

#### ⚠️ `lib/services/commission_service.dart` (Lines 98, 123, 149, 172, 191)
```dart
final userId = _supabase.auth.currentUser?.id;
```
**Cần kiểm tra:** Tính commission cho ai?

#### ⚠️ `lib/services/commission_rule_service.dart` (Line 23)
```dart
final currentUserId = _supabase.auth.currentUser?.id;
```
**Cần kiểm tra:** Ai tạo commission rules?

---

### 4. **CEO Services** (✅ OK - Không cần sửa)

#### ✅ `lib/services/company_service.dart` (Line 69)
```dart
final userId = _supabase.auth.currentUser?.id;
```
**OK** - Chỉ CEO tạo company

#### ✅ `lib/pages/ceo/daily_reports_dashboard_page.dart` (Line 41)
```dart
final user = _supabase.auth.currentUser;
```
**OK** - CEO page

#### ✅ `lib/providers/ceo_dashboard_provider.dart` (Lines 9, 88)
```dart
final userId = supabaseClient.auth.currentUser?.id;
```
**OK** - CEO dashboard

#### ✅ `lib/pages/ceo/company/tasks_tab.dart` (Line 1059)
```dart
final currentUser = Supabase.instance.client.auth.currentUser;
```
**OK** - CEO tasks tab

---

### 5. **Auth Provider** (✅ OK - Core Auth Logic)

#### ✅ `lib/providers/auth_provider.dart` (Line 238)
```dart
final currentUser = _supabaseClient.auth.currentUser;
```
**OK** - Đây là core auth logic, cần dùng để check CEO login

---

### 6. **Core Services** (✅ OK - Infrastructure)

#### ✅ `lib/core/services/supabase_service.dart` (Line 15)
```dart
User? get currentUser => client.auth.currentUser;
```
**OK** - Infrastructure code

---

## 📊 THỐNG KÊ

| Loại | Số file | Ưu tiên |
|------|---------|---------|
| 🔴 **Manager Pages - CẦN SỬA NGAY** | 1 | CRITICAL |
| 🔴 **Manager Services - CẦN SỬA NGAY** | 2 | HIGH |
| ⚠️ **Shared Services - CẦN REVIEW** | 4 | MEDIUM |
| ✅ **CEO Services - OK** | 5 | N/A |
| ✅ **Infrastructure - OK** | 2 | N/A |

---

## 🔧 HÀNH ĐỘNG CẦN LÀM

### Bước 1: Sửa Manager Pages (CRITICAL)
- [ ] `employee_performance_page.dart` - Đổi sang `authProvider.user`

### Bước 2: Sửa Manager Services (HIGH)
- [ ] `manager_kpi_service.dart` - Thêm parameter `employeeId`
- [ ] `management_task_service.dart` - Review từng method, phân biệt CEO vs Manager

### Bước 3: Review Shared Services (MEDIUM)
- [ ] `business_document_service.dart` - Kiểm tra caller
- [ ] `bill_service.dart` - Kiểm tra caller
- [ ] `commission_service.dart` - Kiểm tra caller
- [ ] `commission_rule_service.dart` - Kiểm tra caller

### Bước 4: Test Toàn Bộ
- [ ] Test với CEO login
- [ ] Test với Manager login
- [ ] Test với Staff login

---

## 💡 PATTERN ĐỀ XUẤT

### Pattern 1: Page/Widget (có access to Riverpod)
```dart
// ✅ ĐÚNG
final currentUser = ref.read(authProvider).user;
if (currentUser == null) return;

final userId = currentUser.id; // employee.id hoặc CEO id
final companyId = currentUser.companyId;
final branchId = currentUser.branchId;
```

### Pattern 2: Service (không có access to Riverpod)
```dart
// ✅ ĐÚNG - Truyền userId từ caller
Future<Data> getData({required String userId}) async {
  // Không dùng auth.currentUser ở đây
  // Caller sẽ truyền employee.id hoặc CEO id
}
```

### Pattern 3: CEO-only Service
```dart
// ✅ ĐÚNG - Chỉ CEO dùng, OK to use auth
Future<Data> getCEOData() async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');
  // ...
}
```

---

## 📝 GHI CHÚ

1. **Manager KPI Service**: Cần refactor để nhận `employeeId` từ caller thay vì lấy từ auth
2. **Management Task Service**: Cần review từng method, có method cho CEO (OK dùng auth), có method share (cần parameter)
3. **Shared Services**: Cần trace xem service được gọi từ đâu để quyết định có cần sửa không

---

## ✅ ĐÃ SỬA

- [x] `manager_attendance_page.dart` - Đã sửa sang `authProvider.user`

---

**Người tạo:** AI Assistant  
**Ngày:** 2024-11-13  
**Mục đích:** Audit toàn bộ usage của Supabase Auth để tìm lỗi dùng sai cho Manager/Employee
