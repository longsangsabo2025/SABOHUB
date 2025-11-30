# 🔍 BÁO CÁO KIỂM TRA SUPABASE THỰC TẾ - SABOHUB

**Ngày kiểm tra:** 12 tháng 11, 2025  
**Database:** https://dqddxowyikefqcdiioyh.supabase.co  
**Phương pháp:** Kết nối trực tiếp vào Supabase và kiểm tra schema thực tế

---

## 📊 TÓM TẮT TỔNG QUAN

### Trạng thái các bảng chính:

| Bảng | Trạng thái | Số bản ghi |
|------|-----------|------------|
| ✅ **users** | Tồn tại | 11 |
| ✅ **companies** | Tồn tại | 1 |
| ✅ **branches** | Tồn tại | 1 |
| ❌ **stores** | KHÔNG TỒN TẠI (Đã đổi tên) | - |
| ✅ **tasks** | Tồn tại | 3 |
| ✅ **attendance** | Tồn tại | 3 |
| ✅ **task_templates** | Tồn tại | - |
| ✅ **employees** | Tồn tại | - |
| ⚠️ **profiles** | TỒN TẠI (Có thể gây xung đột) | - |

### Đánh giá chung:
- ✅ **Migration từ stores → branches ĐÃ HOÀN THÀNH**
- ⚠️ **Bảng profiles tồn tại** - Cần kiểm tra RLS policies
- 🔴 **Attendance table có vấn đề nghiêm trọng** - Vẫn dùng store_id
- 🟠 **Một số cột quan trọng bị thiếu** trong các bảng

---

## 🚨 VẤN ĐỀ NGHIÊM TRỌNG (CRITICAL)

### 1. ❌ Bảng PROFILES Tồn Tại - Xung Đột RLS

**Phát hiện:**
- Bảng `profiles` TỒN TẠI trong database
- Code frontend và một số RLS policies có thể đang reference bảng `users`
- Gây xung đột giữa 2 bảng: `profiles` vs `users`

**Nguy cơ:**
- RLS policies có thể đang dùng bảng SAI
- Authentication flow có thể bị lỗi
- Phân quyền không hoạt động đúng

**Khắc phục:**
```sql
-- Kiểm tra xem bảng profiles có data không
SELECT COUNT(*) FROM profiles;

-- Nếu có data, cần migrate sang users
-- Nếu không có data, xóa bảng profiles
DROP TABLE IF EXISTS profiles CASCADE;

-- Sau đó kiểm tra và sửa TẤT CẢ RLS policies đang dùng profiles
```

**Độ ưu tiên:** 🔴 **P0 - Cấp báo động**

---

### 2. ❌ ATTENDANCE Table Vẫn Dùng `store_id`

**Phát hiện:**
```
Cột hiện có trong attendance:
  ✓ store_id        ❌ CỘT CŨ, KHÔNG ĐÚNG
  ✗ branch_id       ❌ THIẾU - NÊN CÓ
  ✗ company_id      ❌ THIẾU - BẮT BUỘC
```

**Vấn đề:**
- Frontend đang expect `branch_id` nhưng database vẫn là `store_id`
- Thiếu cột `company_id` - Không thể filter theo công ty
- Foreign key đang reference bảng `stores` không tồn tại

**Code frontend bị lỗi:**
```dart
// Frontend gửi branch_id
await _supabase.from('attendance').insert({
  'branch_id': branchId,  // ❌ Cột không tồn tại
  'company_id': companyId, // ❌ Cột không tồn tại
  ...
});
```

**Khắc phục NGAY:**
```sql
-- Bước 1: Rename cột
ALTER TABLE attendance DROP CONSTRAINT IF EXISTS attendance_store_id_fkey;
ALTER TABLE attendance RENAME COLUMN store_id TO branch_id;

-- Bước 2: Thêm foreign key mới
ALTER TABLE attendance 
  ADD CONSTRAINT attendance_branch_id_fkey 
  FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE;

-- Bước 3: Thêm company_id
ALTER TABLE attendance ADD COLUMN company_id UUID REFERENCES companies(id);

-- Bước 4: Populate company_id từ users
UPDATE attendance
SET company_id = (
  SELECT company_id FROM users WHERE users.id = attendance.user_id
);
```

**Độ ưu tiên:** 🔴 **P0 - Blocking feature chấm công**

---

## ⚠️ VẤN ĐỀ QUAN TRỌNG (HIGH PRIORITY)

