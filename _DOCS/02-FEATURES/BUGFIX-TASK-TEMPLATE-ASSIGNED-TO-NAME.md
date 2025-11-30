# 🔧 Fix Task Template "assigned_to_name" Error

## ✅ Đã Fix

### 1. Database Schema
- ✅ Thêm column `assigned_to_name` vào bảng `tasks`
- ✅ Tạo index cho performance
- ✅ Thêm comment mô tả

### 2. Nguyên nhân lỗi

**Lỗi gốc**:
```
Exception: Failed to create task: PostgrestException(message: Could not find the 'assigned_to_name' column of 'tasks' in the schema cache, code: PGRST204)
```

**Nguyên nhân**:
- Bảng `tasks` thiếu column `assigned_to_name`
- Code `TaskService.createTask()` đang cố gắng insert vào column này
- PostgreSQL schema cache chưa được refresh

### 3. Giải pháp đã áp dụng

**Script**: `fix_tasks_assigned_to_name.py`

```sql
-- Thêm column
ALTER TABLE tasks 
ADD COLUMN assigned_to_name TEXT;

-- Tạo index
CREATE INDEX idx_tasks_assigned_to_name 
ON tasks(assigned_to_name);

-- Thêm comment
COMMENT ON COLUMN tasks.assigned_to_name 
IS 'Cached name of the assigned user for display purposes';
```

**Kết quả**:
```
✅ Column added!
✅ Index created!
✅ Comment added!
✅ Verified: assigned_to_name (text)
```

---

## 🔄 Next Steps

### Bước 1: Restart Flutter App

**Cách 1: Hot Restart (Khuyến nghị)**
1. Trong terminal đang chạy Flutter
2. Nhấn `R` (uppercase) để hot restart
3. Hoặc nhấn `Ctrl+C` rồi chạy lại `flutter run -d chrome`

**Cách 2: Restart từ VS Code**
1. Nhấn `Ctrl+Shift+P`
2. Gõ "Flutter: Hot Restart"
3. Hoặc click icon restart trong Debug toolbar

**Cách 3: Stop và Start lại**
```bash
# Stop app (Ctrl+C)
# Chạy lại
flutter run -d chrome
```

### Bước 2: Test lại tính năng

1. **Vào CEO Dashboard**
2. **Chọn một công ty**
3. **Tab "Công việc"**
4. **Click tab "Template"** (phía dưới)
5. **Chọn một template** (ví dụ: "Kiểm tra cơ sở vật chất")
6. **Click "Áp dụng"** ✅

**Expected**: 
- Task được tạo thành công
- Hiển thị thông báo: "✅ Đã tạo công việc: [Tên task]"
- Tự động chuyển về tab "Danh sách"
- Task mới xuất hiện trong danh sách

---

## 📊 Technical Details

### Task Model Fields

```dart
class Task {
  final String? assignedTo;        // UUID của user được giao
  final String? assignedToName;    // Tên của user (cached)
  // ...
}
```

### TaskService.createTask()

```dart
await _supabase.from('tasks').insert({
  // ...
  'assigned_to': task.assignedTo,           // UUID hoặc null
  'assigned_to_name': task.assignedToName,  // Tên hoặc null ✅
  // ...
})
```

### Database Schema

```sql
tasks (
  id uuid PRIMARY KEY,
  assigned_to uuid REFERENCES auth.users(id),
  assigned_to_name text,  -- ✅ Column mới thêm
  -- ...
)
```

---

## 🐛 Why This Happened?

### Timeline

1. **Code được viết** với assumption là `assigned_to_name` column tồn tại
2. **Database chưa có** column này (do migration chưa chạy)
3. **Khi apply template** → TaskService.createTask() cố gắng insert
4. **PostgreSQL báo lỗi** vì không tìm thấy column trong schema cache

### Schema Cache Issue

PostgreSQL sử dụng schema cache để tăng performance. Khi:
- Column mới được thêm
- App đang chạy
- Cache chưa được refresh

→ App vẫn sử dụng old schema → Lỗi PGRST204

**Solution**: Restart app để clear cache và load lại schema mới.

---

## ✅ Verification

### Check Database

```python
# Chạy script check
python check_tasks_schema.py

# Expected output:
# ✅ assigned_to_name: text (default: None)
```

### Check App

```dart
// Test creating task from template
final task = Task(
  // ...
  assignedToName: null,  // ✅ NULL is OK now
);

await taskService.createTask(task);
// ✅ Should work without error
```

---

## 🎯 Related Files

### Modified
- `d:\0\0211\SABOHUB\fix_tasks_assigned_to_name.py` - Migration script

### Affected
- `lib/services/task_service.dart` - Uses assigned_to_name
- `lib/models/task.dart` - Task model with assignedToName field
- `lib/pages/ceo/company/tasks_tab.dart` - Apply template logic

### Database
- `tasks` table - Added assigned_to_name column

---

## 💡 Lessons Learned

1. **Always sync database schema with code**
   - Khi code reference column mới
   - Phải chạy migration trước khi deploy

2. **Schema cache matters**
   - PostgreSQL cache schema để tăng performance
   - Restart app sau khi ALTER TABLE

3. **NULL handling**
   - Column mới nên allow NULL
   - Hoặc có DEFAULT value
   - Tránh breaking changes

---

## 🚀 Status

- ✅ Database updated
- ⏳ App restart required
- ⏳ Testing pending

**Next**: Hot restart app và test lại! 🔄
