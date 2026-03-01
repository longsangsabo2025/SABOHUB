# 📋 KẾ HOẠCH PHÁT TRIỂN - MANAGER TASKS PAGE

## ✅ ĐÃ HOÀN THÀNH

### 1. Cấu Trúc UI Cơ Bản
- ✅ Tạo `ManagerTasksPage` với 3 tabs
- ✅ Thêm vào Manager Bottom Navigation
- ✅ Tab Bar với icons và labels rõ ràng
- ✅ Mock data cho demonstration

### 2. Giao Diện 3 Tabs Chính

#### Tab 1: "Từ CEO" - Nhận việc từ cấp trên
**Tính năng đã có:**
- ✅ Hiển thị danh sách tasks từ CEO
- ✅ Priority badges (Cao, Trung bình, Thấp)
- ✅ Status badges (Chờ xử lý, Đang làm, Hoàn thành)
- ✅ Due date với format dd/MM/yyyy HH:mm
- ✅ Hiển thị người giao việc
- ✅ Pull to refresh

**Mock Data:**
- 3 tasks mẫu với priority khác nhau
- Assigned by "CEO Nguyễn Văn A"

#### Tab 2: "Giao việc" - Quản lý việc giao cho nhân viên
**Tính năng đã có:**
- ✅ Danh sách tasks đã giao cho staff
- ✅ Quick stats (Đang làm, Chờ xử lý, Hoàn thành)
- ✅ Hiển thị người được giao việc
- ✅ Floating Action Button để tạo task mới
- ✅ Dialog tạo task cơ bản

**Mock Data:**
- 3 tasks đã giao cho nhân viên và trưởng ca

#### Tab 3: "Việc của tôi" - Workspace cá nhân
**Tính năng đã có:**
- ✅ Danh sách công việc cá nhân
- ✅ Progress card với thanh tiến độ
- ✅ Tính % hoàn thành (8/11 = 73%)
- ✅ Gradient background đẹp mắt

**Mock Data:**
- 3 tasks cá nhân với priority khác nhau

### 3. Components Đã Xây Dựng

#### Task Card Component
**Features:**
- ✅ Priority badge với màu sắc phù hợp
- ✅ Status badge
- ✅ Title và Description
- ✅ Due date với icon
- ✅ Assigned by/to information (conditional)
- ✅ Border color theo priority
- ✅ Card elevation và shadow
- ✅ Tap to view details
- ✅ More options menu (3 dots)

#### Quick Stats Widget
- ✅ 3 stat items: Đang làm, Chờ xử lý, Hoàn thành
- ✅ Icons với màu sắc
- ✅ Container với background và border

#### Personal Progress Widget
- ✅ Gradient background (green)
- ✅ Linear progress bar
- ✅ Current/Total display
- ✅ Percentage calculation

---

## 🚀 ROADMAP PHÁT TRIỂN TIẾP THEO

### PHASE 1: Backend Integration (Ưu tiên cao)

#### 1.1 Tạo Provider cho Tasks
```dart
// lib/providers/task_provider.dart

// State cho tasks
final ceoTasksProvider = FutureProvider<List<Task>>((ref) async {
  final service = ref.watch(taskServiceProvider);
  return service.getTasksFromCEO();
});

final assignedTasksProvider = FutureProvider<List<Task>>((ref) async {
  final service = ref.watch(taskServiceProvider);
  return service.getAssignedTasks();
});

final myTasksProvider = FutureProvider<List<Task>>((ref) async {
  final service = ref.watch(taskServiceProvider);
  return service.getMyTasks();
});
```

