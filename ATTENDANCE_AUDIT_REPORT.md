# AUDIT BÁO CÁO: TÍNH NĂNG CHẤM CÔNG (ATTENDANCE)
**Ngày audit:** 13/11/2025
**Người thực hiện:** AI Assistant

---

## 1. TỔNG QUAN KIẾN TRÚC

### Database Schema
✅ **Table: `attendance`**
- Primary key: `id` (UUID)
- Foreign keys:
  - `user_id` → `auth.users(id)` ✅
  - `branch_id` → `branches(id)` ✅  
  - `company_id` → `companies(id)` ✅
  - `shift_id` → `shifts(id)` (optional)

### Cấu trúc dữ liệu chính:
```sql
- id UUID
- user_id UUID (NOT NULL)
- branch_id UUID (NOT NULL) 
- company_id UUID (NOT NULL)
- shift_id UUID (nullable)
- check_in TIMESTAMPTZ
- check_out TIMESTAMPTZ
- check_in_location TEXT
- check_out_location TEXT
- check_in_latitude DECIMAL
- check_in_longitude DECIMAL
- check_out_latitude DECIMAL
- check_out_longitude DECIMAL
- check_in_photo_url TEXT
- total_hours DECIMAL(5,2)
- is_late BOOLEAN
- is_early_leave BOOLEAN
- notes TEXT
- employee_name TEXT (cached)
- employee_role TEXT (cached)
- created_at TIMESTAMPTZ
- deleted_at TIMESTAMPTZ (soft delete)
```

---

## 2. PHÂN TÍCH TÍNH NĂNG

### ✅ Tính năng đã triển khai:

1. **Check-in (Chấm công vào)**
   - GPS location tracking ✅
   - Photo capture support ✅
   - Validation location trong radius ✅
   - Auto-populate employee info ✅

2. **Check-out (Chấm công ra)**
   - GPS location tracking ✅
   - Auto-calculate total hours ✅
   - Update attendance record ✅

3. **Xem lịch sử chấm công**
   - User xem chấm công của mình ✅
   - Manager/CEO xem tất cả trong company ✅
   - Filter by date range ✅

4. **Quản lý chấm công**
   - Manager/CEO có thể update ✅
   - Manager/CEO có thể delete ✅
   - Soft delete support ✅

---

## 3. VẤN ĐỀ CẦN FIX

### 🔴 CRITICAL ISSUES

#### 3.1. Schema Mismatch (CRITICAL)
**Vấn đề:** Có 2 schema khác nhau đang được dùng:
- **Old schema:** `store_id` (trong migration cũ)
- **New schema:** `branch_id`, `company_id` (trong code hiện tại)

**File affected:**
- `supabase/migrations/20251104_attendance_real_data.sql` - Dùng `store_id`
- `lib/services/attendance_service.dart` - Dùng `branch_id`, `company_id`

**Impact:** 
- Code sẽ fail khi check-in vì thiếu column `branch_id`, `company_id`
- Database có column `store_id` nhưng code không dùng

**Fix:** Chạy migration mới để:
```sql
ALTER TABLE attendance DROP COLUMN store_id;
ALTER TABLE attendance ADD COLUMN branch_id UUID REFERENCES branches(id);
ALTER TABLE attendance ADD COLUMN company_id UUID REFERENCES companies(id);
```

#### 3.2. RLS Policy Issues
**Vấn đề:** RLS policies có logic phức tạp với subquery:
```sql
users.company_id = (
  SELECT company_id FROM public.users WHERE id = attendance.user_id
)
```

**Risk:** Performance issue với nhiều records

**Fix:** Đơn giản hóa bằng cách dùng trực tiếp `attendance.company_id`:
```sql
users.company_id = attendance.company_id
```

#### 3.3. Missing Validation
**Vấn đề:** 
- ❌ Không validate user đã check-in chưa (có thể check-in 2 lần/ngày)
- ❌ Không validate must check-in before check-out
- ❌ Không validate location radius

**Fix:** Add validation trong service:
```dart
// Before check-in
final existing = await getTodayAttendance(userId);
if (existing != null && existing.checkInTime != null) {
  throw Exception('Đã chấm công vào rồi!');
}

// Before check-out
if (existing == null || existing.checkInTime == null) {
  throw Exception('Chưa chấm công vào!');
}
if (existing.checkOutTime != null) {
  throw Exception('Đã chấm công ra rồi!');
}
```

#### 3.4. Data Inconsistency
**Vấn đề:** Có 2 model Attendance khác nhau:
- `lib/models/attendance.dart` - Full model với breaks, status
- `lib/providers/attendance_provider.dart` - Simple model

**Impact:** Confusion và data mapping sai

**Fix:** Xóa duplicate model, chỉ dùng 1 model duy nhất

---

### 🟡 MEDIUM ISSUES

#### 3.5. Missing Features
- ❌ Break time tracking (đang nghỉ giữa ca)
- ❌ Overtime calculation
- ❌ Late/Early leave auto-detection (based on shift)
- ❌ Attendance report/export
- ❌ Notification cho manager khi staff check-in/out

#### 3.6. Error Handling
**Vấn đề:** Service chỉ rethrow error, không có custom exception
```dart
} catch (e) {
  rethrow; // ❌ Không user-friendly
}
```