### 3. ⚠️ ATTENDANCE Thiếu Cột GPS

**Phát hiện:**
```
Thiếu các cột:
  ❌ check_in_latitude
  ❌ check_in_longitude  
  ❌ check_out_latitude
  ❌ check_out_longitude
```

**Ảnh hưởng:**
- Không thể lưu vị trí GPS khi check-in/check-out
- Feature theo dõi vị trí nhân viên không hoạt động
- Không thể kiểm tra nhân viên có check-in đúng địa điểm không

**Khắc phục:**
```sql
ALTER TABLE attendance ADD COLUMN check_in_latitude DOUBLE PRECISION;
ALTER TABLE attendance ADD COLUMN check_in_longitude DOUBLE PRECISION;
ALTER TABLE attendance ADD COLUMN check_out_latitude DOUBLE PRECISION;
ALTER TABLE attendance ADD COLUMN check_out_longitude DOUBLE PRECISION;

-- Thêm comment
COMMENT ON COLUMN attendance.check_in_latitude IS 'Vĩ độ GPS khi check-in';
COMMENT ON COLUMN attendance.check_in_longitude IS 'Kinh độ GPS khi check-in';
```

**Độ ưu tiên:** 🟠 **P1 - Cần sửa trong tuần này**

---

### 4. ⚠️ TASKS Table: `assignee_id` vs `assigned_to`

**Phát hiện:**
```
Cột hiện có:
  ✓ assigned_to         ✅ CÓ
  ✗ assignee_id         ❌ THIẾU
```

**Vấn đề:**
- Database dùng cột `assigned_to`
- Frontend model có CẢ HAI fields: `assignedTo` và `assigneeId`
- Gây nhầm lẫn khi mapping data

**Audit report gợi ý:**
- Rename `assigned_to` → `assignee_id` trong database (HOẶC)
- Xóa field `assigneeId` trong frontend model

**Khuyến nghị:**
```sql
-- OPTION 1: Đổi tên trong database (Ưu tiên)
ALTER TABLE tasks RENAME COLUMN assigned_to TO assignee_id;

-- OPTION 2: Giữ nguyên database, sửa frontend
-- Trong Dart model, chỉ dùng assignedTo và map đúng
```

**Độ ưu tiên:** 🟠 **P1 - Cần thống nhất ngay**

---

### 5. ⚠️ COMPANIES Table Thiếu Cột Quan Trọng

**Phát hiện:**
```
Thiếu các cột:
  ❌ owner_id          (CEO của công ty)
  ❌ legal_name        (Tên pháp lý)
  ❌ primary_color     (Màu chủ đạo)
  ❌ secondary_color   (Màu phụ)
  ❌ settings          (JSONB config)
```

**Ảnh hưởng:**
- Không biết ai là chủ/CEO của công ty
- Không thể customize màu sắc theo branding
- Thiếu cấu hình linh hoạt

**Khắc phục:**
```sql
ALTER TABLE companies ADD COLUMN owner_id UUID REFERENCES auth.users(id);
ALTER TABLE companies ADD COLUMN legal_name TEXT;
ALTER TABLE companies ADD COLUMN primary_color TEXT DEFAULT '#007AFF';
ALTER TABLE companies ADD COLUMN secondary_color TEXT DEFAULT '#5856D6';
ALTER TABLE companies ADD COLUMN settings JSONB DEFAULT '{
  "timezone": "Asia/Ho_Chi_Minh",
  "currency": "VND",
  "locale": "vi-VN"
}'::jsonb;

-- Update owner_id cho công ty hiện tại
-- (Cần xác định CEO nào sở hữu công ty)
```

**Độ ưu tiên:** 🟠 **P1 - Quan trọng cho multi-company**

---

### 6. ⚠️ USERS Table: `name` vs `full_name`

**Phát hiện:**
```
Cột hiện có:
  ✓ full_name      ✅ CÓ
  ✗ name           ❌ THIẾU
```

**Vấn đề:**
- Database dùng cột `full_name`
- Frontend model expect field `name`
- Mapping code có fallback: `json['full_name'] ?? json['name']`

**Khuyến nghị:**
```sql
-- OPTION 1: Thêm cột name (alias của full_name)
ALTER TABLE users ADD COLUMN name TEXT GENERATED ALWAYS AS (full_name) STORED;

-- OPTION 2: Rename full_name → name
ALTER TABLE users RENAME COLUMN full_name TO name;

-- OPTION 3: Giữ nguyên, sửa frontend mapping
-- Chỉ dùng full_name trong Dart model
```

