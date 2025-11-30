# ⚠️⚠️⚠️ CRITICAL: AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️

## **QUY TẮC BẮT BUỘC - ĐỌC TRƯỚC KHI LÀM BẤT CỨ ĐIỀU GÌ!**

### 🔴 NHÂN VIÊN KHÔNG CÓ TÀI KHOẢN SUPABASE AUTH!

---

## Kiến trúc Authentication

### 1. CEO (Chủ doanh nghiệp)
- ✅ **Có tài khoản Supabase Auth** (email + password)
- ✅ Đăng ký và đăng nhập qua `auth.users`
- ✅ Có `user_id` trong bảng `auth.users`
- ✅ Có record trong bảng `companies` với `owner_id = auth.user.id`

### 2. NHÂN VIÊN (Manager, Staff, tất cả roles khác)
- ❌ **KHÔNG có tài khoản Supabase Auth**
- ❌ KHÔNG có email/password để login vào Supabase
- ❌ KHÔNG có user_id trong `auth.users`
- ✅ Được CEO tạo trong bảng `employees`
- ✅ Login bằng **MÃ NHÂN VIÊN** (employee code)
- ✅ Có `employee_id` trong bảng `employees`

---

## Cấu trúc Database

### Bảng `auth.users` (Supabase Auth)
```sql
-- CHỈ CHỨA CEO
id | email | raw_user_meta_data
```
**Lưu ý:** Nhân viên KHÔNG có trong bảng này!

### Bảng `employees`
```sql
-- CHỨA TẤT CẢ NHÂN VIÊN (bao gồm cả Manager)
id              -- Employee ID (UUID)
employee_code   -- Mã nhân viên để login
name
email           -- Email nhân viên (KHÔNG dùng cho auth)
phone
role            -- 'manager', 'staff', 'accountant', v.v.
company_id      -- FK to companies
branch_id       -- FK to branches
user_id         -- NULL (vì không có auth account)
password_hash   -- Hash của mã nhân viên
```

---

## Cách Lấy Thông Tin User

### ❌ SAI - KHÔNG BAO GIỜ LÀM NHƯ NÀY:
```dart
// SAI! Nhân viên không có trong Supabase Auth
final user = Supabase.instance.client.auth.currentUser;

// SAI! Không query auth.users cho nhân viên
final userData = await supabase
    .from('auth.users')
    .select()
    .eq('id', userId);
```

### ✅ ĐÚNG - LUÔN LÀM NHƯ NÀY:
```dart
// ĐÚNG! Dùng authProvider để lấy employee
final currentUser = ref.read(authProvider).user;

// currentUser sẽ có:
// - id: employee_id (KHÔNG phải auth.user.id)
// - name: tên nhân viên
// - role: UserRole enum
// - companyId: company_id
// - branchId: branch_id
```

---

## Khi Code Các Features

### Attendance (Chấm công)
```dart
// ✅ ĐÚNG
final employee = ref.read(authProvider).user;
await attendanceService.checkIn(
  userId: employee.id,  // employee_id, KHÔNG phải auth user id
  branchId: employee.branchId,
  companyId: employee.companyId,
);
```

### Tasks (Công việc)
```dart
// ✅ ĐÚNG  
final employee = ref.read(authProvider).user;
final tasks = await supabase
    .from('tasks')
    .select()
    .eq('assigned_to', employee.id);  // employee_id
```

### Reports (Báo cáo)
```dart
// ✅ ĐÚNG
final employee = ref.read(authProvider).user;
final reports = await supabase
    .from('daily_work_reports')
    .select()
    .eq('employee_id', employee.id);  // employee_id
```

---

## RLS Policies

### Employees Table
```sql
-- RLS cho nhân viên xem thông tin của mình
CREATE POLICY "Employees can view own data" ON employees
FOR SELECT USING (
  id = (current_setting('app.employee_id')::uuid)
);
```

**Lưu ý:** KHÔNG dùng `auth.uid()` cho nhân viên!

---

## Auth Flow

### CEO Login
1. Email + Password
2. Supabase Auth (`auth.signInWithPassword`)
3. Check `companies` table where `owner_id = auth.user.id`
4. Set authProvider với CEO user

### Employee Login
1. Mã nhân viên (employee_code)
2. Query `employees` table
3. Verify password hash
4. Set authProvider với employee user
5. **KHÔNG** tương tác với Supabase Auth

---

## Checklist Khi Code Feature Mới

- [ ] Đọc file này trước khi bắt đầu
- [ ] KHÔNG dùng `Supabase.instance.client.auth.currentUser` cho nhân viên
- [ ] KHÔNG query `auth.users` cho nhân viên
- [ ] Dùng `ref.read(authProvider).user` để lấy thông tin
- [ ] userId trong các service = employee.id (KHÔNG phải auth.user.id)
- [ ] RLS policies KHÔNG dùng `auth.uid()` cho nhân viên
- [ ] Test với cả CEO và nhân viên

---

## Files Quan Trọng

1. `lib/providers/auth_provider.dart` - Auth state management
2. `lib/models/user.dart` - User model (cho cả CEO và employee)
3. `lib/services/auth_service.dart` - Employee login logic
4. `AUTHENTICATION_ARCHITECTURE.md` - File này!

---

## ⚠️ LƯU Ý QUAN TRỌNG

**NẾU BẠN THẤY CODE NÀO:**
- Dùng `auth.currentUser` cho manager/staff → SAI, phải sửa!
- Query `auth.users` cho nhân viên → SAI, phải sửa!
- Dùng `auth.uid()` trong RLS cho nhân viên → SAI, phải sửa!

**HÃY SỬA NGAY và cập nhật documentation!**

---

## Liên Hệ

Nếu có thắc mắc về kiến trúc auth, hỏi CEO hoặc đọc lại file này!

**CHỈ CÓ CEO MỚI CÓ TÀI KHOẢN SUPABASE AUTH!**
**NHÂN VIÊN = EMPLOYEE RECORD, KHÔNG PHẢI AUTH USER!**