**Fix:** Custom exceptions:
```dart
class AttendanceException implements Exception {
  final String message;
  AttendanceException(this.message);
}

throw AttendanceException('Vui lòng bật GPS để chấm công');
```

#### 3.7. UI/UX Issues
- Mock data vẫn còn trong AttendanceProvider
- Attendance list page chưa kết nối với real service
- Missing loading states
- No offline support

---

### 🟢 LOW PRIORITY

#### 3.8. Code Quality
- Duplicate code giữa models
- Thiếu unit tests
- Thiếu documentation cho API
- Magic numbers (e.g., radius validation)

#### 3.9. Performance
- Missing pagination cho attendance list
- No caching cho today's attendance
- Có thể optimize RLS policies

---

## 4. DATABASE AUDIT

### Kiểm tra column tồn tại:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'attendance'
ORDER BY ordinal_position;
```

### Kiểm tra indexes:
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'attendance';
```

**Tìm thấy:**
- ✅ `idx_attendance_user_id`
- ✅ `idx_attendance_check_in`
- ✅ `idx_attendance_user_date`
- ❌ Missing: `idx_attendance_company_id`
- ❌ Missing: `idx_attendance_branch_id`

---

## 5. SECURITY AUDIT

### RLS Policies:
1. ✅ Enabled RLS
2. ✅ User can view own attendance
3. ✅ Manager/CEO can view company attendance
4. ✅ User can insert own attendance
5. ✅ User can update own attendance
6. ✅ Manager/CEO can update company attendance
7. ✅ Only Manager/CEO can delete

### Potential Security Issues:
- ⚠️ Location data không được encrypt
- ⚠️ Photo URLs có thể access public
- ⚠️ Không có rate limiting cho check-in API

---

## 6. ACTION ITEMS (PRIORITY ORDER)

### Priority 1 - CRITICAL (Phải fix ngay)
1. ✅ Fix schema mismatch (store_id → branch_id, company_id)
2. ✅ Add validation: prevent duplicate check-in
3. ✅ Add validation: must check-in before check-out
4. ✅ Remove duplicate Attendance models
5. ✅ Add missing indexes

### Priority 2 - HIGH (Fix trong tuần)
1. ⏳ Implement location radius validation
2. ⏳ Add auto late/early detection based on shift
3. ⏳ Implement break time tracking
4. ⏳ Add custom exceptions
5. ⏳ Connect UI to real service

### Priority 3 - MEDIUM (Fix trong tháng)
1. ⏳ Add attendance report/export
2. ⏳ Add notifications
3. ⏳ Implement overtime calculation
4. ⏳ Add pagination
5. ⏳ Add offline support

### Priority 4 - LOW (Nice to have)
1. ⏳ Add unit tests
2. ⏳ Improve documentation
3. ⏳ Add caching
4. ⏳ Optimize RLS policies
5. ⏳ Add analytics

---

## 7. MIGRATION SCRIPT CẦN CHẠY

```sql
-- Fix attendance table schema
DO $$ 
BEGIN
  -- Check if store_id exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance' AND column_name = 'store_id'
  ) THEN
    -- Drop store_id
    ALTER TABLE attendance DROP COLUMN IF EXISTS store_id CASCADE;
    RAISE NOTICE '✅ Dropped store_id column';
  END IF;
  
  -- Add branch_id if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance' AND column_name = 'branch_id'
  ) THEN
    ALTER TABLE attendance ADD COLUMN branch_id UUID REFERENCES branches(id);
    RAISE NOTICE '✅ Added branch_id column';
  END IF;
  
  -- Add company_id if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'attendance' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE attendance ADD COLUMN company_id UUID REFERENCES companies(id);
    RAISE NOTICE '✅ Added company_id column';
  END IF;
  
  -- Add missing location columns
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_latitude DECIMAL;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_longitude DECIMAL;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_latitude DECIMAL;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_longitude DECIMAL;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS employee_name TEXT;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS employee_role TEXT;
  ALTER TABLE attendance ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
  
  -- Add missing indexes
  CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON attendance(company_id);
  CREATE INDEX IF NOT EXISTS idx_attendance_branch_id ON attendance(branch_id);
  CREATE INDEX IF NOT EXISTS idx_attendance_deleted_at ON attendance(deleted_at) WHERE deleted_at IS NULL;
  
  RAISE NOTICE '✅ Attendance schema migration completed';
END $$;
```

---

## 8. KẾT LUẬN

### Tình trạng hiện tại: ⚠️ PARTIALLY WORKING

**Điểm mạnh:**
- ✅ Core functionality đã có (check-in/out)
- ✅ RLS policies đầy đủ
- ✅ GPS tracking support
- ✅ Soft delete support

**Điểm yếu:**
- ❌ Schema không nhất quán
- ❌ Thiếu validation
- ❌ Duplicate models
- ❌ Mock data chưa remove
- ❌ Chưa connect UI với real service

**Khuyến nghị:**
1. CRITICAL: Chạy migration fix schema ngay
2. HIGH: Add validation trong service
3. MEDIUM: Remove mock data và connect UI
4. Sau đó mới implement các feature mới

**Estimated effort:**
- Fix critical issues: 4-6 hours
- Fix high priority: 8-12 hours
- Complete medium priority: 2-3 days
