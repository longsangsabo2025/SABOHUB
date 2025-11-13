# 🔐 AUTHENTICATION ARCHITECTURE - ĐỌC KỸ TRƯỚC KHI CODE

## ⚠️ QUY TẮC VÀNG - KHÔNG BAO GIỜ QUÊN

### 👤 PHÂN CHIA NGƯỜI DÙNG

```
┌─────────────────────────────────────────────────────────────┐
│                    SABOHUB USER SYSTEM                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CEO (auth.users table)                                 │
│     - Supabase Authentication (email + password)           │
│     - Full system access                                    │
│     - Table: auth.users + public.users                      │
│                                                             │
│  2. ALL EMPLOYEES (public.employees table)                  │
│     - Custom Authentication (company_name + username + pwd) │
│     - Roles: MANAGER, SHIFT_LEADER, STAFF                   │
│     - Table: public.employees ONLY                          │
│     - NO Supabase Auth account                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 📊 DATABASE TABLES

### ✅ `auth.users` + `public.users`
**CHỈ DÙNG CHO CEO**

```sql
-- CEO login với Supabase Auth
-- Email: ceo@company.com
-- Password: supabase password
```

**Columns:**
- `id` (UUID) - Auth user ID
- `email` - CEO email
- `role` = 'CEO' (ALWAYS)
- `company_id` - Link to company
- `full_name` - CEO name

### ✅ `public.employees`
**TẤT CẢ NHÂN VIÊN (Manager, Shift Leader, Staff)**

```sql
-- Employee login KHÔNG dùng Supabase Auth
-- Company: SABO Billiards
-- Username: manager01
-- Password: custom hashed password
```

**Columns:**
- `id` (UUID) - Employee ID
- `company_id` - Link to company
- `username` - Login username (unique per company)
- `password_hash` - bcrypt hashed password
- `full_name` - Employee name
- `role` - 'MANAGER' | 'SHIFT_LEADER' | 'STAFF'
- `is_active` - Status
- `branch_id` - Branch assignment

## 🚨 COMMON MISTAKES - ĐỪNG LÀM

### ❌ SAI: Query managers từ users table
```dart
// WRONG - managers KHÔNG CÓ trong users table
final managers = await supabase
    .from('users')
    .select()
    .eq('role', 'MANAGER'); // ← SẼ TRỐNG!
```

### ✅ ĐÚNG: Query managers từ employees table
```dart
// CORRECT - ALL employees including managers
final managers = await supabase
    .from('employees')
    .select()
    .eq('role', 'MANAGER')
    .eq('is_active', true);
```

## 🔗 RELATIONSHIPS

### Attendance Table
```sql
CREATE TABLE attendance (
  user_id UUID REFERENCES users(id),  -- ← CHỈ CHO CEO
  employee_id UUID REFERENCES employees(id),  -- ← CHO EMPLOYEES
  ...
);
```

**⚠️ CRITICAL:**
- Nếu CEO check-in: dùng `user_id`
- Nếu Employee check-in: dùng `employee_id`

### Tasks Table
```sql
CREATE TABLE tasks (
  created_by UUID,  -- CEO user_id HOẶC employee.id
  assigned_to UUID,  -- Employee.id (MANAGER/STAFF)
  ...
);
```

## 📝 CODING GUIDELINES

### 1. Authentication Check
```dart
// Check if current user is CEO
final user = Supabase.instance.client.auth.currentUser;
if (user != null) {
  // This is CEO (has Supabase auth)
  final userId = user.id;
} else {
  // This is Employee (custom auth)
  // Check session storage for employee_id
}
```

### 2. Fetching Employees
```dart
// Always use employees table for staff queries
final employees = await supabase
    .from('employees')
    .select('id, full_name, role, company_id')
    .eq('company_id', companyId)
    .eq('is_active', true);
```

### 3. Creating Tasks
```dart
// CEO assigns task to Manager
await supabase.from('management_tasks').insert({
  'created_by': ceoUserId,  // from auth.users
  'assigned_to': managerId,  // from employees.id
  'created_by_role': 'CEO',
  'assigned_to_role': 'MANAGER',
});
```

## 🎯 QUICK REFERENCE

| User Type | Auth Method | Table | Role Values |
|-----------|-------------|-------|-------------|
| **CEO** | Supabase Auth | `users` | `CEO` |
| **Manager** | Custom Auth | `employees` | `MANAGER` |
| **Shift Leader** | Custom Auth | `employees` | `SHIFT_LEADER` |
| **Staff** | Custom Auth | `employees` | `STAFF` |

## 🛠️ MIGRATION HISTORY

### Phase 1: Old System (DEPRECATED)
- All users in `users` table with Supabase Auth
- ❌ Problem: Too many auth accounts, complex management

### Phase 2: Current System (ACTIVE)
- CEO only in `users` table (Supabase Auth)
- All employees in `employees` table (Custom Auth)
- ✅ Solution: Simple, scalable, easy management

## 📞 WHEN IN DOUBT

**Remember:**
1. `users` table = CEO ONLY
2. `employees` table = EVERYONE ELSE
3. Never query managers from `users`
4. Always use `employees` for staff operations

---

**Last Updated:** 2025-11-12  
**Author:** SABO Development Team  
**Status:** ✅ ACTIVE - DO NOT MODIFY WITHOUT APPROVAL
