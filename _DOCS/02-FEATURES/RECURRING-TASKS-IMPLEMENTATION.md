# 🔄 Recurring Tasks Feature - Implementation Guide

## 📋 Feature Overview

**Mục tiêu:** Tự động tạo công việc hằng ngày/tuần/tháng dựa trên AI suggestions từ tài liệu đã phân tích.

**Lợi ích:**
- ✅ Tự động hóa 80% công việc lặp lại
- ✅ Không bỏ sót công việc quan trọng  
- ✅ Tự động phân công dựa trên role và ca làm việc
- ✅ AI đề xuất công việc định kỳ từ tài liệu vận hành

---

## 🎯 Current Status

### ✅ Completed:
1. **Database Schema** - `create_task_templates_table.sql`
   - `task_templates` table với recurrence patterns
   - `recurring_task_instances` table để track generated tasks
   - RLS policies và indexes

2. **Dart Model** - `lib/models/task_template.dart`
   - `TaskTemplate` class với full fields
   - `RecurrencePattern` enum (daily/weekly/monthly)
   - `AssignedRole` enum (ceo/manager/shift_leader/staff)
   - JSON serialization/deserialization

### ⏳ Pending (cần tables được tạo trước):
3. **TaskTemplateService** - CRUD operations cho templates
4. **Auto-generation Logic** - Tự động tạo tasks từ templates
5. **AI Integration** - Convert AI suggestions → TaskTemplates
6. **UI Components:**
   - Task Templates management page
   - Create/Edit template dialog
   - Enable/Disable templates
   - Preview scheduled tasks

---

## 🚀 Step 1: Create Database Tables

### Option A: Sử dụng Supabase SQL Editor (Recommended)

1. Mở Supabase Dashboard: https://supabase.com/dashboard/project/YOUR_PROJECT/sql/new

2. Copy toàn bộ nội dung file `create_task_templates_table.sql`

3. Paste vào SQL Editor và click **RUN**

4. Verify tables created:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_name IN ('task_templates', 'recurring_task_instances');
   ```

### Option B: Sử dụng Python Script (if DATABASE_URL available)

```bash
# Add to .env file:
DATABASE_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres

# Run migration:
python run_task_templates_migration.py
```

### Verify Tables Created:

```sql
-- Check task_templates table
SELECT COUNT(*) FROM task_templates;

-- Check recurring_task_instances table  
SELECT COUNT(*) FROM recurring_task_instances;
```

---

## 📊 Database Schema Details

### `task_templates` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `company_id` | UUID | Foreign key to companies |
| `branch_id` | UUID | Foreign key to branches (nullable) |
| `title` | TEXT | Template title |
| `description` | TEXT | Template description |
| `category` | TEXT | checklist/sop/kpi/training/maintenance/operations |
| `priority` | TEXT | low/medium/high/urgent |
| `recurrence_pattern` | TEXT | daily/weekly/monthly/custom |
| `scheduled_time` | TIME | Time to create task (e.g., 08:00) |
| `scheduled_days` | INTEGER[] | Day numbers [1,2,3...] |
| `assigned_role` | TEXT | ceo/manager/shift_leader/staff/any |
| `assigned_user_id` | UUID | Specific user assignment |
| `estimated_duration` | INTEGER | Duration in minutes |
| `checklist_items` | JSONB | Array of checklist items |
| `is_active` | BOOLEAN | Enable/disable template |
| `last_generated_at` | TIMESTAMP | Last task generation time |
| `ai_suggestion_id` | TEXT | Link to AI suggestion source |
| `ai_confidence` | FLOAT | AI confidence score (0-1) |

### `recurring_task_instances` Table

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `template_id` | UUID | Foreign key to task_templates |
| `task_id` | UUID | Foreign key to tasks |
| `scheduled_date` | DATE | Date task was scheduled for |

**Unique constraint:** (template_id, scheduled_date) - One task per template per day

---

## 🔄 How It Works

### 1. **AI Analyzes Documents**
```
Documents → AI Analysis → Extract recurring tasks
```

Example từ tài liệu SABO Billiards:
- "Vệ sinh bàn bida hằng ngày" → daily template
- "Kiểm tra thiết bị an toàn hằng tuần" → weekly template
- "Báo cáo KPI cuối tháng" → monthly template

### 2. **Create Templates from AI Suggestions**
```dart
// Convert AI suggestion to TaskTemplate
TaskTemplate template = TaskTemplate(
  title: "Vệ sinh bàn bida",
  description: "Lau sạch bàn, kiểm tra độ phẳng",
  category: "checklist",
  priority: "high",
  recurrencePattern: RecurrencePattern.daily,
  scheduledTime: TimeOfDay(hour: 8, minute: 0),
  assignedRole: AssignedRole.staff,
  aiSuggestionId: "doc-123-task-1",
  aiConfidence: 0.95,
);
```

### 3. **Auto-Generate Tasks**

**Trigger:** Cron job runs daily at 12:00 AM

**Logic:**
```dart
// For each active template
for (template in activeTemplates) {
  // Check if should generate for tomorrow
  if (shouldGenerateForDate(template, tomorrow)) {
    // Find employee by role and shift
    employee = findEmployeeForTemplate(template);
    
    // Create actual task
    task = createTaskFromTemplate(
      template: template,
      assignedTo: employee.id,
      scheduledDate: tomorrow,
    );
    
    // Track instance
    createRecurringInstance(
      templateId: template.id,
      taskId: task.id,
      scheduledDate: tomorrow,
    );
  }
}
```

### 4. **Employee Assignment**

**Auto-assignment rules:**
- `assigned_role = 'staff'` → Find staff working morning shift
- `assigned_role = 'shift_leader'` → Find shift leader for scheduled time
- `assigned_role = 'manager'` → Assign to branch manager
- `assigned_user_id` set → Always assign to that specific user

---

## 🎨 UI Components (To be implemented)

### 1. **Task Templates Page** (`task_templates_page.dart`)
- List all templates for company
- Filter by recurrence pattern
- Enable/disable toggle
- Edit/Delete actions

### 2. **Create Template Dialog** (`create_template_dialog.dart`)
```dart
- Title, Description input
- Category dropdown (Checklist/SOP/KPI)
- Priority picker
- Recurrence pattern picker:
  - Daily: Select time
  - Weekly: Select days [Mon, Tue, Wed...]
  - Monthly: Select dates [1, 15, 30]