#### 1.2 Tạo Service Layer
```dart
// lib/services/task_service.dart

class TaskService {
  final _supabase = supabase.client;
  
  // Get tasks assigned by CEO to manager
  Future<List<Task>> getTasksFromCEO() async {
    final userId = _supabase.auth.currentUser?.id;
    
    return await _supabase
      .from('tasks')
      .select('*, created_by:users!tasks_created_by_fkey(*)')
      .eq('assigned_to', userId)
      .in('created_by.role', ['ceo'])
      .order('due_date', ascending: true);
  }
  
  // Get tasks created by manager and assigned to staff
  Future<List<Task>> getAssignedTasks() async {
    final userId = _supabase.auth.currentUser?.id;
    
    return await _supabase
      .from('tasks')
      .select('*, assigned_to_user:users!tasks_assigned_to_fkey(*)')
      .eq('created_by', userId)
      .order('created_at', ascending: false);
  }
  
  // Get manager's own tasks
  Future<List<Task>> getMyTasks() async {
    final userId = _supabase.auth.currentUser?.id;
    
    return await _supabase
      .from('tasks')
      .select()
      .eq('assigned_to', userId)
      .eq('created_by', userId) // Self-assigned
      .order('due_date', ascending: true);
  }
  
  // Create new task
  Future<Task> createTask(TaskCreateDto dto) async {
    final userId = _supabase.auth.currentUser?.id;
    
    final response = await _supabase
      .from('tasks')
      .insert({
        'title': dto.title,
        'description': dto.description,
        'priority': dto.priority,
        'due_date': dto.dueDate.toIso8601String(),
        'assigned_to': dto.assignedTo,
        'created_by': userId,
        'status': 'pending',
      })
      .select()
      .single();
      
    return Task.fromJson(response);
  }
  
  // Update task status
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabase
      .from('tasks')
      .update({'status': status})
      .eq('id', taskId);
  }
  
  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _supabase
      .from('tasks')
      .delete()
      .eq('id', taskId);
  }
}
```

#### 1.3 Tạo Models
```dart
// lib/models/task.dart

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String createdBy;
  final String? assignedTo;
  final User? createdByUser;
  final User? assignedToUser;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdBy,
    this.assignedTo,
    this.createdByUser,
    this.assignedToUser,
    required this.createdAt,
    this.completedAt,
  });
  
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: TaskPriority.values.byName(json['priority']),
      status: TaskStatus.values.byName(json['status']),
      dueDate: DateTime.parse(json['due_date']),
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      createdByUser: json['created_by_user'] != null 
        ? User.fromJson(json['created_by_user']) 
        : null,
      assignedToUser: json['assigned_to_user'] != null
        ? User.fromJson(json['assigned_to_user'])
        : null,
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'])
        : null,
    );
  }
}

enum TaskPriority { low, medium, high }
enum TaskStatus { pending, in_progress, completed, overdue }
```

---

### PHASE 2: Advanced Features

#### 2.1 Task Details Dialog Enhancement
**Cần thêm:**
- [ ] Full task information display
- [ ] Comments/Notes section
- [ ] Attachments (nếu có)
- [ ] History log (status changes)
- [ ] Action buttons: Accept, Complete, Reject (for CEO tasks)
- [ ] Edit button (for assigned tasks)

#### 2.2 Create/Edit Task Form
**Form Fields:**
- [ ] Title (TextFormField)
- [ ] Description (TextArea)
- [ ] Priority dropdown (High/Medium/Low)
- [ ] Due date picker (DateTimePicker)
- [ ] Assignee selector (search staff by name/role)
- [ ] Store/Branch selector (if multi-store)
- [ ] Recurring option (daily, weekly, monthly)
- [ ] Validation logic

#### 2.3 Filters & Search
**Filter Options:**
- [ ] By priority
- [ ] By status
- [ ] By date range
- [ ] By assignee
- [ ] By store/branch

**Search:**
- [ ] Search by title
- [ ] Search by description
- [ ] Recent searches

#### 2.4 Notifications
**Push Notifications khi:**
- [ ] Được CEO giao việc mới
- [ ] Task sắp đến deadline (1 day, 1 hour)
- [ ] Task quá hạn
- [ ] Nhân viên hoàn thành task được giao
- [ ] CEO phê duyệt/từ chối task

---

### PHASE 3: Advanced Analytics

#### 3.1 Task Statistics Dashboard
**Metrics:**
- [ ] Completion rate (%)
- [ ] Average completion time
- [ ] On-time vs overdue ratio
- [ ] Tasks by priority distribution
- [ ] Top performers (staff with most completed tasks)

#### 3.2 Charts & Visualization
- [ ] Tasks completion trend (line chart)
- [ ] Priority distribution (pie chart)
- [ ] Status breakdown (bar chart)
- [ ] Weekly/Monthly comparison

---

### PHASE 4: Collaboration Features

#### 4.1 Task Comments
- [ ] Add comments to tasks
- [ ] Mention users (@username)
- [ ] Comment notifications
- [ ] Comment history

#### 4.2 Task Templates
- [ ] Save common tasks as templates
- [ ] Quick create from template
- [ ] Template categories

#### 4.3 Recurring Tasks
- [ ] Daily/Weekly/Monthly recurrence
- [ ] Custom recurrence rules
- [ ] Auto-create next instance on completion

---

### PHASE 5: Integration & Automation

