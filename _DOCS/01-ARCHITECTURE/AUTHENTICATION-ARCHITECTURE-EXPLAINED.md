# 🔐 KIẾN TRÚC KHI TẮT SUPABASE EMAIL AUTH

## Current Setup (dựa trên database):

```
┌─────────────────────────────────────────────────────────────┐
│ SUPABASE AUTH (Email) - CHỈ CEO/Manager                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  auth.users (Supabase built-in)                             │
│  ├─ CEO creates company                                     │
│  ├─ Manager manages branch                                  │
│  └─ Login: email + password (Supabase Auth)                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ CUSTOM AUTH - Staff/Employees                               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  public.employees (Custom table)                            │
│  ├─ username (unique)                                       │
│  ├─ password_hash (bcrypt/argon2)                          │
│  ├─ email (nullable)                                        │
│  └─ Login: username + password (Custom logic)               │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ UNIFIED TABLE - public.users                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Cách này: TẤT CẢ đều vào 1 bảng                           │
│  ├─ id (link to auth.users.id cho CEO/Manager)             │
│  ├─ username (cho Staff)                                    │
│  ├─ password_hash (cho Staff)                               │
│  ├─ role: CEO, MANAGER, STAFF                               │
│  └─ auth_type: 'supabase' | 'custom'                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## ❓ VẬY ATTENDANCE TABLE DÙNG GÌ?

### Option 1: Dual Reference (Recommended)
```sql
CREATE TABLE attendance (
  id UUID PRIMARY KEY,
  
  -- For CEO/Manager (Supabase Auth)
  user_id UUID REFERENCES auth.users(id),
  
  -- For Staff (Custom Auth)  
  employee_id UUID REFERENCES employees(id),
  
  -- At least one must be present
  CHECK (user_id IS NOT NULL OR employee_id IS NOT NULL),
  
  company_id UUID NOT NULL,
  branch_id UUID NOT NULL,
  check_in TIMESTAMPTZ,
  check_out TIMESTAMPTZ,
  -- GPS columns...
);
```

**Frontend logic:**
```dart
// CEO/Manager check-in
await checkIn(
  userId: auth.currentUser.id,  // From Supabase Auth
  employeeId: null,
  ...
);

// Staff check-in
await checkIn(
  userId: null,
  employeeId: currentEmployee.id,  // From employees table
  ...
);
```

### Option 2: Unified user_id (Cleaner)
```sql
-- Add employee_id to public.users table
ALTER TABLE users ADD COLUMN employee_id UUID REFERENCES employees(id);

-- Attendance chỉ dùng user_id
CREATE TABLE attendance (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),  -- Links to unified users
  ...
);
```

**Frontend logic:**
```dart
// Cả CEO lẫn Staff đều có user_id
await checkIn(
  userId: currentUser.id,  // From public.users (not auth.users)
  ...
);
```

## 🎯 KHUYẾN NGHỊ:

**Dựa trên database hiện tại của bạn:**

1. ✅ **public.users** có 11 records (CEO/Manager)
2. ✅ **employees** có 4 records (Staff) với username/password_hash
3. ✅ **attendance** đang dùng user_id

**→ BẠN ĐANG DÙNG HYBRID MODEL**

Giải pháp tốt nhất:

```sql
-- Add employee_id to attendance (optional, nullable)
ALTER TABLE attendance 
ADD COLUMN employee_id UUID REFERENCES employees(id);

-- Populate for existing staff attendance
-- (nếu có data staff đã check-in)

-- Create view để query dễ
CREATE VIEW attendance_with_details AS
SELECT 
  a.*,
  COALESCE(u.full_name, e.full_name) as person_name,
  COALESCE(u.role, e.role) as person_role
FROM attendance a
LEFT JOIN users u ON a.user_id = u.id
LEFT JOIN employees e ON a.employee_id = e.id;
```

## ✅ KẾT LUẬN:

**Nếu bạn TẮT email auth trên Supabase:**
- CEO/Manager vẫn có thể dùng email auth (optional)
- Staff dùng username/password (custom)
- Attendance cần support CẢ HAI: user_id VÀ employee_id

**BẠN MUỐN TÔI TẠO MIGRATION ĐỂ ADD employee_id VÀO ATTENDANCE KHÔNG?** 🔧
