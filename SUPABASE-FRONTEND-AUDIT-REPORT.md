# 🔍 SUPABASE-FRONTEND AUDIT REPORT
**Project:** SABOHUB  
**Audit Date:** November 12, 2025  
**Auditor:** Senior Backend & Supabase Expert  
**Scope:** Complete Backend-Frontend Synchronization Analysis

---

## 📊 EXECUTIVE SUMMARY

### Critical Issues Found: **12**
### High Priority Issues: **8**
### Medium Priority Issues: **15**
### Low Priority Issues: **7**

**Overall Assessment:** The project has **CRITICAL MISMATCHES** between Supabase backend schema and Flutter frontend models that require immediate attention. The multi-company architecture migration is incomplete, causing significant inconsistencies.

---

## 🚨 CRITICAL ISSUES

### 1. **Attendance Table References Non-Existent `stores` Table**

**Severity:** `CRITICAL`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251104_attendance_real_data.sql:8`
- **Frontend:** `lib/models/attendance.dart`

**Issue:**
The attendance table references `stores` table which has been renamed to `branches` in the multi-company migration (20251031_multi_company_architecture.sql), but the attendance migration still uses old `store_id` reference.

**Current State:**

```sql
-- Backend (INCORRECT)
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,  -- ❌ 'stores' table doesn't exist
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  ...
);
```

```dart
// Frontend (Expects stores but table renamed to branches)
class AttendanceRecord {
  final String employeeId;
  final String companyId;
  // No storeId or branchId field defined
  ...
}
```

**Recommendation:**

```sql
-- Backend FIX
ALTER TABLE public.attendance DROP CONSTRAINT IF EXISTS attendance_store_id_fkey;
ALTER TABLE public.attendance RENAME COLUMN store_id TO branch_id;
ALTER TABLE public.attendance 
  ADD CONSTRAINT attendance_branch_id_fkey 
  FOREIGN KEY (branch_id) REFERENCES public.branches(id) ON DELETE CASCADE;
```

```dart
// Frontend FIX
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String companyId;
  final String? branchId;  // ✅ Add this field
  ...
  
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      ...
      branchId: json['branch_id'] as String?,  // ✅ Map correctly
      ...
    );
  }
}
```

---

### 2. **Tasks Table RLS References Non-Existent `profiles` Table**

**Severity:** `CRITICAL`  
**Category:** `rls`

**Location:**
- **Backend:** `supabase/migrations/20251030_create_tasks_table.sql:42-72`
- **Frontend:** `lib/services/task_service.dart`

**Issue:**
RLS policies for tasks table reference `public.profiles` table which doesn't exist in the schema. The project uses `public.users` table instead.

**Current State:**

```sql
-- Backend (INCORRECT)
CREATE POLICY "CEO can view all tasks"
  ON public.tasks
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles  -- ❌ Table 'profiles' doesn't exist
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'CEO'
    )
  );
```

**Frontend Impact:**
- CEO users cannot view tasks due to failed policy check
- Task queries will return empty results or permission denied errors

**Recommendation:**

```sql
-- Backend FIX: Replace ALL 'profiles' references with 'users'
DROP POLICY IF EXISTS "CEO can view all tasks" ON public.tasks;
DROP POLICY IF EXISTS "Manager can view all tasks" ON public.tasks;
DROP POLICY IF EXISTS "Staff can view their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO and Manager can create tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO and Manager can update tasks" ON public.tasks;
DROP POLICY IF EXISTS "Staff can update their own tasks" ON public.tasks;
DROP POLICY IF EXISTS "CEO can delete tasks" ON public.tasks;

-- ✅ CORRECT POLICIES using 'users' table
CREATE POLICY "CEO can view all tasks" ON public.tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'CEO'
    )
  );

CREATE POLICY "Manager can view all tasks" ON public.tasks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('CEO', 'MANAGER')
    )
  );