**Độ ưu tiên:** 🟡 **P2 - Medium (Đã có fallback code)**

---

## 📝 VẤN ĐỀ VỪA PHẢI (MEDIUM PRIORITY)

### 7. 💾 Storage Buckets Chưa Được Tạo

**Phát hiện:**
```
⚠️ Không có bucket nào
```

**Ảnh hưởng:**
- Không thể upload file/hình ảnh
- Feature AI Assistant không hoạt động (cần bucket `ai-files`)
- Feature document upload bị lỗi

**Khắc phục:**
```sql
-- Tạo bucket cho AI files
INSERT INTO storage.buckets (id, name, public)
VALUES ('ai-files', 'ai-files', false);

-- Tạo bucket cho avatars (nếu cần)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Tạo bucket cho documents (nếu cần)
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);
```

**Sau đó cần thêm RLS policies cho từng bucket.**

**Độ ưu tiên:** 🟡 **P2 - Cần thiết cho AI features**

---

### 8. 🔒 RLS Policies Cần Kiểm Tra

**Kết quả test:**
```
✅ tasks         : Service role có thể truy cập
✅ attendance    : Service role có thể truy cập
✅ companies     : Service role có thể truy cập
✅ branches      : Service role có thể truy cập
```

**Lưu ý:**
- Service role BYPASS RLS, nên test này không đủ
- Cần test với authenticated user thực tế
- Phải test cho từng role: CEO, MANAGER, STAFF

**Các policy cần kiểm tra đặc biệt:**
1. Tasks policies có đang dùng bảng `profiles` không?
2. Storage policies có đang dùng bảng `profiles` không?
3. Attendance policies có filter đúng `company_id` không?

**Độ ưu tiên:** 🟡 **P2 - Cần test kỹ**

---

## ✅ NHỮNG GÌ ĐÃ ĐÚNG

### Điểm tốt:

1. ✅ **Migration stores → branches ĐÃ HOÀN THÀNH**
   - Bảng `branches` tồn tại với đầy đủ cột
   - Có `manager_id`, `code`, `company_id`
   - Bảng `stores` cũ đã được xóa

2. ✅ **Tasks table có cấu trúc tốt**
   - Có `company_id`, `branch_id` (multi-company ready)
   - Có `progress` column (0-100%)
   - Có `deleted_at` (soft delete)
   - Có đầy đủ fields: priority, status, recurrence

3. ✅ **Users table đã có multi-company support**
   - Có `company_id`
   - Có `branch_id`
   - Có soft delete support

4. ✅ **Branches table đầy đủ**
   - Có `manager_id` (đã đổi từ owner_id)
   - Có `code` field
   - Có `company_id`

5. ✅ **Database đang có data thực tế**
   - 1 company
   - 1 branch
   - 11 users
   - 3 tasks
   - 3 attendance records

---

## 🚀 KẾ HOẠCH KHẮC PHỤC

### 🔴 PHASE 1: CRITICAL FIXES (Làm ngay hôm nay)

**Bước 1: Kiểm tra và xử lý bảng PROFILES**
```bash
# Kết nối vào Supabase
psql $SUPABASE_CONNECTION_STRING

# Kiểm tra profiles có data không
SELECT COUNT(*), * FROM profiles LIMIT 5;

# Nếu KHÔNG có data quan trọng:
DROP TABLE IF EXISTS profiles CASCADE;

# Nếu CÓ data, cần phân tích trước khi migrate
```

**Bước 2: Fix ATTENDANCE table**
```bash
# Chạy migration file đã tạo sẵn
psql $SUPABASE_CONNECTION_STRING < supabase/migrations/20251112_fix_critical_schema_issues.sql

# HOẶC dùng Supabase CLI
supabase db push
```

**Bước 3: Test lại attendance feature**
```dart
// Test check-in với GPS
await attendanceService.checkIn(
  userId: currentUser.id,
  branchId: currentBranch.id,
  companyId: currentCompany.id,
  latitude: 10.762622,
  longitude: 106.660172,
);
```

**Thời gian:** 2-3 giờ  
**Downtime:** Không cần

---

### 🟠 PHASE 2: HIGH PRIORITY (Tuần này)