#### 5.1 Calendar Integration
- [ ] View tasks in calendar view
- [ ] Sync with device calendar
- [ ] Calendar export (iCal)

#### 5.2 Workflow Automation
- [ ] Auto-assign tasks based on rules
- [ ] Status change triggers
- [ ] Reminder automation

#### 5.3 Reports
- [ ] Weekly task summary email
- [ ] Manager performance report
- [ ] Team productivity report

---

## 📊 DATABASE SCHEMA

### Table: `tasks`
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')),
  due_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id),
  assigned_to UUID REFERENCES users(id),
  store_id UUID REFERENCES stores(id),
  company_id UUID REFERENCES companies(id),
  recurring_rule JSONB, -- For recurring tasks
  parent_task_id UUID REFERENCES tasks(id), -- For subtasks
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_created_by ON tasks(created_by);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_company_id ON tasks(company_id);
```

### Table: `task_comments`
```sql
CREATE TABLE task_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  comment TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_task_comments_task_id ON task_comments(task_id);
```

### Table: `task_attachments`
```sql
CREATE TABLE task_attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  uploaded_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_task_attachments_task_id ON task_attachments(task_id);
```

---

## 🎨 UI/UX Improvements

### Priority 1: Visual Enhancements
- [ ] Add animations when marking task complete
- [ ] Swipe actions (swipe right: complete, swipe left: delete)
- [ ] Drag-and-drop to reorder tasks
- [ ] Haptic feedback on actions
- [ ] Empty state illustrations

### Priority 2: Accessibility
- [ ] Screen reader support
- [ ] High contrast mode
- [ ] Font size adjustments
- [ ] Voice commands

### Priority 3: Performance
- [ ] Pagination for large task lists
- [ ] Image lazy loading
- [ ] Offline mode với local cache
- [ ] Optimistic updates

---

## 🧪 TESTING PLAN

### Unit Tests
- [ ] TaskService methods
- [ ] Task model serialization
- [ ] Provider state management

### Widget Tests
- [ ] Task card rendering
- [ ] Tab switching
- [ ] Form validation

### Integration Tests
- [ ] Create task flow
- [ ] Complete task flow
- [ ] Filter and search

---

## 📱 RESPONSIVE DESIGN

### Tablet Layout
- [ ] Two-column layout (list + details)
- [ ] Floating task details panel
- [ ] Keyboard shortcuts

### Desktop Layout
- [ ] Three-column layout
- [ ] Sidebar navigation
- [ ] Bulk actions

---

## 🔐 SECURITY & PERMISSIONS

### RLS Policies
```sql
-- Managers can only see:
-- 1. Tasks assigned TO them
-- 2. Tasks created BY them
-- 3. Tasks for their store/company

CREATE POLICY "Managers can view relevant tasks"
ON tasks FOR SELECT
USING (
  assigned_to = auth.uid() OR
  created_by = auth.uid() OR
  store_id IN (
    SELECT store_id FROM users WHERE id = auth.uid()
  )
);
```

---

## 📝 DOCUMENTATION

### User Guide
- [ ] How to create tasks
- [ ] How to assign tasks
- [ ] How to track progress
- [ ] Best practices

### Developer Guide
- [ ] API documentation
- [ ] Component architecture
- [ ] State management flow

---

## ⏱️ TIMELINE ESTIMATE

- **Phase 1 (Backend Integration):** 2-3 days
- **Phase 2 (Advanced Features):** 3-4 days
- **Phase 3 (Analytics):** 2-3 days
- **Phase 4 (Collaboration):** 2-3 days
- **Phase 5 (Integration):** 2-3 days

**Total:** 11-16 days (2-3 sprints)

---

## 📌 IMMEDIATE NEXT STEPS

1. ✅ **Implement TaskService** - Connect to Supabase
2. ✅ **Create Task Provider** - Riverpod state management
3. ✅ **Replace mock data** - Use real data from providers
4. ✅ **Add loading states** - Show loading indicators
5. ✅ **Add error handling** - Display error messages
6. ✅ **Implement create task** - Full form with validation
7. ✅ **Implement update status** - Mark complete, in progress
8. ✅ **Add pull-to-refresh** - Already done, connect to provider
9. ✅ **Test on real data** - Create test tasks in database

---

## 🎯 SUCCESS METRICS

- ✅ Task creation time < 30 seconds
- ✅ Page load time < 2 seconds
- ✅ 90%+ task completion rate
- ✅ < 5% overdue tasks
- ✅ User satisfaction > 4/5 stars
