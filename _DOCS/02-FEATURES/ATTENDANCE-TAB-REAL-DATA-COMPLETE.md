# Tab Chấm Công - Tích Hợp Dữ Liệu Thực

## Tóm tắt

Tab chấm công trong trang chi tiết công ty đã được tích hợp với dữ liệu thực từ Supabase, thay thế dữ liệu mock trước đó.

## Các thay đổi chính

### 1. Service mới: `attendance_service.dart`

Tạo service mới để quản lý tất cả các thao tác liên quan đến chấm công:

**File:** `lib/services/attendance_service.dart`

**Tính năng:**
- ✅ Lấy dữ liệu chấm công theo công ty và ngày
- ✅ Lấy dữ liệu chấm công theo nhân viên
- ✅ Check-in với location và photo
- ✅ Check-out với tự động tính giờ làm việc
- ✅ Cập nhật bản ghi chấm công
- ✅ Xóa bản ghi chấm công

**Các phương thức chính:**

```dart
// Lấy chấm công của công ty theo ngày
Future<List<AttendanceRecord>> getCompanyAttendance({
  required String companyId,
  DateTime? date,
})

// Lấy chấm công của nhân viên
Future<List<AttendanceRecord>> getUserAttendance({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
})

// Check-in
Future<AttendanceRecord> checkIn({
  required String userId,
  required String storeId,
  String? shiftId,
  String? location,
  String? photoUrl,
})

// Check-out
Future<AttendanceRecord> checkOut({
  required String attendanceId,
  String? location,
})
```

### 2. Cập nhật Provider: `attendance_tab.dart`

**Thay đổi:**

#### a. Provider mới với tham số đầy đủ

```dart
// Trước (mock data)
final companyAttendanceProvider =
    FutureProvider.family<List<EmployeeAttendanceRecord>, String>(
        (ref, companyId) async {
  return _generateMockAttendance(companyId);
});

// Sau (real data)
final companyAttendanceProvider =
    FutureProvider.family<List<EmployeeAttendanceRecord>, AttendanceQueryParams>(
        (ref, params) async {
  final service = ref.read(attendanceServiceProvider);
  final records = await service.getCompanyAttendance(
    companyId: params.companyId,
    date: params.date,
  );
  return records.map((record) => EmployeeAttendanceRecord(...)).toList();
});
```

#### b. Class tham số mới

```dart
class AttendanceQueryParams {
  final String companyId;
  final DateTime date;
  
  AttendanceQueryParams({
    required this.companyId,
    required this.date,
  });
}
```

### 3. Model: `AttendanceRecord`

Model mới để map dữ liệu từ Supabase:

```dart
class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userAvatar;
  final String storeId;
  final String? storeName;
  final String? shiftId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String? checkInLocation;
  final String? checkOutLocation;
  final String? checkInPhotoUrl;
  final double? totalHours;
  final bool isLate;
  final bool isEarlyLeave;
  final String? notes;
  final DateTime createdAt;
}
```

## Cấu trúc Database

### Bảng `attendance`

```sql
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
  check_in TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  check_out TIMESTAMPTZ,
  check_in_location TEXT,
  check_out_location TEXT,
  check_in_photo_url TEXT,
  total_hours DECIMAL(5, 2),
  is_late BOOLEAN DEFAULT false,
  is_early_leave BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Query với JOIN

Service sử dụng JOIN để lấy thông tin user và store:

```dart
final response = await _supabase
    .from('attendance')
    .select('''
      id,
      user_id,
      store_id,
      check_in,
      check_out,
      total_hours,
      is_late,
      is_early_leave,
      notes,
      users!inner(
        id,
        name,
        email,
        avatar_url,
        company_id
      ),
      stores(
        id,
        name,
        company_id
      )
    ''')
    .eq('users.company_id', companyId)
    .gte('check_in', startOfDay.toIso8601String())
    .lt('check_in', endOfDay.toIso8601String());
