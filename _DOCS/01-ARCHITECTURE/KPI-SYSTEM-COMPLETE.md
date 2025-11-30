# 🎯 HỆ THỐNG ĐÁNH GIÁ NHÂN VIÊN TỰ ĐỘNG - HOÀN THÀNH

## 📋 Tổng quan

Đã xây dựng hoàn chỉnh hệ thống đánh giá KPI và hiệu suất nhân viên tự động cho SABOHUB, bao gồm:

- ✅ **Models**: PerformanceMetrics, KPITarget
- ✅ **Services**: PerformanceMetricsService, KPIService
- ✅ **UI**: EmployeePerformancePage cho Manager
- ✅ **Integration**: Tích hợp vào Manager Settings

---

## 🗂️ Cấu trúc files

### 1. Models (Data Structure)

#### `lib/models/performance_metrics.dart`
```dart
class PerformanceMetrics {
  - id, userId, userName
  - metricDate
  - tasksAssigned, tasksCompleted, tasksOverdue, tasksCancelled
  - completionRate, avgQualityScore, onTimeRate, photoSubmissionRate
  - totalWorkDuration (minutes)
  - checklistsCompleted, incidentsReported
  
  // Helper methods
  - overallScore: double (0-100)
  - performanceRating: String (Xuất sắc/Tốt/Khá/Trung bình/Cần cải thiện)
  - ratingColor: String
}
```

#### `lib/models/kpi_target.dart`
```dart
class KPITarget {
  - id, userId, role
  - metricName, metricType
  - targetValue, period (daily/weekly/monthly)
  - startDate, endDate, isActive
  
  // Helper methods
  - isCurrentlyActive: bool
  - metricTypeDisplay, periodDisplay: String
}
```

---

### 2. Services (Business Logic)

#### `lib/services/performance_metrics_service.dart`

**Chức năng chính:**

1. **calculateDailyMetrics(userId, date)** - Tự động tính metrics:
   - Lấy data từ `tasks` table (assigned, completed, overdue, cancelled)
   - Tính completion_rate (tasks_completed / tasks_assigned * 100)
   - Tính on_time_rate (tasks completed before due date)
   - Lấy data từ `attendance` table (work duration)
   - Lấy data từ `incident_reports` table
   - **Lưu vào `performance_metrics` table** (upsert)

2. **getMetrics(userId, startDate, endDate)**
   - Query metrics cho user trong khoảng thời gian

3. **getCompanyMetrics(companyId, date)**
   - Lấy metrics của tất cả nhân viên trong company

4. **calculateCompanyDailyMetrics(companyId, date)**
   - Tính metrics cho tất cả nhân viên trong company

5. **getPerformanceSummary(userId, days)**
   - Tổng hợp: avg_completion_rate, avg_quality_score, avg_on_time_rate
   - Total tasks, work hours
   - Performance trend (improving/declining/stable)

#### `lib/services/kpi_service.dart`

**Chức năng chính:**

1. **createTarget(...)** - Tạo KPI target mới

2. **getUserTargets(userId)** - Lấy KPI targets của user

3. **getRoleTargets(role)** - Lấy KPI targets theo role

4. **evaluatePerformance(userId, startDate, endDate)** - Đánh giá chính:
   ```javascript
   {
     user_id, user_name,
     targets_met, total_targets,
     overall_score (0-100),
     evaluation (Xuất sắc/Tốt/Khá/...),
     avg_completion_rate, avg_quality_score, avg_on_time_rate,
     details: [
       {metric_name, target_value, actual_value, achievement_percent, is_met}
     ]
   }
   ```

5. **getCompanyPerformance(companyId, startDate, endDate)**
   - Đánh giá tất cả nhân viên
   - Sort theo overall_score

6. **createDefaultTargetsForRole(role)** - Tạo KPI mặc định:
   - **STAFF**: completion_rate (90%), timeliness (95%), photo_submission (100%)
   - **MANAGER**: completion_rate (95%), quality_score (85%)
   - **SHIFT_LEADER**: completion_rate (92%), quality_score (80%)

---

### 3. UI Components

#### `lib/pages/manager/employee_performance_page.dart`

**Giao diện Manager xem và đánh giá nhân viên:**

