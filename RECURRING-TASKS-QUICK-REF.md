# 🚀 QUICK REFERENCE - RECURRING TASKS

## 📍 Vị Trí Code

```
lib/pages/ceo/company/tasks_tab.dart
├── Lines 78-95: Green button "Tạo Templates"
├── Lines 990-1180: _createTemplatesFromAI() method
├── Lines 796-809: _getCategoryColor() helper
└── Lines 1203-1210: _buildTemplateBenefit() helper
```

## 🎯 User Flow

```
CEO Dashboard 
  → Click "SABO Billiards"
    → Tab "Công việc"
      → See buttons:
        • Orange: "5 đề xuất từ AI"
        • Green: "Tạo Templates (5)" ← NEW!
      → Click Green button
        → Dialog shows 5 tasks + benefits
        → Click "Tạo 5 Templates"
        → Loading...
        → Success: "✓ Đã tạo 5 templates thành công!"
```

## 🔧 How It Works

### 1. AI Suggestions → Templates
```dart
// User clicks green button
_createTemplatesFromAI(context, ref, company, suggestedTasks)

// For each AI suggestion:
for (task in suggestedTasks) {
  TaskTemplateService.createFromAISuggestion(
    companyId: company.id,
    branchId: primaryBranch.id,
    suggestion: task,  // AI data
    createdBy: currentUser.id,
  )
}
```

### 2. Smart Detection
```dart
// Text analysis
"Vệ sinh hằng ngày" → {
  recurrence_pattern: "daily",
  scheduled_time: "08:00",
  assigned_role: "staff"
}

"Báo cáo KPI hằng tuần" → {
  recurrence_pattern: "weekly",
  scheduled_time: "09:00",
  assigned_role: "manager"
}
```

### 3. Database Storage
```sql
INSERT INTO task_templates (
  title, category, priority,
  recurrence_pattern, scheduled_time,
  assigned_role, ai_generated
) VALUES (
  'Vệ sinh bàn bi-a', 'Checklist', 'medium',
  'daily', '08:00', 'staff', true
);
```

## 📊 Database Schema Quick View

```sql
task_templates (22 columns)
├── id, company_id, branch_id
├── title, description
├── category, priority
├── recurrence_pattern ← daily/weekly/monthly
├── scheduled_time ← HH:MM
├── scheduled_days ← [1,2,3,4,5] for weekly
├── assigned_role ← ceo/manager/shift_leader/staff
├── auto_assign ← true
├── is_active ← true
├── ai_generated ← true
└── ai_confidence ← 0.85

recurring_task_instances (tracking)
├── template_id → task_templates.id
├── task_id → tasks.id
├── generated_date ← 2025-11-04
└── status ← generated/completed
```

## 🎨 UI Components

### Button Style
```dart
ElevatedButton.icon(
  icon: Icons.repeat,
  label: 'Tạo Templates (5)',
  backgroundColor: Colors.green[600], // Main color
  foregroundColor: Colors.white,
)
```

### Dialog Structure
```
┌─────────────────────────────────┐
│ 🔄 Tạo Task Templates Tự Động  │
├─────────────────────────────────┤
│ Bạn muốn tạo 5 templates?      │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ℹ️ Lợi ích:                 │ │
│ │ ✓ Tự động tạo task          │ │
│ │ ✓ Phân công đúng người      │ │
│ │ ✓ Lên lịch tự động          │ │
│ │ ✓ Giảm 80% thời gian        │ │
│ └─────────────────────────────┘ │
│                                 │
│ Danh sách:                      │
│ • Task 1 [Checklist]           │
│ • Task 2 [SOP]                 │
│ • Task 3 [KPI]                 │
│                                 │
│         [Hủy] [Tạo 5 Templates]│
└─────────────────────────────────┘
```

## 🧪 Quick Test

```bash
# 1. Start app
flutter run -d chrome

# 2. Open browser
http://127.0.0.1:55435

# 3. Navigate
CEO Dashboard → SABO Billiards → Công việc tab

# 4. Click green button → Confirm

# 5. Verify database
psql -h pooler.supabase.com -U postgres -d postgres -c \
  "SELECT COUNT(*) FROM task_templates WHERE company_id = 'xxx';"
# Expected: 5
```

## 🔍 Debug Queries

```sql
-- View all templates
SELECT id, title, recurrence_pattern, scheduled_time, is_active
FROM task_templates
WHERE company_id = 'sabo_billiards_id';

-- View AI-generated templates only
SELECT title, category, ai_confidence
FROM task_templates
WHERE ai_generated = true;

-- View active daily templates
SELECT title, scheduled_time, assigned_role
FROM task_templates
WHERE is_active = true 
  AND recurrence_pattern = 'daily';

-- Check if template exists for today
SELECT * FROM recurring_task_instances
WHERE generated_date = CURRENT_DATE;
```

## 🚨 Common Issues

### Issue 1: Button không hiện
**Nguyên nhân**: Không có AI suggestions  
**Fix**: Upload documents trước → AI analyze → Suggestions appear

### Issue 2: Template creation failed
**Nguyên nhân**: Missing branch  
**Fix**: Ensure company has at least 1 branch

### Issue 3: No templates in DB
**Nguyên nhân**: Transaction rolled back  
**Check**: Database logs, network connection

## 📱 Provider State

```dart
// Read templates
ref.watch(companyTaskTemplatesProvider(companyId))

// Refresh after creation
ref.invalidate(companyTaskTemplatesProvider(companyId))
ref.invalidate(activeTaskTemplatesProvider(companyId))
```

## 🎓 Related Docs

- Full guide: `RECURRING-TASKS-COMPLETE.md`
- Implementation: `RECURRING-TASKS-IMPLEMENTATION.md`
- Refactoring: `REFACTORING-FINAL-README.md`

---

**Quick Status**: ✅ Phase 1 Complete | ⏳ Phase 2 TODO (Auto-gen)  
**Last Updated**: 2025-11-04
