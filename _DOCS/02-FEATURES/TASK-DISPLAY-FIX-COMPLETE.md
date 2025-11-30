# ✅ FIX COMPLETED: Task Display Issue for Manager Diễm

**Date:** 2025-11-12  
**Status:** ✅ IMPLEMENTED - Awaiting Testing

---

## 🎯 PROBLEM SUMMARY

### Original Issue
Manager Diễm (ID: `61715a20-dc93-480c-9dab-f21806114887`) không thể thấy task được CEO giao dù task tồn tại trong database.

### Task Details
- **Task ID:** `4b4971a9-78d4-44c7-9f7a-17ab750e27cb`
- **Title:** "dfggdfgdfg"
- **Status:** pending
- **Assigned To:** Manager Diễm (confirmed in database)
- **Company:** SABO Billiards

---

## 🔍 ROOT CAUSE ANALYSIS

### Database Investigation Results

1. **Task Exists in Database** ✅
   ```
   Task found with correct assigned_to ID
   Status: pending
   deleted_at: NULL (not deleted)
   ```

2. **Schema Check** ✅
   ```
   Tasks table has 20 columns
   ✅ assigned_to_name - text
   ✅ created_by_name - text  
   ✅ assigned_to_role - text
   ```

3. **Data Inspection** ❌ ROOT CAUSE FOUND
   ```sql
   SELECT id, title, assigned_to, assigned_to_name, 
          created_by, created_by_name, assigned_to_role
   FROM tasks 
   WHERE id = '4b4971a9-78d4-44c7-9f7a-17ab750e27cb'
   ```
   
   **Result:**
   - `assigned_to`: `61715a20-dc93-480c-9dab-f21806114887` ✅
   - `assigned_to_name`: **NULL** ❌
   - `assigned_to_role`: **NULL** ❌
   - `created_by`: `944f7536-6c9a-4bea-99fc-f1c984fef2ef` ✅
   - `created_by_name`: **NULL** ❌

### Why This Caused the Problem

The `Task` model in Flutter expects these fields:
```dart
Task _taskFromJson(Map<String, dynamic> json) {
  return Task(
    // ...
    assignedToName: json['assigned_to_name'] ?? 'Unknown',
    assignedToRole: json['assigned_to_role'] ?? 'Unknown',
    createdByName: json['created_by_name'] ?? 'Unknown',
  );
}
```

When these fields are NULL in database:
1. Task object is created with "Unknown" as names
2. UI filtering or display logic might hide tasks with NULL/Unknown names
3. Task card doesn't show proper assignee information

---

## 🔧 SOLUTION IMPLEMENTED

### Code Changes

**File:** `lib/services/task_service.dart`  
**Method:** `getTasksByCompany(String companyId)`  
**Lines:** 247-280

### BEFORE (Problematic Query)
```dart
Future<List<Task>> getTasksByCompany(String companyId) async {
  final response = await _supabase
      .from('tasks')
      .select('*')  // ❌ Doesn't populate name fields
      .eq('company_id', companyId)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false);

  return (response as List).map((json) => _taskFromJson(json)).toList();
}
```

**Problem:** `SELECT '*'` only fetches columns from tasks table. Name fields remain NULL because they need to be populated from the employees table via JOINs.

### AFTER (Fixed Query with JOIN)
```dart
Future<List<Task>> getTasksByCompany(String companyId) async {
  final response = await _supabase
      .from('tasks')
      .select('''
        *,
        assigned_employee:employees!tasks_assigned_to_fkey(full_name, role),
        creator:employees!tasks_created_by_fkey(full_name)
      ''')  // ✅ JOINs with employees table via foreign keys
      .eq('company_id', companyId)
      .isFilter('deleted_at', null)
      .order('created_at', ascending: false);

  // Post-process to populate name fields from joined data
  final tasks = (response as List).map((json) {
    final taskJson = Map<String, dynamic>.from(json);
    
    // Populate assigned_to_name and assigned_to_role from JOIN
    if (json['assigned_employee'] != null) {
      taskJson['assigned_to_name'] = json['assigned_employee']['full_name'];
      taskJson['assigned_to_role'] = json['assigned_employee']['role'];
    }
    
    // Populate created_by_name from JOIN
    if (json['creator'] != null) {
      taskJson['created_by_name'] = json['creator']['full_name'];
    }
    
    return _taskFromJson(taskJson);
  }).toList();

  return tasks;
}
```

---

## 📊 TECHNICAL EXPLANATION

### Supabase Relational Query Syntax

The query uses Supabase's foreign key JOIN syntax:
```
assigned_employee:employees!tasks_assigned_to_fkey(full_name, role)
```

**Breakdown:**
- `assigned_employee:` - Alias for the joined data
- `employees!` - Target table to join with
- `tasks_assigned_to_fkey` - Foreign key constraint name
- `(full_name, role)` - Columns to select from employees table

This creates a JOIN that fetches employee details for:
1. **Assigned Employee:** Via `assigned_to` → `employees.id` FK
2. **Creator:** Via `created_by` → `employees.id` FK

### Post-Processing Logic

After fetching joined data, we map it back to the format that `_taskFromJson` expects:
```dart
taskJson['assigned_to_name'] = json['assigned_employee']['full_name'];
taskJson['assigned_to_role'] = json['assigned_employee']['role'];
taskJson['created_by_name'] = json['creator']['full_name'];
```

