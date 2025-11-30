# 🚀 HƯỚNG DẪN SỬ DỤNG HỆ THỐNG ĐÁNH GIÁ KPI

## ⚡ Quick Start (5 phút)

### Bước 1: Setup Database (Chỉ chạy 1 lần)

```bash
# Cài supabase-py nếu chưa có
pip install supabase

# Chạy test script để tạo sample data
python test_kpi_system.py
```

**Script sẽ:**
- ✅ Kiểm tra tables: `performance_metrics`, `kpi_targets`
- ✅ Tạo KPI targets mặc định cho 5 nhân viên đầu tiên
- ✅ Tạo performance metrics cho 7 ngày gần đây
- ✅ Hiển thị thống kê và sample data

---

### Bước 2: Chạy Flutter App

```bash
flutter run -d chrome
```

---

### Bước 3: Sử dụng trong App

#### 🔑 Login as Manager
- Email: manager@email.com
- Password: (your manager password)

#### 📊 Xem đánh giá nhân viên

1. **Mở Settings tab** (Tab cuối cùng)
2. **Scroll xuống section "Quản lý"**
3. **Click "Đánh giá nhân viên"**

#### 🎯 Các chức năng chính:

**A. Filter & Sort**
- **Khoảng thời gian:**
  - 7 ngày qua
  - 30 ngày qua
  - Tháng này
  - Tháng trước
  
- **Sắp xếp:**
  - Điểm tổng (mặc định)
  - Tên A-Z
  - Tỷ lệ hoàn thành

**B. Tính metrics mới**
- Click icon ⚙️ "Calculate" trên AppBar
- Hệ thống tự động:
  - Query tasks của hôm nay
  - Query attendance records
  - Tính completion_rate, on_time_rate, quality_score
  - Lưu vào database
- SnackBar hiển thị "Đã tính toán metrics thành công!"

**C. Xem chi tiết nhân viên**
- Click **"Chi tiết"** trên card
- Dialog hiển thị:
  - Điểm tổng + Đánh giá
  - List KPI targets với progress bar
  - Target value vs Actual value
  - Achievement percentage

**D. Đánh giá thủ công**
- Click **"Đánh giá"** trên card
- Adjust slider 0-100
- Nhập ghi chú
- Click "Lưu đánh giá"

---

## 📱 UI Overview

