# 🎯 Backend Integration Complete - Management Tasks System

## ✅ Đã hoàn thành

### 1. **Database Schema** (Supabase)
✅ Tạo 4 bảng mới:
- `tasks` - Bảng task chính với đầy đủ metadata
- `task_comments` - Comments/discussions on tasks
- `task_attachments` - File attachments
- `task_approvals` - CEO approval workflow

✅ **Row Level Security (RLS)** đầy đủ:
- CEO: Xem tất cả tasks
- Manager: Xem tasks được giao hoặc tự tạo
- Staff: Chỉ xem tasks được giao
- Policies cho INSERT, UPDATE, DELETE

✅ **Indexes** tối ưu cho:
- created_by, assigned_to
- company_id, branch_id
- status, priority, due_date
- created_at (DESC)

✅ **Auto-update timestamp trigger**

### 2. **Models** (`lib/models/management_task.dart`)
✅ `ManagementTask` class:
- Full properties: id, title, description, priority, status, progress, dates
- User details: createdByName, assignedToName, roles
- JSON serialization: `fromJson()`, `toJson()`
- `copyWith()` method

✅ Enums với labels tiếng Việt:
- `TaskPriority`: critical, high, medium, low
- `TaskStatus`: pending, in_progress, completed, overdue, cancelled
- `ApprovalType`: report, budget, proposal, other
- `ApprovalStatus`: pending, approved, rejected

✅ `TaskApproval` class cho CEO approval workflow

### 3. **Service Layer** (`lib/services/management_task_service.dart`)
✅ 12 Methods hoàn chỉnh:

**Query Methods:**
- `getCEOStrategicTasks()` - Tasks của CEO (với JOIN users, companies, branches)
- `getTasksAssignedToMe()` - Tasks được giao cho user hiện tại
- `getTasksCreatedByMe()` - Tasks user hiện tại đã tạo
- `getPendingApprovals()` - Approval requests chờ duyệt

**CRUD Methods:**
- `createTask()` - Tạo task mới (CEO → Manager hoặc Manager → Staff)
- `updateTaskProgress()` - Cập nhật % tiến độ
- `updateTaskStatus()` - Cập nhật trạng thái
- `deleteTask()` - Xóa task

**Approval Methods:**
- `approveTaskApproval()` - CEO phê duyệt request
- `rejectTaskApproval()` - CEO từ chối với lý do

**Statistics Methods:**
- `getTaskStatistics()` - Tổng, pending, in_progress, completed, overdue
- `getCompanyTaskStatistics()` - Stats theo từng công ty

### 4. **Providers** (`lib/providers/management_task_provider.dart`)
✅ Riverpod FutureProviders:
- `ceoStrategicTasksProvider` - Dùng trong CEO Tasks Page
- `managerAssignedTasksProvider` - Dùng trong Manager Tasks Page (From CEO tab)
- `managerCreatedTasksProvider` - Dùng trong Manager Tasks Page (Assign Tasks tab)
- `pendingApprovalsProvider` - Dùng trong CEO Tasks Page (Approvals tab)
- `taskStatisticsProvider` - Stats overview
- `companyTaskStatisticsProvider` - Company overview

✅ Helper function:
- `refreshAllTasks(ref)` - Invalidate tất cả providers sau mutations

### 5. **UI Integration** (Đã bắt đầu)
✅ CEO Tasks Page (`lib/pages/ceo/ceo_tasks_page.dart`):
- Import providers và models
- Watch AsyncValue từ providers
- 3 tabs: Strategic Tasks, Approvals, Company Overview

⏳ **Cần hoàn thiện:** Thay thế mock data bằng AsyncValue.when()

⏳ **Manager Tasks Page** - Cần tích hợp tương tự

### 6. **Sample Data Script**
✅ `database/seed_management_tasks.py`:
- Tạo 4 sample tasks từ CEO → Manager
- Tạo 3 sample approval requests từ Manager → CEO
- **Yêu cầu:** Cần có CEO và Manager users trong database

## 🔄 Bước tiếp theo để hoàn thiện

### Immediate (Cần làm ngay):

1. **Tạo test users:**
   ```sql
   -- Trong Supabase SQL Editor
   INSERT INTO users (id, email, full_name, role) VALUES
   ('uuid-ceo', 'ceo@sabohub.com', 'CEO Test', 'ceo'),
   ('uuid-manager', 'manager@sabohub.com', 'Manager Test', 'manager');
   ```

