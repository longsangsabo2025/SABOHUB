# Hướng dẫn Deploy Tính năng Chấm Công

## 📋 Checklist trước khi deploy

### 1. Database Migration

Chạy migration để đảm bảo cấu trúc database đúng:

```sql
-- Chạy file này trong Supabase SQL Editor:
supabase/migrations/20251104_attendance_real_data.sql
```

Migration này sẽ:
- ✅ Tạo bảng `attendance` (nếu chưa có)
- ✅ Thêm cột `company_id` vào bảng `users` (nếu chưa có)
- ✅ Tạo indexes để tăng performance
- ✅ Thiết lập RLS policies
- ✅ Tạo trigger tự động tính `total_hours`

### 2. Kiểm tra Dependencies

Đảm bảo các packages đã được cài đặt:

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  supabase_flutter: ^2.0.0
  intl: ^0.18.0
```

### 3. Test trên môi trường Development

```bash
# 1. Chạy ứng dụng
flutter run -d chrome

# 2. Kiểm tra trang chi tiết công ty
# 3. Click vào tab "Chấm công"
# 4. Verify dữ liệu hiển thị từ Supabase (không phải mock data)
```

## 🚀 Các bước Deploy

### Bước 1: Push code lên repository

```bash
git add .
git commit -m "feat: integrate real attendance data from Supabase"
git push origin master
```

### Bước 2: Chạy migration trên Production

Vào Supabase Dashboard → SQL Editor → Run migration:

```sql
-- Paste nội dung file: supabase/migrations/20251104_attendance_real_data.sql
```

### Bước 3: Verify trên Production

1. Kiểm tra bảng `attendance` đã được tạo
2. Kiểm tra `users` có cột `company_id`
3. Kiểm tra RLS policies đã được apply
4. Test query:

```sql
-- Test query như trong app
SELECT 
  a.id,
  a.check_in,
  a.check_out,
  a.total_hours,
  a.is_late,
  u.name as user_name,
  u.company_id,
  s.name as store_name
FROM attendance a
JOIN users u ON u.id = a.user_id
JOIN stores s ON s.id = a.store_id
WHERE u.company_id = 'YOUR_COMPANY_ID'
  AND a.check_in >= CURRENT_DATE
ORDER BY a.check_in DESC
LIMIT 10;
```

### Bước 4: Deploy app

```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Bước 5: Tạo dữ liệu test (nếu cần)

Nếu chưa có dữ liệu chấm công, tạo một số bản ghi test:

```sql
-- Sample attendance data
INSERT INTO attendance (user_id, store_id, check_in, check_out, is_late)
SELECT 
  u.id,
  s.id,
  CURRENT_DATE + TIME '08:00:00',
  CURRENT_DATE + TIME '17:00:00',
  false
FROM users u
CROSS JOIN stores s
WHERE u.company_id IS NOT NULL
  AND s.company_id = u.company_id
LIMIT 5;

-- Thêm vài bản ghi đi muộn
INSERT INTO attendance (user_id, store_id, check_in, is_late)
SELECT 
  u.id,
  s.id,
  CURRENT_DATE + TIME '08:30:00',
  true
FROM users u
CROSS JOIN stores s
WHERE u.company_id IS NOT NULL
  AND s.company_id = u.company_id
LIMIT 2;
```

## 🧪 Testing

### Test Case 1: Xem danh sách chấm công

1. Login với tài khoản CEO/Manager
2. Vào trang chi tiết công ty
3. Click tab "Chấm công"
4. **Expected:** Hiển thị danh sách chấm công của nhân viên trong công ty

### Test Case 2: Filter theo ngày

1. Ở tab chấm công
2. Click vào date picker
3. Chọn ngày khác
4. **Expected:** Danh sách cập nhật theo ngày đã chọn

### Test Case 3: Filter theo trạng thái

1. Ở tab chấm công
2. Chọn filter "Đi muộn"
3. **Expected:** Chỉ hiển thị nhân viên đi muộn

### Test Case 4: Search nhân viên

1. Ở tab chấm công
2. Nhập tên nhân viên vào search box
3. **Expected:** Danh sách lọc theo tên

### Test Case 5: Xem chi tiết