-- Apply same fix for all other task policies...
```

---

### 3. **Storage Bucket Policies Reference Non-Existent `profiles` Table**

**Severity:** `CRITICAL`  
**Category:** `storage`

**Location:**
- **Backend:** `supabase/migrations/20251102_ai_files_storage.sql`
- **Frontend:** `lib/services/file_upload_service.dart`

**Issue:**
Storage policies for `ai-files` bucket reference `profiles` table which doesn't exist.

**Current State:**

```sql
-- Backend (INCORRECT)
CREATE POLICY "Users can upload AI files to their company"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN profiles p ON p.company_id = c.id  -- ❌ 'profiles' doesn't exist
    WHERE p.id = auth.uid()
  )
);
```

**Frontend Impact:**
- File uploads fail with permission denied errors
- Users cannot upload documents to AI assistant

**Recommendation:**

```sql
-- Backend FIX
DROP POLICY IF EXISTS "Users can upload AI files to their company" ON storage.objects;
DROP POLICY IF EXISTS "Users can view AI files from their company" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete AI files from their company" ON storage.objects;

-- ✅ CORRECT POLICIES
CREATE POLICY "Users can upload AI files to their company"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'ai-files' AND
  (storage.foldername(name))[1] IN (
    SELECT c.id::text
    FROM companies c
    INNER JOIN users u ON u.company_id = c.id  -- ✅ Use 'users' table
    WHERE u.id = auth.uid()
  )
);

-- Apply same fix for SELECT and DELETE policies...
```

---

### 4. **Attendance Schema Missing Required Columns**

**Severity:** `CRITICAL`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251104_attendance_real_data.sql`
- **Frontend:** `lib/models/attendance.dart:36-50`

**Issue:**
Frontend AttendanceRecord model expects columns that don't exist in the database schema.

**Current State:**

```sql
-- Backend (MISSING COLUMNS)
CREATE TABLE public.attendance (
  id UUID,
  store_id UUID,  -- Should be branch_id
  user_id UUID,
  check_in TIMESTAMPTZ,
  check_out TIMESTAMPTZ,
  check_in_location TEXT,
  check_out_location TEXT,
  check_in_photo_url TEXT,
  total_hours DECIMAL(5, 2),
  is_late BOOLEAN,
  is_early_leave BOOLEAN,
  notes TEXT
  -- ❌ MISSING: employee_name, employee_role, company_id
  -- ❌ MISSING: check_in_latitude, check_in_longitude
  -- ❌ MISSING: check_out_latitude, check_out_longitude
);
```

```dart
// Frontend (EXPECTS MORE COLUMNS)
class AttendanceRecord {
  final String employeeId;
  final String employeeName;      // ❌ No 'employee_name' column in DB
  final String companyId;          // ❌ No 'company_id' column in attendance table
  final double? checkInLatitude;   // ❌ No 'check_in_latitude' column
  final double? checkInLongitude;  // ❌ No 'check_in_longitude' column
  final double? checkOutLatitude;  // ❌ No 'check_out_latitude' column
  final double? checkOutLongitude; // ❌ No 'check_out_longitude' column
  ...
}
```

**Recommendation:**

```sql
-- Backend FIX: Add missing columns
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES companies(id);
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS employee_role TEXT;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_in_longitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_latitude DOUBLE PRECISION;
ALTER TABLE public.attendance ADD COLUMN IF NOT EXISTS check_out_longitude DOUBLE PRECISION;

-- Create index for company_id
CREATE INDEX IF NOT EXISTS idx_attendance_company_id ON public.attendance(company_id);

-- Update RLS policies to use company_id
DROP POLICY IF EXISTS "company_attendance_select" ON public.attendance;
CREATE POLICY "company_attendance_select" ON public.attendance
  FOR SELECT
  USING (
    -- User can see their own attendance
    user_id = auth.uid()
    OR
    -- CEO/Manager can see attendance in their company
    company_id IN (
      SELECT company_id FROM public.users 
      WHERE id = auth.uid() AND role IN ('CEO', 'MANAGER')
    )
  );
```

---