**Filters:**
- Khoảng thời gian: 7 ngày, 30 ngày, tháng này, tháng trước
- Sắp xếp: Điểm tổng, Tên, Tỷ lệ hoàn thành

**Employee Cards hiển thị:**
- Ranking (#1, #2, #3...)
- Tên, Role
- Điểm tổng (0-100) với màu sắc (green/blue/orange/amber/red)
- Đánh giá (Xuất sắc/Tốt/Khá/Trung bình/Cần cải thiện)
- KPI đạt: X/Y targets
- 3 metrics chính: Hoàn thành %, Chất lượng %, Đúng giờ %
- Nút "Chi tiết" và "Đánh giá"

**Actions:**
- **Tính toán metrics hôm nay** button (AppBar)
  - Gọi `_metricsService.calculateCompanyDailyMetrics()`
- **Refresh** button
- **Chi tiết** dialog:
  - Hiển thị tất cả KPI targets
  - Progress bar cho từng metric
  - Target vs Actual values
- **Đánh giá** dialog:
  - Slider điểm thủ công (0-100)
  - TextField ghi chú
  - Lưu đánh giá

---

### 4. Integration

#### `lib/pages/manager/manager_settings_page.dart`

Đã thêm menu item mới:
```dart
_buildSettingItem(
  'Đánh giá nhân viên',
  'Xem KPI và hiệu suất nhân viên',
  Icons.rate_review,
  () {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => const EmployeePerformancePage(),
    ));
  },
),
```

---

## 🔄 Workflow sử dụng

### 1. Tính metrics tự động (Daily)

```dart
final service = PerformanceMetricsService();

// Tính metrics cho 1 nhân viên
await service.calculateDailyMetrics(
  userId: 'employee-uuid',
  date: DateTime.now(),
);

// Hoặc tính cho toàn công ty
await service.calculateCompanyDailyMetrics(
  companyId: 'company-uuid',
  date: DateTime.now(),
);
```

**Dữ liệu được lưu vào `performance_metrics` table:**
- user_id, user_name
- metric_date
- tasks_assigned, tasks_completed, tasks_overdue, tasks_cancelled
- completion_rate, avg_quality_score, on_time_rate
- photo_submission_rate, total_work_duration
- checklists_completed, incidents_reported

---

### 2. Setup KPI targets

```dart
final kpiService = KPIService();

// Tạo KPI cho role
await kpiService.createDefaultTargetsForRole('STAFF');

// Hoặc tạo custom cho nhân viên cụ thể
await kpiService.createTarget(
  userId: 'employee-uuid',
  metricName: 'Hoàn thành nhiệm vụ',
  metricType: 'completion_rate',
  targetValue: 95.0,
  period: 'weekly',
);
```

---

### 3. Đánh giá performance

```dart
// Đánh giá 1 nhân viên
final evaluation = await kpiService.evaluatePerformance(
  userId: 'employee-uuid',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

print(evaluation['overall_score']); // 85.5
print(evaluation['evaluation']); // "Tốt"
print(evaluation['targets_met']); // 2
print(evaluation['total_targets']); // 3

// Đánh giá toàn công ty
final companyEvals = await kpiService.getCompanyPerformance(
  companyId: 'company-uuid',
  startDate: ...,
  endDate: ...,
);
```

---

## 📊 Database Schema

### Bảng `performance_metrics` (Đã có trong migration)

```sql
CREATE TABLE performance_metrics (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  user_name VARCHAR(255),
  metric_date DATE NOT NULL,
  tasks_assigned INT DEFAULT 0,
  tasks_completed INT DEFAULT 0,
  tasks_overdue INT DEFAULT 0,
  tasks_cancelled INT DEFAULT 0,
  completion_rate DECIMAL(5,2),
  avg_quality_score DECIMAL(3,2),
  on_time_rate DECIMAL(5,2),
  photo_submission_rate DECIMAL(5,2),
  total_work_duration INT DEFAULT 0,
  checklists_completed INT DEFAULT 0,
  incidents_reported INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, metric_date)
);
```

### Bảng `kpi_targets` (Đã có trong migration)

```sql
CREATE TABLE kpi_targets (
  id UUID PRIMARY KEY,
  user_id UUID,
  role VARCHAR(50),
  metric_name VARCHAR(100) NOT NULL,
  metric_type VARCHAR(50) CHECK (metric_type IN (
    'completion_rate', 'quality_score', 'timeliness', 
    'photo_submission', 'custom'
  )),
  target_value DECIMAL(10,2) NOT NULL,
  period VARCHAR(20) CHECK (period IN ('daily', 'weekly', 'monthly')),
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 🎯 Use Cases

### UC1: Manager xem ranking nhân viên

1. Manager mở app → Tab Settings
2. Click "Đánh giá nhân viên"
3. Chọn khoảng thời gian (7 ngày / 30 ngày / tháng này / tháng trước)
4. Chọn sắp xếp (Điểm tổng / Tên / Tỷ lệ hoàn thành)
5. Xem danh sách nhân viên với:
   - Ranking (#1, #2, #3...)
   - Điểm tổng + Đánh giá
   - KPI đạt được
   - 3 metrics chính

### UC2: Manager xem chi tiết performance

1. Từ danh sách, click "Chi tiết" trên card nhân viên
2. Dialog hiển thị:
   - Điểm tổng
   - Đánh giá tổng thể
   - Chi tiết từng KPI:
     * Metric name
     * Target value vs Actual value
     * Achievement percentage
     * Progress bar (xanh nếu đạt, cam nếu chưa)

### UC3: Manager tính metrics mới

1. Click nút "Calculate" trên AppBar
2. Service tự động:
   - Query tasks, attendance, incidents từ DB
   - Tính toán metrics
   - Lưu vào performance_metrics table
3. Refresh danh sách tự động
4. Hiển thị SnackBar "Đã tính toán metrics thành công!"

### UC4: Manager đánh giá thủ công

1. Click "Đánh giá" trên card nhân viên
2. Dialog hiển thị:
   - Điểm hệ thống tự động
   - Slider để điều chỉnh điểm (0-100)
   - TextField ghi chú
3. Click "Lưu đánh giá"
4. (TODO: Cần implement lưu vào DB)

---

## 🔧 Cấu hình và Tùy chỉnh

### Thay đổi metric weights

Hiện tại `overallScore` tính trung bình 4 metrics:
- completion_rate (0-100)
- quality_score (0-10 → 0-100)
- on_time_rate (0-100)
- photo_submission_rate (0-100)

**Để thay đổi weights:**

Edit `lib/models/performance_metrics.dart`:
```dart
double get overallScore {
  double score = 0.0;
  
  if (completionRate != null) score += completionRate! * 0.4; // 40%
  if (avgQualityScore != null) score += avgQualityScore! * 10 * 0.3; // 30%
  if (onTimeRate != null) score += onTimeRate! * 0.2; // 20%
  if (photoSubmissionRate != null) score += photoSubmissionRate! * 0.1; // 10%

  return score;
}
```

### Thay đổi default KPI targets

Edit `lib/services/kpi_service.dart` → `createDefaultTargetsForRole()`:
```dart
case 'STAFF':
  defaultTargets.addAll([
    {
      'metric_name': 'Tỷ lệ hoàn thành nhiệm vụ',
      'metric_type': 'completion_rate',
      'target_value': 85.0, // Giảm từ 90% xuống 85%
      'period': 'weekly',
    },
    // ...
  ]);
```

### Thêm metric type mới

1. Update database ENUM:
```sql
ALTER TABLE kpi_targets 
DROP CONSTRAINT kpi_targets_metric_type_check;

ALTER TABLE kpi_targets 
ADD CONSTRAINT kpi_targets_metric_type_check 
CHECK (metric_type IN (
  'completion_rate', 'quality_score', 'timeliness', 
  'photo_submission', 'custom', 'customer_rating' -- NEW
));
```

2. Update `lib/services/kpi_service.dart` → `evaluatePerformance()`:
```dart
switch (target.metricType) {
  // ... existing cases ...
  case 'customer_rating':
    actualValue = avgCustomerRating; // Lấy từ metrics
    unit = '/5';
    break;
}
```

3. Update `lib/models/kpi_target.dart` → `metricTypeDisplay`:
```dart
case 'customer_rating':
  return 'Đánh giá khách hàng';
```

---

## 🚀 Deployment Checklist

### ✅ Đã hoàn thành:
- [x] Models (PerformanceMetrics, KPITarget)
- [x] Services (PerformanceMetricsService, KPIService)
- [x] UI (EmployeePerformancePage)
- [x] Integration vào Manager Settings
- [x] Database schema đã có trong migrations

### 📝 TODO (Tùy chọn - nâng cao):
- [ ] Tự động tính metrics hàng ngày (Cloud Function hoặc Cron job)
- [ ] Lưu manual evaluation vào database
- [ ] Push notification khi nhân viên không đạt KPI
- [ ] Export PDF báo cáo
- [ ] Chart/Graph visualization performance theo thời gian
- [ ] CEO dashboard tổng quan (hiện chỉ có Manager)
- [ ] Gamification: Badges, Achievements cho nhân viên xuất sắc

---

## 🧪 Testing Guide

### Test Manual trong App:

1. **Login as Manager**
2. **Vào Settings → "Đánh giá nhân viên"**
3. **Test Calculate Metrics:**
   - Click nút "Calculate" trên AppBar
   - Kiểm tra console log
   - Verify data trong Supabase

4. **Test Filters:**
   - Thử đổi khoảng thời gian
   - Thử đổi sắp xếp
   - Verify data refresh

5. **Test Employee Card:**
   - Click "Chi tiết"
   - Click "Đánh giá"
   - Verify UI rendering

### Test với Supabase Studio:

```sql
-- 1. Tạo KPI targets mặc định
-- (Run từ Flutter app)

-- 2. Insert test performance metrics
INSERT INTO performance_metrics (
  user_id, user_name, metric_date,
  tasks_assigned, tasks_completed,
  completion_rate, avg_quality_score, on_time_rate
) VALUES (
  'test-user-id', 'Test User', CURRENT_DATE,
  10, 9, 90.0, 8.5, 95.0
);

-- 3. Query để verify
SELECT * FROM performance_metrics 
WHERE metric_date = CURRENT_DATE;

SELECT * FROM kpi_targets 
WHERE is_active = true;
```

---

## 📚 API Reference

### PerformanceMetricsService

```dart
// Calculate metrics for one employee
Future<PerformanceMetrics> calculateDailyMetrics({
  required String userId,
  required DateTime date,
});

// Get metrics for date range
Future<List<PerformanceMetrics>> getMetrics({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
});

// Get all employee metrics in company
Future<List<PerformanceMetrics>> getCompanyMetrics({
  required String companyId,
  DateTime? date,
});

// Calculate metrics for all employees
Future<List<PerformanceMetrics>> calculateCompanyDailyMetrics({
  required String companyId,
  required DateTime date,
});

// Get summary stats
Future<Map<String, dynamic>> getPerformanceSummary({
  required String userId,
  int days = 7,
});
```

### KPIService

```dart
// Create KPI target
Future<KPITarget> createTarget({
  String? userId,
  String? role,
  required String metricName,
  required String metricType,
  required double targetValue,
  String period = 'weekly',
  DateTime? startDate,
  DateTime? endDate,
});

// Get targets
Future<List<KPITarget>> getUserTargets(String userId);
Future<List<KPITarget>> getRoleTargets(String role);

// Evaluate performance
Future<Map<String, dynamic>> evaluatePerformance({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
});

// Get company-wide evaluation
Future<List<Map<String, dynamic>>> getCompanyPerformance({
  required String companyId,
  DateTime? startDate,
  DateTime? endDate,
});

// Create defaults
Future<List<KPITarget>> createDefaultTargetsForRole(String role);
```

---

## 🎉 Kết luận

Hệ thống đánh giá nhân viên đã hoàn chỉnh với:

✅ **Tự động tính toán metrics** từ tasks, attendance, incidents
✅ **KPI system** linh hoạt với targets theo role hoặc cá nhân
✅ **Evaluation engine** đánh giá performance dựa trên KPI
✅ **Manager UI** xem ranking, chi tiết, đánh giá thủ công
✅ **Database-backed** với RLS security
✅ **Production-ready** code structure

**Manager giờ có thể:**
- Xem ranking nhân viên theo performance
- Theo dõi KPI đạt được
- Đánh giá chi tiết từng metrics
- Tính toán metrics tự động
- Filter theo thời gian và sort

**Next steps tùy chọn:**
- Tự động hóa với Cloud Functions
- Push notifications
- CEO dashboard
- Export báo cáo
- Gamification
