# 📋 TÓM TẮT NHANH - SUPABASE AUDIT

## 🎯 KẾT QUẢ KIỂM TRA

### ✅ ĐÚNG (60%):
- Bảng `branches` đã được đổi tên từ `stores` ✅
- Có đầy đủ 11 users, 1 company, 1 branch
- Tasks table có cấu trúc tốt với progress, soft delete
- Multi-company architecture đã được implement

### ❌ SAI - CẦN FIX NGAY (40%):

#### 1. 🔴 CRITICAL: Attendance table sai hoàn toàn
```
❌ Vẫn dùng store_id (phải là branch_id)
❌ Thiếu company_id
❌ Thiếu 4 cột GPS (latitude/longitude)
```
**Ảnh hưởng:** Feature chấm công KHÔNG hoạt động

#### 2. 🔴 CRITICAL: Bảng `profiles` tồn tại
```
⚠️ Có thể xung đột với bảng users
⚠️ RLS policies đang reference sai bảng
```
**Ảnh hưởng:** Phân quyền có thể bị lỗi

#### 3. 🟠 HIGH: Companies thiếu cột
```
❌ Thiếu owner_id (không biết ai là CEO)
❌ Thiếu legal_name, primary_color, secondary_color, settings
```

#### 4. 🟠 HIGH: Tasks có 2 cột trùng
```
⚠️ Có assigned_to nhưng không có assignee_id
⚠️ Frontend expect assigneeId
```

#### 5. 🟡 MEDIUM: Storage buckets chưa tạo
```
❌ Không có bucket nào
❌ Không thể upload file
```

---

## 🚀 CÁCH FIX (2 BƯỚC)

### BƯỚC 1: Chạy migration tự động (5 phút)

```bash
# Option 1: Dùng script Python
python run_migration.py

# Option 2: Dùng psql thủ công
psql $SUPABASE_CONNECTION_STRING < supabase/migrations/20251112_fix_critical_schema_issues.sql
```

**Migration này sẽ:**
- ✅ Đổi `store_id` → `branch_id` trong attendance
- ✅ Thêm `company_id` và GPS columns
- ✅ Fix tất cả RLS policies (profiles → users)
- ✅ Thêm các cột thiếu vào companies, branches

### BƯỚC 2: Update code frontend

#### File `lib/models/attendance.dart`:
```dart
class AttendanceRecord {
  final String? branchId;           // ✅ ĐỔI TÊN từ storeId
  final String companyId;            // ✅ THÊM MỚI
  final double? checkInLatitude;    // ✅ THÊM MỚI
  final double? checkInLongitude;   // ✅ THÊM MỚI
  final double? checkOutLatitude;   // ✅ THÊM MỚI
  final double? checkOutLongitude;  // ✅ THÊM MỚI
  ...
}
```

#### File `lib/services/attendance_service.dart`:
```dart
// ✅ ĐỔI TÊN parameter
Future<AttendanceRecord> checkIn({
  required String branchId,    // was: storeId
  required String companyId,   // THÊM MỚI
  double? latitude,            // THÊM MỚI
  double? longitude,           // THÊM MỚI
  ...
}) {
  return _supabase.from('attendance').insert({
    'branch_id': branchId,
    'company_id': companyId,
    'check_in_latitude': latitude,
    'check_in_longitude': longitude,
    ...
  });
}
```

---

## 📊 TRƯỚC VÀ SAU

### TRƯỚC (❌ Lỗi):
```dart
// Attendance check-in BỊ LỖI
await supabase.from('attendance').insert({
  'store_id': storeId,      // ❌ Cột không tồn tại
  'branch_id': branchId,    // ❌ Cột không tồn tại trong DB
});
// → Error: column "branch_id" does not exist
```

### SAU (✅ Hoạt động):
```dart
// Attendance check-in HOẠT ĐỘNG
await supabase.from('attendance').insert({
  'branch_id': branchId,       // ✅ Đã đổi tên
  'company_id': companyId,     // ✅ Đã thêm
  'check_in_latitude': lat,    // ✅ Đã thêm
  'check_in_longitude': lng,   // ✅ Đã thêm
});
// → Success!
```

---

## ⏱️ THỜI GIAN

| Task | Thời gian | Priority |
|------|-----------|----------|
| Chạy migration | 5 phút | 🔴 Ngay |
| Update Dart models | 30 phút | 🔴 Ngay |
| Update services | 1 giờ | 🔴 Ngay |
| Test tất cả features | 2 giờ | 🟠 Hôm nay |
| Tạo storage buckets | 30 phút | 🟡 Tuần này |

**TỔNG: Khoảng 4-5 giờ để fix xong hết**

---

## 📁 FILES QUAN TRỌNG

1. **BAO-CAO-SUPABASE-THUC-TE.md** ← Đọc file này để hiểu chi tiết
2. **run_migration.py** ← Chạy file này để fix database
3. **CRITICAL-FIXES-QUICK-START.md** ← Hướng dẫn từng bước
4. **supabase/migrations/20251112_fix_critical_schema_issues.sql** ← SQL migration

---

## ✅ CHECKLIST

### Ngay bây giờ:
- [ ] Backup database (quan trọng!)
- [ ] Chạy `python run_migration.py`
- [ ] Verify attendance columns đã đổi tên

### Hôm nay:
- [ ] Update `AttendanceRecord` model
- [ ] Update `attendance_service.dart`
- [ ] Test check-in với GPS
- [ ] Test check-out
- [ ] Verify CEO/Manager có thể xem attendance

### Tuần này:
- [ ] Tạo storage buckets cho AI files
- [ ] Fix assignee_id vs assigned_to
- [ ] Test phân quyền cho từng role
- [ ] Update companies với owner_id

---

## 🆘 CẦN GIÚP?

**Lỗi migration?**
```bash
# Check logs
python run_migration.py 2>&1 | tee migration.log

# Rollback nếu cần
# (Migration được thiết kế để không phá vỡ data cũ)
```

**Frontend vẫn lỗi?**
- Đọc file `CRITICAL-FIXES-QUICK-START.md`
- Check section "Common Issues & Solutions"

**Không chắc phải làm gì?**
1. Đọc `BAO-CAO-SUPABASE-THUC-TE.md` (báo cáo đầy đủ)
2. Follow từng bước trong PHASE 1
3. Test từng feature một

---

## 🎯 MỤC TIÊU

**Sau khi hoàn thành:**
- ✅ Attendance feature hoạt động với GPS
- ✅ Tasks CRUD hoạt động cho tất cả roles
- ✅ RLS policies hoạt động đúng
- ✅ File upload hoạt động
- ✅ Multi-company architecture hoàn chỉnh

**Risk level hiện tại:** 🟡 MEDIUM-HIGH  
**Risk level sau khi fix:** 🟢 LOW

---

**TL;DR:**
1. Chạy `python run_migration.py` (5 phút)
2. Update Dart models theo hướng dẫn (1 giờ)
3. Test lại tất cả features (2 giờ)
4. Done! 🎉