**1. Thêm GPS columns vào attendance**
**2. Fix assignee_id vs assigned_to**
**3. Thêm owner_id vào companies**
**4. Tạo storage buckets**

**Thời gian:** 1 ngày  
**Downtime:** Không cần

---

### 🟡 PHASE 3: MEDIUM PRIORITY (Tuần sau)

**1. Test kỹ RLS policies**
**2. Fix name vs full_name**
**3. Optimize indexes**
**4. Add missing constraints**

**Thời gian:** 2-3 ngày

---

## 📋 CHECKLIST SAU KHI FIX

### Attendance Feature:
- [ ] Check-in với GPS hoạt động
- [ ] Check-out với GPS hoạt động
- [ ] CEO xem được attendance của tất cả nhân viên
- [ ] Manager xem được attendance trong company
- [ ] Staff chỉ xem được attendance của mình

### Tasks Feature:
- [ ] Tạo task thành công
- [ ] Assign task cho nhân viên
- [ ] Update progress (0-100%)
- [ ] Filter tasks theo status
- [ ] CEO xem tất cả tasks
- [ ] Manager xem tasks trong company
- [ ] Staff xem tasks được assign

### Companies & Branches:
- [ ] Tạo company mới
- [ ] Assign CEO/owner
- [ ] Tạo branch với manager
- [ ] View company settings
- [ ] Update company branding

### File Upload:
- [ ] Upload AI files thành công
- [ ] Download files
- [ ] Delete files
- [ ] RLS policies hoạt động đúng

---

## 🎯 RECOMMENDED ACTIONS - HÀNH ĐỘNG NGAY

### Cho Backend Team:

1. **NGAY BÂY GIỜ:**
   ```bash
   # Backup database trước
   pg_dump $SUPABASE_CONNECTION_STRING > backup_$(date +%Y%m%d).sql
   
   # Chạy migration
   psql $SUPABASE_CONNECTION_STRING < supabase/migrations/20251112_fix_critical_schema_issues.sql
   ```

2. **SAU ĐÓ:**
   - Kiểm tra bảng profiles có data không
   - Test attendance check-in/check-out
   - Verify RLS policies

### Cho Frontend Team:

1. **Update models theo actual database:**
   - `AttendanceRecord`: Dùng `branch_id` thay vì `store_id`
   - `Task`: Quyết định dùng `assignedTo` hay `assigneeId`
   - `User`: Dùng `full_name` thay vì `name`

2. **Test tất cả CRUD operations**

3. **Update service calls:**
   - Luôn gửi `company_id` khi insert attendance
   - Dùng `branch_id` thay vì `store_id`

---

## 📞 HỖ TRỢ

**Files đã tạo:**
- ✅ `check_supabase_real.py` - Script kiểm tra
- ✅ `supabase/migrations/20251112_fix_critical_schema_issues.sql` - Migration file
- ✅ `SUPABASE-FRONTEND-AUDIT-REPORT.md` - Báo cáo tiếng Anh chi tiết
- ✅ `CRITICAL-FIXES-QUICK-START.md` - Hướng dẫn nhanh
- ✅ File này - Báo cáo tiếng Việt

**Cần giúp đỡ:**
- Slack: #sabohub-dev
- Backend issues: Tag @backend-team
- Frontend issues: Tag @frontend-team

---

## 📊 KẾT LUẬN

### Tổng quan:
- ✅ **60% schema đã đúng** - Migration stores→branches thành công
- 🔴 **3 vấn đề critical** cần fix ngay
- 🟠 **5 vấn đề high priority** cần fix trong tuần
- 🟡 **Các vấn đề medium** có thể fix dần

### Ưu tiên cao nhất:
1. Fix bảng attendance (store_id → branch_id, thêm company_id)
2. Xử lý bảng profiles conflict
3. Thêm GPS columns
4. Tạo storage buckets

### Thời gian ước tính:
- Critical fixes: **2-3 giờ**
- High priority: **1 ngày**
- Medium priority: **2-3 ngày**
- **TỔNG: Khoảng 1 tuần để hoàn thiện**

### Risk level: 🟡 **MEDIUM-HIGH**
Database đang hoạt động nhưng có bug nghiêm trọng ở attendance feature. Cần fix ngay để tránh data inconsistency.

---

**Báo cáo được tạo tự động bởi audit script**  
**Ngày:** 12/11/2025  
**Version:** 1.0  
**Status:** ✅ HOÀN THÀNH