- Assigned role dropdown
- Estimated duration slider
- Checklist items builder
```

### 3. **AI Suggestions → Templates Button**
In Company Details > Tasks Tab:
```dart
ElevatedButton(
  child: Text("Tạo Template từ AI (5)"),
  onPressed: () => _convertAISuggestionsToTemplates(),
)
```

### 4. **Template Preview**
Show next 7 days of scheduled tasks from templates.

---

## 📝 Example Use Cases

### Daily Tasks:
```yaml
Template: "Vệ sinh bàn bida"
Recurrence: daily
Time: 08:00 AM
Assigned: staff (morning shift)
→ Creates task every day at 8 AM for morning staff
```

### Weekly Tasks:
```yaml
Template: "Vệ sinh sâu"
Recurrence: weekly  
Days: [1] (Monday)
Time: 08:00 AM
Assigned: staff
→ Creates task every Monday at 8 AM
```

### Monthly Tasks:
```yaml
Template: "Báo cáo KPI tháng"
Recurrence: monthly
Days: [1] (1st of month)
Time: 09:00 AM
Assigned: manager
→ Creates task on 1st of each month
```

---

## 🔜 Next Steps

### After tables are created:

1. **Create TaskTemplateService** (`lib/services/task_template_service.dart`)
   - CRUD operations
   - List templates by company
   - Enable/disable template
   - Get active templates for generation

2. **Create Provider** (`lib/providers/task_template_provider.dart`)
   - companyTaskTemplatesProvider
   - activeTaskTemplatesProvider
   - Riverpod integration

3. **Implement Auto-Generation Logic**
   - Cloud Function or scheduled job
   - Check recurrence patterns
   - Find employees by role
   - Create tasks
   - Track instances

4. **Build UI Components**
   - Task Templates management page
   - Create/Edit dialogs
   - Enable/disable toggle
   - Preview calendar

5. **AI Integration**
   - Button: "Tạo Templates từ AI"
   - Parse AI suggestions
   - Detect recurrence from description
   - Create templates automatically

---

## 🎯 Success Metrics

After implementation:
- ✅ 5+ task templates created from AI analysis
- ✅ Daily tasks auto-generated at midnight
- ✅ 80% reduction in manual task creation
- ✅ 100% coverage of recurring operational tasks
- ✅ Employees see their daily tasks when they login

---

## 📚 Files Created

1. `create_task_templates_table.sql` - Database schema
2. `lib/models/task_template.dart` - Dart model
3. `RECURRING-TASKS-IMPLEMENTATION.md` - This document

### To be created:
4. `lib/services/task_template_service.dart`
5. `lib/providers/task_template_provider.dart`
6. `lib/pages/ceo/task_templates_page.dart`
7. `lib/widgets/create_template_dialog.dart`

---

## 🤝 Ready to Continue?

**Immediate action needed:**
1. ✅ Run SQL in Supabase Dashboard
2. ✅ Verify tables created
3. ✅ Let me know when ready

Then I'll implement:
- TaskTemplateService
- UI components
- AI integration
- Auto-generation logic

---

**Status:** 🟡 Waiting for database tables to be created
**Next:** 🚀 Implement service layer and UI components