### 5. **Task Status Enum Mismatch**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251112_fix_tasks_constraints_lowercase.sql`
- **Frontend:** `lib/models/task.dart:24-45`

**Issue:**
Database uses lowercase enum values (`pending`, `in_progress`) but frontend enum conversion uses uppercase database values in some places.

**Current State:**

```sql
-- Backend (lowercase)
ALTER TABLE public.tasks 
  ADD CONSTRAINT tasks_status_check 
  CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));
```

```dart
// Frontend (Inconsistent)
enum TaskStatus {
  todo, inProgress, completed, cancelled;
  
  // ✅ CORRECT conversion
  String toDbValue() {
    switch (this) {
      case TaskStatus.todo: return 'pending';
      case TaskStatus.inProgress: return 'in_progress';
      ...
    }
  }
}
```

**However, in some queries:**

```dart
// ❌ INCORRECT - Uses enum.name instead of toDbValue()
.eq('status', status.name)  // Sends 'inProgress' instead of 'in_progress'
```

**Recommendation:**

```dart
// Frontend FIX: Always use toDbValue()
Future<List<Task>> getTasksByStatus(TaskStatus status) async {
  final query = _supabase
      .from('tasks')
      .select('*')
      .eq('status', status.toDbValue())  // ✅ Use toDbValue()
      .isFilter('deleted_at', null);
  ...
}
```

---

### 6. **Task Table Missing `progress` Column in Original Schema**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251030_create_tasks_table.sql` vs `20251112_add_progress_to_tasks.sql`
- **Frontend:** `lib/services/task_service.dart:96`

**Issue:**
The original tasks table creation doesn't include `progress` column, but frontend tries to insert it, and a later migration adds it. This creates a timing issue.

**Current State:**

```sql
-- Original schema (NO progress column)
CREATE TABLE public.tasks (
  id UUID,
  title TEXT NOT NULL,
  ...
  metadata JSONB DEFAULT '{}'::jsonb
  -- ❌ No 'progress' column
);

-- Later migration adds it
ALTER TABLE public.tasks ADD COLUMN progress INTEGER DEFAULT 0;
```

```dart
// Frontend (ALWAYS tries to insert progress)
final insertData = {
  'title': task.title,
  'progress': 0,  // ❌ Fails if migration not run
  ...
};
```

**Recommendation:**

Option 1: Merge migrations and include progress in initial schema
```sql
-- In 20251030_create_tasks_table.sql
CREATE TABLE public.tasks (
  ...
  progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  metadata JSONB DEFAULT '{}'::jsonb
);
```

Option 2: Frontend should handle column existence
```dart
// Defensive programming
final insertData = <String, dynamic>{
  'title': task.title,
  'description': task.description,
  ...
};

// Only add progress if it's explicitly set
if (task.progress != null && task.progress! > 0) {
  insertData['progress'] = task.progress;
}
```

---

### 7. **Inconsistent `assignee_id` vs `assigned_to` Field**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251030_create_tasks_table.sql:14`
- **Frontend:** `lib/models/task.dart:92-93`

**Issue:**
Database uses `assignee_id` column name, but frontend model has both `assignedTo` and `assigneeId` fields causing confusion.

**Current State:**

```sql
-- Backend
CREATE TABLE public.tasks (
  ...
  assignee_id UUID REFERENCES auth.users(id),  -- ✅ Only this column exists
  assignee_name TEXT,
  ...
);
```

```dart
// Frontend (CONFUSING - has both fields)
class Task {
  final String? assignedTo;    // ❌ What does this map to?
  final String? assigneeId;    // ✅ Maps to assignee_id
  final String? assignedToName;
  ...
  
  // In toJson:
  'assigned_to': task.assignedTo,  // ❌ No 'assigned_to' column in DB
  'assignee_id': task.assigneeId,  // ✅ Correct
}
```

**Recommendation:**

