# 🧪 Hướng dẫn Test Tính năng Báo cáo Tự động Cuối Ngày

## ✅ Setup Hoàn tất

### 📁 Files Đã Tạo
1. **Test Page**: `lib/pages/test/daily_report_test_page.dart` ✅
2. **Documentation**: `DAILY-REPORT-TEST-COMPLETE.md` ✅
3. **Navigation**: Đã thêm vào Manager Dashboard ✅

---

## 🚀 Cách Test (3 Bước Đơn Giản)

### Bước 1: Mở App và Navigate
1. Chạy app Flutter
2. Đăng nhập với tài khoản **Manager**
3. Vào trang **Manager Dashboard** (trang chủ của Manager)
4. Cuộn xuống phần **"Hoạt động"**
5. Nhấn vào card màu **Indigo** (xanh tím):
   ```
   🧪 Test: Báo cáo Tự động
   Kiểm tra tính năng báo cáo cuối ngày tự động
   ```

### Bước 2: Simulate Checkout
Trên trang test, bạn sẽ thấy:

**Info Card (màu xanh dương)**:
- Giải thích tính năng tự động
- 5 feature points:
  - ⏰ Tính toán giờ làm việc tự động
  - ✅ Thu thập danh sách công việc hoàn thành
  - 📊 Tạo tóm tắt ca làm việc
  - 🎯 Đánh giá hiệu suất tự động
  - ✏️ Nhân viên có thể chỉnh sửa trước khi gửi

**Test Controls (white card)**:
1. Nhấn nút **"🚀 Simulate Checkout & Generate Report"**
2. Chờ 1-2 giây (simulating API call)
3. Thấy thông báo success: "✅ Báo cáo tạo thành công!"

### Bước 3: Xem Kết Quả
Sau khi generate, bạn sẽ thấy 2 phần:

#### A. Report Preview (trên trang)
- **Card màu xanh lá** với border
- Hiển thị:
  - ✅ Icon check circle "Báo cáo đã tạo thành công!"
  - 👤 Nhân viên: "Nguyễn Văn A (Test User)"
  - 📅 Ngày: hôm nay
  - ⏰ Giờ làm việc: 8:00 - 17:30 (9.5h)
  - ✅ Công việc hoàn thành: 2 tasks
  - 📝 Tóm tắt tự động (formatted text với emoji)
  - 📋 Danh sách 2 công việc:
    1. "Vệ sinh khu vực làm việc"
    2. "Kiểm tra thiết bị"

#### B. Preview Dialog (test interaction)
1. Nhấn nút **"👁️ Preview Report Dialog"**
2. Dialog popup hiển thị:
   - **Header**: "📝 Báo cáo công việc hôm nay"
   - **Auto Summary Section** (read-only):
     - Thời gian check-in/out
     - Tổng giờ làm việc
     - Số công việc hoàn thành
     - AI-generated summary text
   - **Editable Fields** (text inputs):
     - Ghi chú của nhân viên
     - Thành tựu
     - Thử thách gặp phải
     - Kế hoạch ngày mai
   - **Action Buttons**:
     - 💾 Lưu nháp
     - ✅ Gửi báo cáo

3. Test chỉnh sửa:
   - Thử nhập text vào các field
   - Nhấn "Lưu nháp" → thấy snackbar "💾 Báo cáo đã lưu nháp"
   - Hoặc "Gửi báo cáo" → thấy snackbar "✅ Báo cáo đã được gửi thành công!"

---

## 📊 Dữ Liệu Test (Mock)

### Attendance Simulation
```dart
Check-in:  8:00 AM   (8 giờ sáng)
Check-out: 5:30 PM   (5 giờ 30 chiều)
Total:     9.5 hours (9.5 giờ)
```

### Completed Tasks
1. **Vệ sinh khu vực làm việc**
   - Description: "Vệ sinh và sắp xếp khu vực làm việc"
   - Notes: "Hoàn thành sạch sẽ"

2. **Kiểm tra thiết bị**
   - Description: "Kiểm tra hoạt động của thiết bị"
   - Notes: "Tất cả hoạt động tốt"

### Performance Evaluation
- **Giờ làm**: 9.5 giờ
- **Tasks hoàn thành**: 2
- **Rating**: **"Tốt"** (Good)
  - Logic: 9.5h >= 6h ✅ AND 2 tasks >= 2 ✅

### Auto-Generated Summary (Example)
```
⏰ CA LÀM VIỆC
Bắt đầu: 8:00 AM
Kết thúc: 5:30 PM
Tổng thời gian: 9.5 giờ

✅ CÔNG VIỆC HOÀN THÀNH
Đã hoàn thành 2/2 công việc được giao:
• Vệ sinh khu vực làm việc - Hoàn thành sạch sẽ
• Kiểm tra thiết bị - Tất cả hoạt động tốt

🎯 ĐÁNH GIÁ HIỆU SUẤT: TốT
Nhân viên đã hoàn thành tốt công việc trong ca.
```

---

