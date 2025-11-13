# ✅ DATABASE MỚI - EMPLOYEE RELATIONSHIPS CHECK

## Database Mới (dqddxowyikefqcdiioyh)

Theo xác nhận của bạn:
- ✅ Có 4 employees trong bảng `employees`

## 🔍 Cần Kiểm Tra Mối Quan Hệ

### 1. Foreign Keys FROM employees table

```sql
employees.company_id → companies.id
employees.branch_id → branches.id
employees.store_id → stores.id (nếu có)
```

**Câu hỏi:**
- ✅ 4 employees có `company_id` chưa?
- ✅ 4 employees có `branch_id` chưa?
- ❓ Field `store_id` có trong employees table không?

---

### 2. Foreign Keys TO employees table

#### attendance.user_id → employees.id
```sql
-- Foreign key name: attendance_user_id_fkey
-- Đã fix trong code: employees!attendance_user_id_fkey
```

**Cần check:**
- ❓ Foreign key `attendance_user_id_fkey` đã tồn tại chưa?
- ❓ Có attendance records nào chưa?

#### tasks.assigned_to
```sql
-- Tasks có thể assign cho cả CEO (users) hoặc Employees (employees)
-- Giải pháp: Sử dụng cached fields (assigned_to_name, assigned_to_role)
```

**Cần check:**
- ❓ Tasks có cached fields `assigned_to_name`, `assigned_to_role` chưa?
- ❓ Có tasks nào chưa?

#### employee_documents.employee_id → employees.id
```sql
-- Foreign key cho tài liệu của nhân viên
```

**Cần check:**
- ❓ Bảng `employee_documents` có tồn tại không?
- ❓ Foreign key đã setup chưa?

---

### 3. Các Bảng Khác

#### bookings (nếu có)
```sql
-- Nếu có booking system
bookings.employee_id → employees.id
```

#### shifts (nếu có)
```sql
-- Nếu có shift management
shifts.assigned_to → employees.id
```

---

## 🎯 CÁCH KIỂM TRA

### Method 1: Chạy App và Test (Khuyến nghị)

```bash
flutter run -d chrome
```

Sau đó kiểm tra:
1. Login bằng employee account
2. Check attendance tab (xem có data không)
3. Check tasks tab (xem có data không)
4. Xem console có lỗi foreign key không

### Method 2: SQL Direct Query

```sql
-- Check foreign keys
SELECT
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND (tc.table_name = 'employees' 
         OR ccu.table_name = 'employees')
ORDER BY tc.table_name;
```

### Method 3: Flutter Analyze Errors

```bash
flutter analyze
```

Nếu có lỗi foreign key, sẽ hiện khi query data.

---

## 📋 CHECKLIST HOÀN THIỆN

### Schema ✅ (Theo Migration)
- [x] employees table structure
- [x] company_id, branch_id foreign keys
- [x] attendance.user_id foreign key
- [x] tasks cached fields
- [ ] **CẦN XÁC NHẬN: Foreign keys đã setup trong database mới chưa?**

### Data ✅
- [x] 4 employees tồn tại

### Foreign Keys ❓
- [ ] attendance_user_id_fkey → employees.id
- [ ] employee_documents.employee_id → employees.id
- [ ] Các foreign keys khác

### RLS Policies ❓
- [ ] Employees RLS
- [ ] Attendance RLS
- [ ] Tasks RLS

---

## 💡 HÀNH ĐỘNG TIẾP THEO

1. **Chạy app và test:**
   ```bash
   flutter run -d chrome
   ```

2. **Login bằng employee account**

3. **Check console logs** - Xem có lỗi foreign key không

4. **Nếu có lỗi:**
   - Tạo foreign keys thiếu
   - Update RLS policies
   - Fix code nếu cần

5. **Nếu không lỗi:**
   - ✅ Database relationships hoàn thiện 100%!

---

## ❓ CÂU HỎI CHO BẠN

1. **4 employees có data đầy đủ không?**
   - full_name ✓
   - role ✓
   - company_id ✓
   - branch_id ✓
   - email ✓
   - password_hash ✓

2. **Có tables nào khác liên quan đến employees không?**
   - attendance?
   - tasks?
   - employee_documents?
   - shifts?
   - bookings?

3. **Bạn có thể login bằng employee account không?**
   - Nếu được → Auth hoạt động
   - Nếu không → Cần check RPC function

---

**Bạn có muốn tôi chạy app và test để kiểm tra mối quan hệ không?** 🚀