```
┌─────────────────────────────────────┐
│  Đánh giá hiệu suất nhân viên  ⚙️ 🔄│
├─────────────────────────────────────┤
│ Khoảng thời gian: [7 ngày qua ▼]   │
│ Sắp xếp theo:     [Điểm tổng ▼]    │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ #1  👤 Nguyễn Văn A             │ │
│ │     STAFF                  92.5 │ │
│ │     KPI đạt: 2/3          Tốt  │ │
│ │     ✓ 90% │⭐ 85% │⏰ 95%      │ │
│ │     [Chi tiết] [Đánh giá]      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ #2  👤 Trần Thị B               │ │
│ │     MANAGER                87.3 │ │
│ │     KPI đạt: 1/2          Tốt  │ │
│ │     ✓ 85% │⭐ 90% │⏰ 88%      │ │
│ │     [Chi tiết] [Đánh giá]      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

## 🎨 Màu sắc đánh giá

| Điểm | Đánh giá | Màu |
|------|----------|-----|
| 90-100 | Xuất sắc | 🟢 Xanh lá |
| 80-89 | Tốt | 🔵 Xanh dương |
| 70-79 | Khá | 🟠 Cam |
| 60-69 | Trung bình | 🟡 Vàng |
| 0-59 | Cần cải thiện | 🔴 Đỏ |

---

## 📊 KPI Metrics Explained

### 1. Completion Rate (Tỷ lệ hoàn thành)
```
= (tasks_completed / tasks_assigned) * 100
```
- **Target:** 90-95% tùy role
- **Weight:** 40% trong tổng điểm

### 2. Quality Score (Điểm chất lượng)
```
= Average rating from managers (0-10)
```
- **Target:** 8-8.5/10 tùy role
- **Weight:** 30% trong tổng điểm

### 3. On-Time Rate (Tỷ lệ đúng hạn)
```
= (tasks completed before due_date / total completed) * 100
```
- **Target:** 95%
- **Weight:** 20% trong tổng điểm

### 4. Photo Submission (Gửi hình ảnh)
```
= (tasks with photos / total tasks) * 100
```
- **Target:** 100%
- **Weight:** 10% trong tổng điểm

---

## 🔧 Troubleshooting

### ❌ "Chưa có dữ liệu đánh giá"

**Nguyên nhân:**
- Chưa có performance metrics trong database
- Nhân viên chưa có tasks nào

**Giải pháp:**
1. Click nút "Calculate" ⚙️
2. Hoặc chạy: `python test_kpi_system.py`

---

### ❌ "Failed to calculate metrics"

**Nguyên nhân:**
- Không có quyền truy cập company_id
- Lỗi kết nối Supabase

**Giải pháp:**
1. Kiểm tra user có trong employees table
2. Verify company_id exists
3. Check Supabase connection

---

### ❌ Employee card không hiển thị metrics

**Nguyên nhân:**
- Metrics = null trong database
- Khoảng thời gian không có data

**Giải pháp:**
1. Đổi filter sang "30 ngày qua"
2. Click "Calculate" để tính metrics mới

---

## 📝 Sample Data Structure

### Performance Metrics Record
```json
{
  "user_id": "abc-123",
  "user_name": "Nguyễn Văn A",
  "metric_date": "2025-01-15",
  "tasks_assigned": 10,
  "tasks_completed": 9,
  "tasks_overdue": 1,
  "tasks_cancelled": 0,
  "completion_rate": 90.0,
  "avg_quality_score": 8.5,
  "on_time_rate": 95.0,
  "photo_submission_rate": 100.0,
  "total_work_duration": 480,
  "checklists_completed": 9,
  "incidents_reported": 0
}
```

### KPI Target Record
```json
{
  "user_id": "abc-123",
  "role": "STAFF",
  "metric_name": "Tỷ lệ hoàn thành nhiệm vụ",
  "metric_type": "completion_rate",
  "target_value": 90.0,
  "period": "weekly",
  "start_date": null,
  "end_date": null,
  "is_active": true
}
```

---

## 🎯 Common Use Cases

### UC1: Tìm nhân viên performance cao nhất

1. Filter: "Tháng này"
2. Sort: "Điểm tổng"
3. Xem top 3 nhân viên
4. Click "Chi tiết" để xem KPI

### UC2: Kiểm tra nhân viên chưa đạt target

1. Filter: "7 ngày qua"
2. Scroll xuống bottom của list
3. Tìm nhân viên có điểm < 70
4. Click "Đánh giá" để ghi nhận

### UC3: So sánh performance theo thời gian

1. Filter: "Tháng này" → Note điểm
2. Filter: "Tháng trước" → So sánh
3. Identify: Improving / Declining

### UC4: Daily metrics update

**Mỗi ngày:**
1. Login as Manager
2. Mở "Đánh giá nhân viên"
3. Click "Calculate" ⚙️
4. Review nhân viên có vấn đề

---

## 🚀 Advanced Tips

### Tip 1: Tự động tính metrics (Supabase Edge Function)

```typescript
// supabase/functions/daily-metrics/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabase = createClient(...)
  
  // Get all companies
  const companies = await supabase.from('companies').select('id')
  
  for (const company of companies.data) {
    // Calculate metrics for all employees
    // Call your Flutter service logic here
  }
  
  return new Response('Metrics calculated', { status: 200 })
})
```

**Setup Cron:**
```sql
SELECT cron.schedule(
  'daily-metrics',
  '0 0 * * *', -- Every day at midnight
  $$
  SELECT net.http_post(
    url:='https://your-project.supabase.co/functions/v1/daily-metrics',
    headers:='{"Authorization": "Bearer YOUR_KEY"}'::jsonb
  );
  $$
);
```

### Tip 2: Export báo cáo PDF

```dart
// Add dependencies
// pdf: ^3.10.4

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> exportPerformanceReport(List evaluations) async {
  final pdf = pw.Document();
  
  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Text('Báo cáo đánh giá nhân viên'),
          // Add table with evaluations
        ],
      ),
    ),
  );
  
  // Save or share PDF
  final bytes = await pdf.save();
  // ...
}
```

### Tip 3: Push notification cho low performers

```dart
// Check if employee below threshold
if (evaluation['overall_score'] < 70) {
  // Send push notification
  await sendNotification(
    userId: evaluation['user_id'],
    title: 'Performance Alert',
    body: 'Your performance this week is below target. Please improve!',
  );
}
```

---

## ✅ Checklist hoàn thành

- [x] Database tables (performance_metrics, kpi_targets)
- [x] Models (PerformanceMetrics, KPITarget)
- [x] Services (PerformanceMetricsService, KPIService)
- [x] UI (EmployeePerformancePage)
- [x] Manager integration
- [x] Calculate metrics function
- [x] Filter & sort
- [x] Detail view
- [x] Manual evaluation UI
- [ ] Save manual evaluation to DB (TODO)
- [ ] Automatic daily calculation (TODO)
- [ ] CEO dashboard (TODO)
- [ ] Export PDF (TODO)
- [ ] Push notifications (TODO)

---

## 📞 Support

Nếu có vấn đề:
1. Check console logs trong Flutter
2. Check Supabase logs
3. Verify data trong Supabase Studio
4. Review code trong các files:
   - `lib/services/performance_metrics_service.dart`
   - `lib/services/kpi_service.dart`
   - `lib/pages/manager/employee_performance_page.dart`

---

## 🎉 Kết luận

Hệ thống KPI đã sẵn sàng! 

**Manager có thể:**
- ✅ Xem ranking nhân viên real-time
- ✅ Track KPI targets
- ✅ Tính toán metrics tự động
- ✅ Đánh giá performance chi tiết
- ✅ Filter theo thời gian
- ✅ Sort theo nhiều tiêu chí

**Next level:**
- Tự động hóa với Cron jobs
- CEO dashboard tổng quan
- Export báo cáo
- Gamification & rewards