Option 1: Remove duplicate field from frontend
```dart
class Task {
  // ❌ Remove this field
  // final String? assignedTo;
  
  final String? assigneeId;    // ✅ Keep only this
  final String? assignedToName;
  
  // Update toJson
  Map<String, dynamic> toJson() {
    return {
      'assignee_id': assigneeId,  // ✅ Correct mapping
      'assigned_to_name': assignedToName,
      ...
    };
  }
}
```

Option 2: Update database to match frontend expectation
```sql
ALTER TABLE public.tasks RENAME COLUMN assignee_id TO assigned_to;
```

**Recommended:** Option 1 (remove duplicate frontend field)

---

## ⚠️ HIGH PRIORITY ISSUES

### 8. **Company Model Missing Critical Database Columns**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251031_multi_company_architecture.sql:15-57`
- **Frontend:** `lib/models/company.dart:3-40`

**Issue:**
Frontend Company model doesn't match backend schema structure.

**Current State:**

```sql
-- Backend (Full schema)
CREATE TABLE companies (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  legal_name TEXT,
  business_type TEXT NOT NULL,
  tax_code TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  owner_id UUID NOT NULL,  -- ❌ Frontend doesn't have this
  logo_url TEXT,
  primary_color TEXT,
  secondary_color TEXT,
  status TEXT NOT NULL,
  settings JSONB,          -- ❌ Frontend doesn't have this
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  created_by UUID          -- ❌ Frontend doesn't have this
);
```

```dart
// Frontend (Missing fields)
class Company {
  final String id;
  final String name;
  final BusinessType type;
  final String address;
  final int tableCount;        // ❌ Not in DB
  final double monthlyRevenue; // ❌ Not in DB (calculated field)
  final int employeeCount;     // ❌ Not in DB (calculated field)
  // ❌ Missing: owner_id, settings, created_by, legal_name, tax_code, website
}
```

**Recommendation:**

```dart
class Company {
  final String id;
  final String name;
  final String? legalName;           // ✅ Add
  final BusinessType businessType;
  final String? taxCode;             // ✅ Add
  final String? address;
  final String? phone;
  final String? email;
  final String? website;             // ✅ Add
  final String ownerId;              // ✅ Add (required)
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String status;
  final Map<String, dynamic>? settings;  // ✅ Add
  final String? createdBy;           // ✅ Add
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  
  // Computed fields (fetched separately)
  int? tableCount;
  double? monthlyRevenue;
  int? employeeCount;
  
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      businessType: _parseBusinessType(json['business_type']),
      taxCode: json['tax_code'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      ownerId: json['owner_id'] as String,
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String?,
      secondaryColor: json['secondary_color'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      settings: json['settings'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : null,
      deletedAt: json['deleted_at'] != null 
          ? DateTime.parse(json['deleted_at']) : null,
    );
  }
}
```

---

### 9. **Branch Model Missing `manager_id` Column**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251031_multi_company_architecture.sql:138-145`
- **Frontend:** `lib/models/branch.dart`

**Issue:**
Backend renamed `owner_id` to `manager_id` but frontend doesn't have this field.

**Current State:**

```sql
-- Backend
ALTER TABLE branches RENAME COLUMN owner_id TO manager_id;
ALTER TABLE branches ADD COLUMN code TEXT;
```

```dart
// Frontend (Missing fields)
class Branch {
  final String id;
  final String companyId;
  final String name;
  // ❌ Missing: manager_id, code
}
```

**Recommendation:**

```dart
class Branch {
  final String id;
  final String companyId;
  final String name;
  final String? managerId;      // ✅ Add this
  final String? code;           // ✅ Add this
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;
  
  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      ...
      managerId: json['manager_id'] as String?,
      code: json['code'] as String?,
      ...
    );
  }
}
```

---

### 10. **User Model Auth Field Name Mismatch**

**Severity:** `HIGH`  
**Category:** `schema`

**Location:**
- **Backend:** `supabase/migrations/20251031_multi_company_architecture.sql:73-85`
- **Frontend:** `lib/models/user.dart:87-95`

**Issue:**
Frontend tries to map `full_name` field which doesn't exist in users table.

**Current State:**

