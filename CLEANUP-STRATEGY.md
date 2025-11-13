# 🧹 CLEANUP STRATEGY - OLD EMPLOYEE LOGIC

## 📋 Phân loại `from('users')` usage

### ✅ HỢP LỆ - Keep `from('users')` (CEO data)
- `auth_provider.dart` - Lấy profile CEO sau khi login
- `ceo_profile_page.dart` - CEO profile page
- `user_profile_page.dart` - CEO user profile
- `onboarding_page.dart` - CEO onboarding
- Query CEO's `branch_id`, `company_id` từ users table

### ❌ CẦN SỬA - Đổi sang `from('employees')`

#### 1. `staff_service.dart`
**Lines cần sửa:**
- Line 81: `createStaff()` - INSERT vào `users` ❌
- Line 105: `updateStaff()` - UPDATE trong `users` ❌
- Line 121: `deleteStaff()` - UPDATE status trong `users` ❌

**Action:** Đổi ALL thành `employees` table

---

#### 2. `manager_kpi_service.dart`
**Lines cần sửa:**
- Line 17: Query CEO's `branch_id` từ `users` ✅ (keep)
- Line 131: Query staff list từ `users` ❌
- Line 123: Query CEO's `branch_id` từ `users` ✅ (keep)
- Line 185: Query CEO's `branch_id` từ `users` ✅ (keep)

**Action:** Chỉ đổi line 131 (staff list query)

---

#### 3. `employee_service.dart`
**Lines cần sửa:**
- Line 24: `emailExists()` - Check email trong `users` ❌
- Line 38: `getUserByEmail()` - Get user từ `users` ❌
- Line 278: Query user info từ `users` ❌
- Line 347: `updateEmployee()` - UPDATE trong `users` ❌
- Line 370: `deleteEmployee()` - DELETE từ `users` ❌
- Line 392: Query employees từ `users` ❌

**Action:** ĐÃ SỬA createEmployeeAccount(), còn cần sửa các hàm khác

---

#### 4. `manager_staff_page.dart` & `shift_leader_team_page.dart`
**Lines cần sửa:**
- Query team members từ `users` ❌

**Action:** Đổi thành `employees`

---

### ⚠️ CẦN XEM XÉT - Context dependent

#### `attendance_service.dart`
- Line 153: Query user info - Có thể là CEO hoặc employee
- **Decision:** Cần check context, có thể cần join cả 2 tables

#### `management_task_service.dart`
- Line 417: Query user cho task assignment
- **Decision:** Tasks có thể assign cho CEO hoặc employee

---

## 🎯 CLEANUP PLAN

### Phase 1: Database Cleanup ✅ READY
```bash
python cleanup_old_employee_logic.py
```
- Xóa 6 employees sai trong `auth.users`
- Chỉ giữ lại CEO users

---

### Phase 2: Code Cleanup (Priority Order)

#### 🔥 HIGH PRIORITY
1. ✅ `staff_service.dart` - Core employee operations
2. ✅ `employee_service.dart` - Employee CRUD (partially done)
3. ✅ `manager_kpi_service.dart` - Dashboard stats

#### 🟡 MEDIUM PRIORITY
4. `manager_staff_page.dart` - UI query employees
5. `shift_leader_team_page.dart` - UI query team

#### 🟢 LOW PRIORITY (Context dependent)
6. `attendance_service.dart` - Mixed (CEO + employees)
7. `management_task_service.dart` - Mixed (CEO + employees)
8. Other services - Mostly CEO operations (OK to keep)

---

## 📝 DETAILED CHANGES NEEDED

### 1. Complete `employee_service.dart` cleanup

```dart
// ❌ OLD
Future<bool> emailExists(String email) async {
  return await _supabase.from('users').select('id').eq('email', email);
}

// ✅ NEW - Check both tables
Future<bool> emailExists(String email) async {
  // Check CEO in users
  final ceoCheck = await _supabase.from('users').select('id').eq('email', email);
  if (ceoCheck.isNotEmpty) return true;
  
  // Check employees in employees
  final empCheck = await _supabase.from('employees').select('id').eq('email', email);
  return empCheck.isNotEmpty;
}
```

---

### 2. Fix `staff_service.dart` CRUD operations

```dart
// ❌ OLD - createStaff()
await _supabase.from('users').insert({...})

// ✅ NEW
await _supabase.from('employees').insert({...})

// ❌ OLD - updateStaff()
await _supabase.from('users').update({...})

// ✅ NEW
await _supabase.from('employees').update({...})

// ❌ OLD - deleteStaff()
await _supabase.from('users').update({'status': 'inactive'})

// ✅ NEW
await _supabase.from('employees').update({'is_active': false})
```

---

### 3. Fix `manager_kpi_service.dart` staff query

```dart
// ❌ OLD - Line 131
final baseQuery = _supabase.from('users').select('...');

// ✅ NEW
final baseQuery = _supabase.from('employees').select('...');
```

---

### 4. Fix UI pages staff queries

```dart
// manager_staff_page.dart & shift_leader_team_page.dart

// ❌ OLD
.from('users').select('*').eq('company_id', companyId)

// ✅ NEW
.from('employees').select('*').eq('company_id', companyId)
```

---

## 🚀 EXECUTION ORDER

1. **Run database cleanup script** ✅ READY
   ```bash
   python cleanup_old_employee_logic.py
   ```

2. **Complete code changes:**
   - [ ] employee_service.dart remaining methods
   - [ ] staff_service.dart CRUD operations
   - [ ] manager_kpi_service.dart staff list query
   - [ ] manager_staff_page.dart
   - [ ] shift_leader_team_page.dart

3. **Test after each change:**
   - Hot reload app
   - Verify UI still works
   - Check console for errors

4. **Final verification:**
   - Run all tests
   - Verify employees tab
   - Verify manager/shift leader pages

---

## ✅ SUMMARY

**Total files needing changes:** 5 files
- `employee_service.dart` (6 methods)
- `staff_service.dart` (3 methods)
- `manager_kpi_service.dart` (1 method)
- `manager_staff_page.dart` (1 query)
- `shift_leader_team_page.dart` (1 query)

**Estimated time:** 30-45 minutes

**Risk level:** 🟡 MEDIUM
- Potential breaking changes in UI
- Need thorough testing after changes