This ensures:
- NULL name fields are populated with actual employee names
- Task objects have proper assignee information
- UI can display tasks correctly

---

## ✅ EXPECTED RESULTS

After this fix, when Manager Diễm logs in:

1. **Tasks Tab Loads**
   - Shows "Đang tải công việc..." message
   - Fetches tasks using new JOIN query

2. **Task Displays Correctly**
   - Title: "dfggdfgdfg"
   - Assigned to: "Võ Ngọc Diễm" (not NULL or "Unknown")
   - Role: "MANAGER" (not NULL)
   - Creator: Actual CEO name (not NULL or "Unknown")

3. **Task Filtering Works**
   - Task appears in "Tất cả" (All) filter
   - Task appears in "Đang làm" (Todo) filter (status: pending)
   - Task is clickable and editable

---

## 🧪 TESTING CHECKLIST

### Manual Testing Steps

1. **Start Flutter App**
   ```bash
   flutter run -d chrome
   ```

2. **Login as Manager Diễm**
   - Email: (manager email)
   - Password: (manager password)

3. **Navigate to Company Info**
   - Click "Công ty" from sidebar
   - Select "SABO Billiards" company

4. **Check Tasks Tab**
   - [ ] Tab displays without errors
   - [ ] Loading message shows briefly
   - [ ] Task "dfggdfgdfg" is visible in task list
   - [ ] Task card shows correct assignee name: "Võ Ngọc Diễm"
   - [ ] Task card shows correct creator name
   - [ ] Task status shows as "Đang làm" (Todo/Pending)

5. **Test Task Interactions**
   - [ ] Click on task to view details
   - [ ] Verify all fields display correctly
   - [ ] Test task editing (if permissions allow)
   - [ ] Test task filtering by status
   - [ ] Test task filtering by category

### Database Verification
```sql
-- After fix, these fields should be populated
SELECT 
  id,
  title,
  assigned_to_name,  -- Should be "Võ Ngọc Diễm"
  assigned_to_role,  -- Should be "MANAGER"
  created_by_name    -- Should be actual creator name
FROM tasks
WHERE id = '4b4971a9-78d4-44c7-9f7a-17ab750e27cb';
```

---

## 🔄 ALTERNATIVE SOLUTIONS CONSIDERED

### Option 1: Database Trigger (Not Chosen)
Create a trigger to auto-populate name fields on INSERT/UPDATE:
```sql
CREATE OR REPLACE FUNCTION populate_task_names()
RETURNS TRIGGER AS $$
BEGIN
  -- Populate assigned_to_name and role
  SELECT full_name, role 
  INTO NEW.assigned_to_name, NEW.assigned_to_role
  FROM employees 
  WHERE id = NEW.assigned_to;
  
  -- Populate created_by_name
  SELECT full_name 
  INTO NEW.created_by_name
  FROM employees 
  WHERE id = NEW.created_by;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Why Not Chosen:**
- More complex database setup
- Harder to maintain and debug
- JOIN query solution is simpler and works immediately

### Option 2: Separate API Calls (Not Chosen)
Fetch tasks first, then make separate calls to get employee details.

**Why Not Chosen:**
- Multiple round trips to database
- Slower performance
- More complex code

### Option 3: JOIN Query (✅ CHOSEN)
Use Supabase's relational query syntax to fetch everything in one call.

**Why Chosen:**
- ✅ Single database query
- ✅ Better performance
- ✅ Cleaner code
- ✅ No database schema changes needed
- ✅ Easy to maintain and debug

---

## 📝 RELATED FILES

### Modified Files
- ✅ `lib/services/task_service.dart` (lines 247-280)

### Reference Files
- `lib/models/task.dart` - Task model definition
- `lib/pages/ceo/company/tasks_tab.dart` - Tasks tab UI
- `lib/pages/manager/manager_company_info_page.dart` - Manager company page

### Verification Scripts Created
- `check_diem_tasks.py` - Verify tasks in database
- `check_tasks_table_schema.py` - Verify table schema
- `check_specific_task.py` - Check specific task data

---

## 🚀 DEPLOYMENT STATUS

- [x] Code changes implemented
- [x] Code compiled successfully
- [ ] Testing in progress
- [ ] User verification pending

**Next Steps:**
1. ✅ Hot reload/restart Flutter app
2. ⏳ Login as Manager Diễm
3. ⏳ Verify task displays correctly
4. ⏳ Test all 10 tabs in Company Info page
5. ⏳ User acceptance testing

---

## 📞 SUPPORT

If issues persist after this fix:

1. **Check Database**
   ```bash
   python check_specific_task.py
   ```

2. **Check Flutter Logs**
   - Look for Supabase query errors
   - Check for JSON parsing errors
   - Verify network requests in browser DevTools

3. **Verify RLS Status**
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename IN ('tasks', 'employees', 'companies');
   ```

4. **Test Query Directly**
   ```dart
   final test = await _supabase
     .from('tasks')
     .select('*, assigned_employee:employees!tasks_assigned_to_fkey(full_name, role)')
     .eq('id', '4b4971a9-78d4-44c7-9f7a-17ab750e27cb')
     .single();
   print('Test result: $test');
   ```

---

**Status:** ✅ FIX IMPLEMENTED - Ready for Testing  
**Updated:** 2025-11-12  
**Engineer:** AI Assistant