1. Click vào menu (⋮) của một bản ghi
2. Chọn "Xem chi tiết"
3. **Expected:** Dialog hiển thị thông tin chi tiết

### Test Case 6: Thống kê

1. Kiểm tra các card thống kê ở trên
2. **Expected:** Hiển thị đúng số liệu:
   - Tổng số nhân viên
   - Số có mặt
   - Số đi muộn
   - Số vắng
   - Tỷ lệ chấm công

## 🔐 Security Checklist

- ✅ RLS policies đã được enable
- ✅ CEO/Manager chỉ xem được attendance trong công ty họ
- ✅ Staff chỉ xem được attendance của chính họ
- ✅ Chỉ CEO/Manager mới được xóa attendance
- ✅ Users có thể check-in/check-out cho chính họ

## 📊 Performance

### Indexes đã được tạo:

- `idx_attendance_user_id` - Query theo user
- `idx_attendance_store_id` - Query theo store
- `idx_attendance_check_in` - Query theo ngày
- `idx_attendance_user_date` - Composite index cho common queries
- `idx_users_company_id` - JOIN với users

### Optimization tips:

1. **Limit kết quả:** Provider đã limit theo ngày để tránh load quá nhiều dữ liệu
2. **Pagination:** Có thể thêm pagination nếu có nhiều nhân viên
3. **Caching:** Riverpod tự động cache kết quả

## 🐛 Troubleshooting

### Lỗi: "No attendance data"

**Nguyên nhân:** Chưa có dữ liệu trong bảng attendance

**Giải pháp:**
1. Tạo dữ liệu test (xem Bước 5)
2. Hoặc dùng tính năng check-in trong app

### Lỗi: "Permission denied"

**Nguyên nhân:** RLS policy chưa được setup đúng

**Giải pháp:**
1. Chạy lại migration
2. Verify policies:

```sql
SELECT * FROM pg_policies WHERE tablename = 'attendance';
```

### Lỗi: "company_id column does not exist"

**Nguyên nhân:** Bảng users chưa có cột company_id

**Giải pháp:**
```sql
ALTER TABLE public.users 
ADD COLUMN company_id UUID REFERENCES public.companies(id);
```

### Lỗi: "Cannot query across foreign key"

**Nguyên nhân:** Foreign key relationships chưa đúng

**Giải pháp:**
1. Verify relationships:

```sql
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
WHERE tc.table_name = 'attendance';
```

## 📝 Monitoring

### Queries để monitor:

```sql
-- Số lượng attendance hôm nay
SELECT COUNT(*) 
FROM attendance 
WHERE check_in >= CURRENT_DATE;

-- Top companies có nhiều attendance nhất
SELECT 
  c.name,
  COUNT(a.id) as attendance_count
FROM companies c
JOIN users u ON u.company_id = c.id
JOIN attendance a ON a.user_id = u.id
WHERE a.check_in >= CURRENT_DATE
GROUP BY c.id, c.name
ORDER BY attendance_count DESC
LIMIT 10;

-- Tỷ lệ đi muộn theo công ty
SELECT 
  c.name,
  COUNT(a.id) as total,
  SUM(CASE WHEN a.is_late THEN 1 ELSE 0 END) as late_count,
  ROUND(SUM(CASE WHEN a.is_late THEN 1 ELSE 0 END)::numeric / COUNT(a.id) * 100, 2) as late_rate
FROM companies c
JOIN users u ON u.company_id = c.id
JOIN attendance a ON a.user_id = u.id
WHERE a.check_in >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY c.id, c.name
HAVING COUNT(a.id) > 0
ORDER BY late_rate DESC;
```

## ✅ Post-deployment Verification

1. ✅ Migration đã chạy thành công
2. ✅ RLS policies hoạt động đúng
3. ✅ App load được dữ liệu từ Supabase
4. ✅ Filter và search hoạt động
5. ✅ Thống kê hiển thị đúng
6. ✅ Performance acceptable (< 2s load time)

## 📞 Support

Nếu gặp vấn đề, check:

1. File documentation: `ATTENDANCE-TAB-REAL-DATA-COMPLETE.md`
2. Test script: `test_attendance_integration.py`
3. Migration file: `supabase/migrations/20251104_attendance_real_data.sql`

---

**Last updated:** 2025-11-04
**Status:** ✅ Ready for deployment