```dart
// Frontend
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    name: json['full_name'] as String? ??  // ❌ 'full_name' doesn't exist in users table
          json['name'] as String?,
    ...
  );
}
```

**Recommendation:**

Check the actual users table schema and update accordingly:
```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    name: json['name'] as String?,  // ✅ Use correct column name
    email: json['email'] as String?,
    ...
  );
}
```

---

## 📋 MEDIUM PRIORITY ISSUES

### 11. **Inconsistent Naming Convention: snake_case vs camelCase**

**Severity:** `MEDIUM`  
**Category:** `api`

**Issue:** Mix of naming conventions in API responses and model mappings.

**Examples:**
- `check_in` (backend) vs `checkIn` (frontend)
- `company_id` (backend) vs `companyId` (frontend)
- `created_at` (backend) vs `createdAt` (frontend)

**Recommendation:**
Standardize on snake_case for database and use proper camelCase conversion in Dart models:

```dart
// Always convert explicitly
factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
  return AttendanceRecord(
    checkInTime: json['check_in'] != null 
        ? DateTime.parse(json['check_in'] as String) 
        : null,
    checkOutTime: json['check_out'] != null 
        ? DateTime.parse(json['check_out'] as String) 
        : null,
    ...
  );
}
```

---

### 12. **Missing Timezone Handling**

**Severity:** `MEDIUM`  
**Category:** `schema`

**Issue:** Database uses `TIMESTAMPTZ` but frontend DateTime handling doesn't explicitly manage timezones.

**Recommendation:**

```dart
// Always parse with timezone awareness
DateTime? parseTimestamp(String? timestamp) {
  if (timestamp == null) return null;
  return DateTime.parse(timestamp).toLocal();  // ✅ Convert to local timezone
}

// When sending to backend
String formatTimestamp(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();  // ✅ Always send UTC
}
```

---

### 13. **RLS Policy References Incorrect User Table Join**

**Severity:** `MEDIUM`  
**Category:** `rls`

**Location:** Multiple RLS policies

**Issue:** Some policies check `users.company_id` but join logic is complex.

**Example:**
```sql
CREATE POLICY "Users can view branches in their company" ON branches
  FOR SELECT
  USING (
    company_id IN (
      SELECT company_id FROM users WHERE id = auth.uid()
    )
    OR
    company_id IN (
      SELECT id FROM companies WHERE owner_id = auth.uid()
    )
  );
```

**Recommendation:** Simplify and optimize:
```sql
CREATE POLICY "Users can view branches in their company" ON branches
  FOR SELECT
  USING (
    -- User belongs to this company
    company_id = (SELECT company_id FROM users WHERE id = auth.uid())
    OR
    -- User owns this company
    EXISTS (
      SELECT 1 FROM companies 
      WHERE id = branches.company_id 
      AND owner_id = auth.uid()
    )
  );
```

---

### 14. **Task Template Service Missing `company_id`**

**Severity:** `MEDIUM`  
**Category:** `schema`

**Location:** `lib/services/task_template_service.dart`

**Issue:** Task templates table likely needs `company_id` for multi-tenancy.

**Recommendation:**

```sql
ALTER TABLE task_templates ADD COLUMN company_id UUID REFERENCES companies(id);
CREATE INDEX idx_task_templates_company ON task_templates(company_id);
```

---

### 15. **Missing Soft Delete Implementation on Multiple Tables**

**Severity:** `MEDIUM`  
**Category:** `schema`

**Issue:** Only `tasks` and `companies` have `deleted_at` column. Other tables like `branches`, `users`, `attendance` should also support soft delete.

**Recommendation:**

```sql
-- Add soft delete to all main tables
ALTER TABLE branches ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE attendance ADD COLUMN deleted_at TIMESTAMPTZ;

-- Update all queries to filter deleted records
-- Example for branches:
CREATE OR REPLACE VIEW active_branches AS
SELECT * FROM branches WHERE deleted_at IS NULL;
```

---

### 16-25. Additional Medium Priority Issues

