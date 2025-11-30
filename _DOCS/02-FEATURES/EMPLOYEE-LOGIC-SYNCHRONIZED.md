# ✅ EMPLOYEE LOGIC SYNCHRONIZED - HOÀN TẤT

## 📋 Tổng quan

Đã đồng bộ hoàn toàn logic phân biệt giữa:
- **CEO** → Bảng `auth.users` (Supabase Auth)
- **Employees** → Bảng `employees` (Custom Auth với bcrypt)

---

## 🔄 Các thay đổi đã thực hiện

### 1️⃣ `lib/services/staff_service.dart`

**Trước:**
```dart
// ❌ SAI - Query từ users table
_supabase.from('users').select(...)
```

**Sau:**
```dart
// ✅ ĐÚNG - Query từ employees table
_supabase.from('employees').select(...)
```

**Các hàm đã sửa:**
- `getAllStaff()` → Query từ `employees`
- `getStaffById()` → Query từ `employees`
- `getStaffByRole()` → Query từ `employees`
- `getStaffStats()` → Query từ `employees`, đổi `status` thành `is_active`
- `subscribeToStaff()` → Stream từ `employees`

---

### 2️⃣ `lib/services/employee_service.dart`

**Trước:**
```dart
// ❌ SAI - Tạo vào auth.users và users table
adminSupabase.auth.admin.createUser(...)
_supabase.from('users').insert(...)
```

**Sau:**
```dart
// ✅ ĐÚNG - Tạo vào employees table với bcrypt password
await _supabase.rpc('create_employee_with_password', params: {
  'p_email': email,
  'p_password': tempPassword,
  'p_full_name': fullName,
  'p_role': role.value.toUpperCase(),
  'p_company_id': companyId,
  'p_is_active': true,
}).select();
```

**Các hàm đã sửa:**
- `createEmployeeAccount()` → Tạo vào `employees` thông qua RPC
- `_emailExistsInEmployees()` → Check email trong `employees` table
- Removed `_emailExists()` (dùng cho users table)

---

### 3️⃣ `lib/services/manager_kpi_service.dart`

**Trước:**
```dart
// ❌ SAI - Query từ users table
_supabase.from('users').select('id, status').eq('role', 'STAFF')
```

**Sau:**
```dart
// ✅ ĐÚNG - Query từ employees table
_supabase.from('employees').select('id, is_active').eq('role', 'STAFF')
```

**Các hàm đã sửa:**
- `getDashboardKPIs()` → Query staff count từ `employees`

---

### 4️⃣ `lib/providers/employee_provider.dart`

**Trạng thái:** ✅ **ĐÃ ĐÚNG TỪ TRƯỚC**

```dart
// ✅ ĐÚNG - Provider đã query từ employees table
final response = await _supabase
    .from('employees')
    .select('*')
    .eq('company_id', companyId)
    .eq('is_active', true);
```

**Không cần sửa gì!**

---

## 🗄️ Database Changes

### RPC Function: `create_employee_with_password`

Tạo employee với bcrypt password hash:

```sql
CREATE OR REPLACE FUNCTION create_employee_with_password(
    p_email TEXT,
    p_password TEXT,
    p_full_name TEXT,
    p_role TEXT,
    p_company_id UUID,
    p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE(...) AS $$
DECLARE
    v_password_hash TEXT;
BEGIN
    -- Generate bcrypt hash
    v_password_hash := crypt(p_password, gen_salt('bf'));
    
    -- Insert employee with hashed password
    INSERT INTO employees (email, password_hash, full_name, role, company_id, is_active)
    VALUES (p_email, v_password_hash, p_full_name, p_role, p_company_id, p_is_active)
    RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Status:** ✅ Created successfully

---

## 📊 Current Database State

### `auth.users` Table (CEO Only)
- **5 CEO users** ✅ ĐÚNG
- **6 employees** ❌ SAI (sẽ cleanup sau)

### `employees` Table (Employees Only)
- **2 Managers** ✅
- **1 Shift Leader** ✅
- **1 Staff** ✅
- **Total: 4 active employees** ✅

All employees có password hash ✅

---

## 🎯 Kiến trúc hiện tại

```
┌─────────────────────────────────────────────────────────┐
│                   AUTHENTICATION                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  👔 CEO                                                 │
│     ├─ Bảng: auth.users (Supabase Auth)               │
│     ├─ Login: supabase.auth.signInWithPassword()      │
│     ├─ Role: 'CEO'                                     │
│     └─ RLS: Dựa trên auth.uid()                       │
│                                                         │
│  👥 EMPLOYEES (Manager / Shift Leader / Staff)         │
│     ├─ Bảng: employees (Custom Table)                 │
│     ├─ Login: Custom email/password check             │
│     ├─ Password: bcrypt hash                           │
│     ├─ Roles: MANAGER, SHIFT_LEADER, STAFF            │
│     └─ RLS: CEO can SELECT/INSERT/UPDATE/DELETE       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 Employee Authentication Flow

1. **CEO tạo employee account:**
   ```dart
   final result = await employeeService.createEmployeeAccount(
     companyId: ceoCompanyId,
     companyName: 'SABO Billiards',
     role: UserRole.staff,
     fullName: 'Nguyễn Văn A',
   );
   // Returns: {email: '...', tempPassword: '...'}
   ```

2. **Employee login:**
   ```dart
   // TODO: Implement custom auth
   final employee = await supabase
       .from('employees')
       .select('*')
       .eq('email', email)
       .eq('password_hash', crypt(password, password_hash))
       .single();
   ```

---

## ✅ Checklist

- [x] `staff_service.dart` query từ `employees` table
- [x] `employee_service.dart` tạo vào `employees` table
- [x] `manager_kpi_service.dart` query từ `employees` table
- [x] `employee_provider.dart` đã đúng (không cần sửa)
- [x] RPC function `create_employee_with_password` đã tạo
- [ ] Test UI hiển thị đúng 4 employees
- [ ] Cleanup 6 employees trong `auth.users` table (optional)
- [ ] Implement custom employee login flow (TODO)

---

## 🧪 Testing

### Test 1: UI hiển thị employees
1. Mở app trên Chrome
2. Login với CEO
3. Vào tab "Nhân viên"
4. **Expected:** Hiển thị 4 employees:
   - Trọng Trí (MANAGER)
   - Nguyễn Ánh Dương (STAFF)
   - Huỳnh Thanh Tú (SHIFT_LEADER)
   - Võ Ngọc Diễm (MANAGER)

### Test 2: Tạo employee mới
1. CEO click "Thêm nhân viên"
2. Chọn role, nhập tên
3. Submit
4. **Expected:** Employee mới xuất hiện trong list
5. **Expected:** Console log hiển thị email và temp password

---

## 📝 Next Steps

1. ✅ **HOÀN TẤT** - Đồng bộ logic query từ `employees` table
2. 🔄 **IN PROGRESS** - Test UI hiển thị employees
3. ⏳ **TODO** - Implement custom employee login
4. ⏳ **TODO** - Cleanup employees trong `auth.users` table

---

## 🎉 Kết luận

**Logic đã đồng bộ hoàn toàn:**
- CEO → `auth.users` ✅
- Employees → `employees` table ✅
- All services query từ đúng bảng ✅
- RPC function để tạo employee với password hash ✅

**Chờ verification từ UI!** 🚀