## 🎯 Điểm Kiểm Tra (Test Checklist)

### ✅ Tính năng Core
- [ ] Report auto-generates khi nhấn "Simulate Checkout"
- [ ] Tính toán giờ làm việc chính xác (9.5h)
- [ ] Thu thập tasks đúng (2 tasks)
- [ ] Generate summary có format đẹp (emoji headers)
- [ ] Performance rating đúng ("Tốt")

### ✅ UI/UX
- [ ] Info card hiển thị đủ thông tin
- [ ] Test controls buttons hoạt động
- [ ] Report preview card hiển thị đẹp
- [ ] Dialog popup đúng cách
- [ ] Text fields có thể edit
- [ ] Submit/save buttons work
- [ ] Snackbars hiển thị feedback

### ✅ Data Flow
- [ ] Mock attendance → service → report
- [ ] Tasks collected correctly
- [ ] Summary generated
- [ ] Dialog receives report data
- [ ] Employee edits preserved (in dialog state)

---

## 🔍 Performance Rating Logic

Hệ thống đánh giá dựa trên 2 yếu tố:

| Giờ làm | Tasks | Rating |
|---------|-------|--------|
| >= 8h | >= 3 | **Xuất sắc** ⭐⭐⭐ |
| >= 6h | >= 2 | **Tốt** ⭐⭐ |
| >= 4h | >= 1 | **Trung bình** ⭐ |
| < 4h | 0 | **Cần cố gắng** ⚠️ |

**Test case hiện tại**: 9.5h + 2 tasks = **Tốt** ✅

---

## 🐛 Troubleshooting

### Vấn đề 1: Không tìm thấy Test button trong Manager Dashboard
**Giải quyết**:
- Đảm bảo đã rebuild app (hot reload có thể không đủ)
- Kiểm tra import đã thêm: `import '../test/daily_report_test_page.dart';`
- Cuộn xuống phần "Hoạt động" → tìm card màu indigo

### Vấn đề 2: Báo cáo không generate
**Giải quyết**:
- Mở DevTools → Console
- Kiểm tra error logs
- Verify `DailyWorkReportService` exists
- Check `_collectTodayCompletedTasks()` returns mock data

### Vấn đề 3: Dialog không mở
**Giải quyết**:
- Nhấn "Simulate Checkout" trước
- Chờ report preview xuất hiện
- Sau đó mới nhấn "Preview Report Dialog"

---

## 🔌 Kết Nối Dữ Liệu Thật (TODO)

Hiện tại test dùng **mock data**. Để kết nối real data:

### 1. Connect Tasks Service
File: `lib/services/daily_work_report_service.dart`

```dart
// Find method: _collectTodayCompletedTasks()
// Replace mock return with:
Future<List<TaskSummary>> _collectTodayCompletedTasks(String userId) async {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // Query Supabase
  final response = await supabase
      .from('tasks')
      .select()
      .eq('assigned_to', userId)
      .eq('status', 'completed')
      .gte('completed_at', startOfDay.toIso8601String())
      .lt('completed_at', endOfDay.toIso8601String());

  return (response as List)
      .map((json) => TaskSummary.fromJson(json))
      .toList();
}
```

### 2. Add Database Persistence
```dart
// In generateReportFromCheckout(), after creating report:
await supabase.from('daily_work_reports').insert(report.toJson());
```

### 3. Integrate with Real Checkout
File: `lib/pages/attendance/checkout_page.dart` (or similar)

```dart
// After successful checkout:
final report = await DailyWorkReportService().generateReportFromCheckout(
  attendance: attendance,
  userName: userName,
);

// Show dialog
showDialog(
  context: context,
  builder: (_) => WorkReportPreviewDialog(report: report),
);
```

---

## 📱 Video Demo Script

Để record demo video:

1. **Intro** (5s): "Test tính năng báo cáo tự động cuối ngày"
2. **Navigate** (10s): Mở app → Manager Dashboard → cuộn → tap Test card
3. **Explain** (15s): Giải thích 5 features trên info card
4. **Generate** (10s): Tap "Simulate Checkout" → show success
5. **Preview** (15s): Cuộn xem report preview với tất cả data
6. **Dialog** (20s): Tap "Preview Dialog" → show editable fields → save/submit
7. **Outro** (5s): "Tính năng hoạt động hoàn hảo!"

**Total**: ~80 giây

---

## ✅ Test Complete!

Khi đã test xong tất cả checklist, bạn xác nhận:

✅ Auto-generation works correctly
✅ UI/UX smooth and intuitive  
✅ Data flows properly from checkout → report → dialog
✅ Performance evaluation logic accurate
✅ Employee can edit before submit
✅ Mock data ready for real integration

**Next steps**: Kết nối với Supabase real data 🔌

---

**File này được tạo**: ${DateTime.now().toString().split('.')[0]}
**Test page**: `lib/pages/test/daily_report_test_page.dart`
**Documentation**: `DAILY-REPORT-TEST-COMPLETE.md`