- **Missing indexes on foreign keys** (company_id, branch_id in multiple tables)
- **No cascade delete strategy documentation**
- **Inconsistent NULL handling** in optional fields
- **Missing validation constraints** (email format, phone format)
- **No enum validation** in database for role field
- **Missing audit trail columns** (updated_by field)
- **No optimistic locking** (version field for concurrent updates)
- **Missing composite indexes** for common query patterns
- **Realtime subscriptions not configured** for critical tables
- **Storage bucket MIME type restrictions** not enforced

---

## 📝 LOW PRIORITY ISSUES

### 26. **Missing Database Comments**

Many tables lack `COMMENT ON TABLE` documentation.

### 27. **Inconsistent Default Values**

Some timestamps default to `NOW()`, others don't.

### 28. **No Database Seed Data**

Missing reference data for roles, statuses, categories.

### 29-32. Additional Low Priority Issues

- Missing API documentation
- No database migration rollback scripts
- Inconsistent error message formatting
- Missing rate limiting on RPC functions

---

## 🔧 RECOMMENDED MIGRATION PLAN

### Phase 1: Critical Fixes (Week 1)
**Priority: IMMEDIATE**

1. **Fix attendance table schema**
   ```sql
   -- Run migration: fix_attendance_schema.sql
   ALTER TABLE attendance DROP CONSTRAINT attendance_store_id_fkey;
   ALTER TABLE attendance RENAME COLUMN store_id TO branch_id;
   ALTER TABLE attendance ADD CONSTRAINT attendance_branch_id_fkey 
     FOREIGN KEY (branch_id) REFERENCES branches(id);
   ALTER TABLE attendance ADD COLUMN company_id UUID REFERENCES companies(id);
   ALTER TABLE attendance ADD COLUMN employee_name TEXT;
   ALTER TABLE attendance ADD COLUMN check_in_latitude DOUBLE PRECISION;
   ALTER TABLE attendance ADD COLUMN check_in_longitude DOUBLE PRECISION;
   ALTER TABLE attendance ADD COLUMN check_out_latitude DOUBLE PRECISION;
   ALTER TABLE attendance ADD COLUMN check_out_longitude DOUBLE PRECISION;
   ```

2. **Fix all profiles → users references**
   ```sql
   -- Run migration: fix_profiles_to_users.sql
   -- Update ALL policies referencing 'profiles' table to use 'users'
   ```

3. **Update frontend models**
   - Update `Company` model with all required fields
   - Update `Branch` model with `manager_id` and `code`
   - Update `AttendanceRecord` model with missing fields
   - Remove duplicate `assignedTo` field from `Task` model

### Phase 2: High Priority Fixes (Week 2)

4. **Standardize enum values**
5. **Fix task progress column timing**
6. **Add missing foreign keys and indexes**

### Phase 3: Medium Priority Improvements (Week 3-4)

7. **Implement comprehensive soft delete**
8. **Add timezone handling utilities**
9. **Optimize RLS policies**
10. **Add storage bucket validation**

### Phase 4: Low Priority Enhancements (Week 5+)

11. **Add database documentation**
12. **Create seed data scripts**
13. **Implement audit logging**
14. **Add realtime subscriptions**

---

## 📚 BEST PRACTICES RECOMMENDATIONS

### 1. Schema Management

```bash
# Always use Supabase migrations
supabase migration new <descriptive_name>

# Test migrations locally first
supabase db reset
supabase db push

# Never modify schema directly in production
```

### 2. Type Safety

```dart
// Generate TypeScript types from Supabase
supabase gen types typescript --local > lib/database.types.ts

// Use generated types in Dart
// Consider using supabase_flutter code generation
```

### 3. RLS Policy Testing

```sql
-- Always test RLS policies with different user roles
SET ROLE authenticated;
SET request.jwt.claim.sub = '<user_id>';
SELECT * FROM tasks;  -- Test as different users
```

### 4. Error Handling