2. **Seed sample data:**
   ```bash
   cd database
   python seed_management_tasks.py
   ```

3. **Hoàn thiện CEO Tasks Page:**
   - Wrap tabs với AsyncValue.when()
   - Handle loading state
   - Handle error state
   - Display real data from providers

4. **Tích hợp Manager Tasks Page:**
   - Import providers
   - Replace mock data
   - Wire up create/update/delete actions

### Features chưa implement:

🔜 **Create Task Dialog:**
- Form validation
- User picker (dropdown managers/staff)
- Company picker
- Date picker for due_date
- Call `createTask()` từ service

🔜 **Update Progress:**
- Slider hoặc input để cập nhật progress
- Auto-update status khi progress = 100%
- Call `updateTaskProgress()`

🔜 **Approval Actions:**
- Approve button → call `approveTaskApproval()`
- Reject button → modal nhập lý do → call `rejectTaskApproval()`
- Refresh providers sau khi approve/reject

🔜 **Real-time Updates:**
- Supabase realtime subscription cho tasks table
- Auto-refresh khi có thay đổi
- Notification khi có task mới được assigned

🔜 **Task Details Modal:**
- Full screen modal với tất cả thông tin
- Edit task inline
- Add comments
- Upload attachments

🔜 **Filters & Search:**
- Filter by priority, status, company
- Search by title/description
- Sort by due_date, created_at

## 📊 Database Schema Reference

### `tasks` table:
```sql
- id (UUID, PK)
- title (TEXT, NOT NULL)
- description (TEXT)
- priority (TEXT: critical|high|medium|low)
- status (TEXT: pending|in_progress|completed|overdue|cancelled)
- progress (INTEGER 0-100)
- due_date (TIMESTAMPTZ)
- completed_at (TIMESTAMPTZ)
- created_by (UUID, FK → users)
- assigned_to (UUID, FK → users)
- company_id (UUID, FK → companies)
- branch_id (UUID, FK → branches)
- created_at, updated_at (TIMESTAMPTZ)
```

### `task_approvals` table:
```sql
- id (UUID, PK)
- title (TEXT, NOT NULL)
- description (TEXT)
- type (TEXT: report|budget|proposal|other)
- task_id (UUID, FK → tasks, optional)
- submitted_by (UUID, FK → users)
- approved_by (UUID, FK → users)
- status (TEXT: pending|approved|rejected)
- company_id (UUID, FK → companies)
- submitted_at (TIMESTAMPTZ)
- reviewed_at (TIMESTAMPTZ)
- rejection_reason (TEXT)
- created_at, updated_at (TIMESTAMPTZ)
```

## 🎨 UI Pattern với AsyncValue

```dart
// CEO Tasks Page example
@override
Widget build(BuildContext context) {
  final tasksAsync = ref.watch(ceoStrategicTasksProvider);
  
  return tasksAsync.when(
    loading: () => Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(
      child: Text('Error: $error'),
    ),
    data: (tasks) => ListView(
      children: tasks.map((task) => TaskCard(task: task)).toList(),
    ),
  );
}
```

## 🚀 Testing Workflow

1. Đăng nhập với CEO account
2. Navigate to CEO Tasks tab (tab #2)
3. Xem strategic tasks trong tab "Nhiệm vụ chiến lược"
4. Xem pending approvals trong tab "Chờ phê duyệt"
5. Xem company overview trong tab "Tổng quan công ty"
6. Click FAB button để test create task dialog
7. Click task card để xem details

8. Đăng nhập với Manager account
9. Navigate to Manager Tasks tab (tab #2)
10. Xem tasks from CEO trong tab "Từ CEO"
11. Xem assigned tasks trong tab "Giao việc"
12. Update progress và status

## 💡 Notes

- **RLS đã enabled**: Mỗi user chỉ xem được tasks liên quan đến mình
- **Indexes đã tối ưu**: Queries sẽ nhanh ngay cả với nhiều data
- **Auto-update timestamps**: updated_at tự động update
- **Foreign keys**: Đảm bảo data integrity
- **Cascade deletes**: Xóa task → xóa comments/attachments

## 🔐 Security

- ✅ RLS policies cho tất cả tables
- ✅ Service role key chỉ dùng server-side
- ✅ Anon key cho client-side queries
- ✅ Check auth.uid() trong policies
- ✅ Role-based access (CEO, Manager, Staff)

---

**Status:** Backend hoàn thiện 90%, UI integration 30%
**Next:** Seed data → Test UI → Hoàn thiện AsyncValue integration