```

## Tính năng

### 1. Hiển thị dữ liệu thực

- ✅ Lấy dữ liệu chấm công từ Supabase theo công ty
- ✅ Lọc theo ngày (date picker)
- ✅ Lọc theo trạng thái (present, late, absent, on leave)
- ✅ Tìm kiếm theo tên nhân viên
- ✅ Hiển thị thông tin: giờ vào, giờ ra, giờ làm việc, trạng thái

### 2. Thống kê realtime

- ✅ Tổng số nhân viên
- ✅ Số nhân viên có mặt
- ✅ Số nhân viên đi muộn
- ✅ Số nhân viên vắng
- ✅ Tỷ lệ chấm công

### 3. Chi tiết bản ghi

- ✅ Xem chi tiết từng bản ghi chấm công
- ✅ Hiển thị location check-in/check-out (nếu có)
- ✅ Hiển thị notes

## Workflow

### CEO/Manager xem chấm công:

1. Vào trang chi tiết công ty
2. Chọn tab "Chấm công"
3. Chọn ngày cần xem (mặc định: hôm nay)
4. Xem danh sách và thống kê
5. Có thể lọc theo trạng thái hoặc tìm kiếm nhân viên

### Dữ liệu được tải:

```
User clicks tab → Provider loads → Service queries Supabase
                                  ↓
                        JOIN: attendance + users + stores
                                  ↓
                        Filter by company_id + date
                                  ↓
                        Map to AttendanceRecord
                                  ↓
                        Display in UI
```

## Testing

### Kiểm tra trong Supabase:

```sql
-- Kiểm tra dữ liệu attendance
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
ORDER BY a.check_in DESC;
```

### Test trong app:

1. Đảm bảo có dữ liệu test trong bảng `attendance`
2. Vào trang chi tiết công ty bất kỳ
3. Click vào tab "Chấm công"
4. Kiểm tra xem dữ liệu có hiển thị đúng không

## Lưu ý quan trọng

### 1. Company ID

⚠️ **Quan trọng:** Bảng `users` phải có cột `company_id` để filter theo công ty.

```sql
-- Kiểm tra column tồn tại
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'company_id';
```

### 2. RLS Policies

Cần đảm bảo RLS policies cho phép CEO/Manager xem chấm công của công ty họ:

```sql
-- Policy cho CEO/Manager
CREATE POLICY "Users can view attendance of their company"
ON attendance FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
      AND users.company_id = (
        SELECT company_id FROM users WHERE id = attendance.user_id
      )
      AND users.role IN ('CEO', 'MANAGER')
  )
);
```

### 3. Store vs Company

Hiện tại hệ thống có cả `store_id` và `company_id`:
- `store_id`: Chi nhánh cụ thể
- `company_id`: Công ty (có thể có nhiều chi nhánh)

Service lọc theo `company_id` để hiển thị tất cả chấm công trong công ty.

## TODO - Cải tiến trong tương lai

### 1. Tính toán thông minh

- [ ] Tự động tính `is_late` dựa trên giờ bắt đầu ca (shift start time)
- [ ] Tự động tính `is_early_leave` dựa trên giờ kết thúc ca
- [ ] Tính toán overtime hours

### 2. Xuất báo cáo

- [ ] Xuất Excel/PDF báo cáo chấm công
- [ ] Báo cáo tổng hợp theo tuần/tháng
- [ ] Chart và visualization

### 3. Chỉnh sửa

- [ ] Cho phép CEO/Manager chỉnh sửa giờ vào/ra
- [ ] Thêm notes/lý do
- [ ] Approve/reject attendance

### 4. Thông báo

- [ ] Thông báo khi nhân viên đi muộn
- [ ] Thông báo khi nhân viên quên checkout
- [ ] Daily/weekly attendance summary

## Kết luận

✅ Tab chấm công đã được tích hợp thành công với dữ liệu thực từ Supabase

✅ Provider và Service được tổ chức tốt, dễ mở rộng

✅ UI hiển thị đầy đủ thông tin cần thiết

✅ Hỗ trợ filter và search

✅ Ready for production với một số cải tiến nhỏ về RLS và validation

## Files liên quan

- `lib/services/attendance_service.dart` - Service mới
- `lib/pages/ceo/company/attendance_tab.dart` - UI đã cập nhật
- `lib/models/attendance.dart` - Models
- `database/schemas/CONSOLIDATED-SCHEMA.sql` - Database schema

---

**Ngày hoàn thành:** 04/11/2025
**Trạng thái:** ✅ HOÀN TẤT