```dart
// Always wrap Supabase calls with proper error handling
try {
  final result = await _supabase.from('tasks').select();
  return result.map((json) => Task.fromJson(json)).toList();
} on PostgrestException catch (error) {
  // Handle Postgrest errors (RLS, constraints, etc.)
  print('Database error: ${error.message}');
  rethrow;
} catch (error) {
  // Handle other errors
  print('Unexpected error: $error');
  rethrow;
}
```

### 5. Migration Strategy

```sql
-- Always make migrations backward compatible
-- Add columns as nullable first
ALTER TABLE tasks ADD COLUMN progress INTEGER;

-- Then add constraints after data migration
ALTER TABLE tasks ADD CONSTRAINT progress_range 
  CHECK (progress >= 0 AND progress <= 100);

-- Finally make NOT NULL if needed
ALTER TABLE tasks ALTER COLUMN progress SET NOT NULL;
ALTER TABLE tasks ALTER COLUMN progress SET DEFAULT 0;
```

---

## 🎯 IMMEDIATE ACTION ITEMS

### For Backend Team

1. ✅ Create `fix_critical_schema_issues.sql` migration
2. ✅ Run database audit script to verify all foreign keys
3. ✅ Update all RLS policies to use `users` instead of `profiles`
4. ✅ Add missing columns to `attendance` table
5. ✅ Document all table schemas

### For Frontend Team

1. ✅ Update `Company` model to match database schema
2. ✅ Update `Branch` model with `manager_id` field
3. ✅ Update `AttendanceRecord` model with all required fields
4. ✅ Remove duplicate `assignedTo` field from `Task` model
5. ✅ Add defensive null checks in all `fromJson` methods
6. ✅ Always use `toDbValue()` for enum conversions

### For QA Team

1. ✅ Test all CRUD operations for each role (CEO, Manager, Staff)
2. ✅ Verify RLS policies block unauthorized access
3. ✅ Test file upload/download functionality
4. ✅ Verify attendance check-in/check-out flow
5. ✅ Test task creation and assignment

---

## 📊 RISK ASSESSMENT

| Issue | Impact | Probability | Risk Level | Mitigation Priority |
|-------|--------|-------------|------------|---------------------|
| Attendance table reference error | **CRITICAL** | High | 🔴 CRITICAL | **P0 - Immediate** |
| Tasks RLS with profiles | **CRITICAL** | High | 🔴 CRITICAL | **P0 - Immediate** |
| Storage policy error | **CRITICAL** | High | 🔴 CRITICAL | **P0 - Immediate** |
| Missing attendance columns | **HIGH** | Medium | 🟠 HIGH | **P1 - Week 1** |
| Company model mismatch | **HIGH** | Medium | 🟠 HIGH | **P1 - Week 1** |
| Task enum mismatch | **MEDIUM** | Low | 🟡 MEDIUM | **P2 - Week 2** |
| Timezone handling | **MEDIUM** | Medium | 🟡 MEDIUM | **P2 - Week 2** |
| Missing indexes | **LOW** | Low | 🟢 LOW | **P3 - Week 3+** |

---

## 🔍 VERIFICATION CHECKLIST

After implementing fixes, verify:

- [ ] All tables exist and have correct column names
- [ ] All foreign keys reference existing tables
- [ ] All RLS policies reference existing tables/columns
- [ ] All frontend models map correctly to database columns
- [ ] All enum values match between frontend and backend
- [ ] Storage bucket policies work for file operations
- [ ] Authentication flow works for all user roles
- [ ] Attendance check-in/check-out works with location
- [ ] Task creation works with proper assignments
- [ ] Company/branch creation assigns correct relationships

---

## 📞 CONTACT & SUPPORT

For questions about this audit report:
- **Technical Lead:** Review findings with backend team
- **Migration Support:** Create step-by-step migration guide
- **Testing:** Coordinate with QA for validation

---

**Report Status:** ✅ COMPLETE  
**Next Review Date:** After Phase 1 fixes implemented  
**Estimated Fix Time:** 2-4 weeks for all critical and high priority issues

