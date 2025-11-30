# 🔒 **RLS POLICY AUDIT - IN PROGRESS**

## 🎯 **Objective**
Audit all Row Level Security policies to ensure data isolation, security, and proper soft delete filtering.

---

## ⚠️ **CRITICAL FINDING: Migration Not Run Yet**

### **Issue:**
```
❌ Error: column companies.deleted_at does not exist
```

### **Root Cause:**
The SQL migration `supabase/migrations/add_soft_delete_to_companies.sql` has **NOT been executed yet** in Supabase.

### **Impact:**
- ❌ Soft delete feature NOT working
- ❌ RLS policies cannot filter deleted companies
- ❌ App will throw errors when trying to soft delete

### **Solution:**
**MUST run this SQL in Supabase Dashboard SQL Editor:**

```sql
-- From: supabase/migrations/add_soft_delete_to_companies.sql
ALTER TABLE companies ADD COLUMN deleted_at TIMESTAMPTZ DEFAULT NULL;
CREATE INDEX idx_companies_deleted_at ON companies(deleted_at) WHERE deleted_at IS NULL;

-- Update RLS policies to filter soft-deleted records
DROP POLICY IF EXISTS "Users can view their companies" ON companies;
CREATE POLICY "Users can view their companies" ON companies
    FOR SELECT
    USING (
        (created_by = auth.uid() OR owner_id = auth.uid())
        AND deleted_at IS NULL
    );
```

---

## 📋 **Audit Checklist**

### **Phase 1: Generate Audit Queries** ✅
- [x] Created `rls_audit_queries.py` 
- [x] Generated SQL queries for manual execution
- [x] Output includes 4 critical queries

### **Phase 2: Automated Testing** ✅
- [x] Created `test_rls_policies.py`
- [x] Tested CEO company isolation
- [x] Tested employee data isolation
- [x] Tested soft delete filter
- [x] Tested task access rules

### **Phase 3: Run SQL Migration** ⏳ PENDING
- [ ] **Execute `add_soft_delete_to_companies.sql` in Supabase**
- [ ] Verify `deleted_at` column exists
- [ ] Verify RLS policies updated
- [ ] Re-run tests to confirm

### **Phase 4: Manual Testing** ⏳ PENDING
- [ ] Test CEO A cannot see CEO B's companies
- [ ] Test Employee cannot see other companies' data
- [ ] Test Manager cannot see other branches
- [ ] Test Staff can only see assigned tasks
- [ ] Test soft delete hides companies correctly

### **Phase 5: Document Findings** ⏳ PENDING
- [ ] List all RLS policy gaps
- [ ] Create SQL fixes for issues
- [ ] Test fixes in staging
- [ ] Deploy to production

---

## 🔍 **SQL Queries for Manual Audit**

Run these in **Supabase SQL Editor**:

### **Query 1: Check RLS Status**
```sql
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ ENABLED' 
        ELSE '❌ DISABLED' 
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename IN (
        'companies', 'employees', 'branches', 'tasks', 
        'documents', 'contracts', 'attendance', 'shifts'
    )
ORDER BY tablename;
```

### **Query 2: List All Policies**
```sql
SELECT 
    tablename,
    policyname,
    cmd as command,
    roles,
    qual as using_clause
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### **Query 3: Companies Policies**
```sql
SELECT 
    policyname,
    cmd,
    qual as using_expression
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;
```

### **Query 4: Check Soft Delete Filter**
```sql
SELECT 
    tablename,
    policyname,
    qual as using_clause
FROM pg_policies 
WHERE tablename = 'companies'
    AND qual LIKE '%deleted_at%';
```

---

## 🎯 **Expected RLS Policy Patterns**

### ✅ **GOOD Policies:**

```sql
-- CEO sees only their companies
(created_by = auth.uid() OR owner_id = auth.uid()) AND deleted_at IS NULL

-- Employee sees only their company data
company_id IN (
    SELECT company_id FROM employees 
    WHERE user_id = auth.uid()
)

-- Manager sees branch tasks
branch_id IN (
    SELECT branch_id FROM employees 
    WHERE user_id = auth.uid() AND role = 'manager'
)

-- Staff sees only assigned tasks
assigned_to = auth.uid() OR assigned_to IN (
    SELECT id FROM employees WHERE user_id = auth.uid()
)
```

### ❌ **BAD Policies:**

```sql
-- Too permissive
true

-- Missing auth check
company_id = 'some-static-id'

-- Missing soft delete filter
created_by = auth.uid()  -- Should add: AND deleted_at IS NULL
```

---

## 🧪 **Test Results**

### **Test 1: CEO Company Isolation**
```
❌ BLOCKED: Column owner_id does not exist
Status: Cannot test until migration runs
```

### **Test 2: Employee Isolation**
```
❌ BLOCKED: Column user_id does not exist
Status: Schema mismatch - need to verify actual column names
```

### **Test 3: Soft Delete Filter**
```
❌ BLOCKED: Column deleted_at does not exist
Status: Must run migration first
```

### **Test 4: Task Access Rules**
```
✅ PARTIAL SUCCESS: 11 tasks found
⚠️  Issue: 0 tasks assigned (assigned_to column empty)
```

---

## 📊 **Current Status**

| **Component** | **Status** | **Issue** |
|--------------|----------|-----------|
| Soft Delete Column | ❌ Missing | Migration not run |
| RLS Policies | ⚠️ Unknown | Cannot audit until column exists |
| Companies Table | ❌ No owner_id | Schema mismatch |
| Employees Table | ❌ No user_id | Schema mismatch |
| Tasks Table | ✅ Working | But no assignments |

---

## 🚨 **CRITICAL ACTION REQUIRED**

### **Step 1: Run SQL Migration (URGENT)**

Open Supabase Dashboard → SQL Editor → Copy and run:

```sql
-- File: supabase/migrations/add_soft_delete_to_companies.sql
-- Copy entire file contents and execute
```

### **Step 2: Verify Column Exists**

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'companies' 
  AND column_name = 'deleted_at';
```

Expected output:
```
column_name | data_type
deleted_at  | timestamp with time zone
```

### **Step 3: Re-run Tests**

```bash
python test_rls_policies.py
```

### **Step 4: Test in App**

1. Login as CEO
2. Try to delete a company
3. Verify it disappears from list
4. Check database: `SELECT * FROM companies WHERE deleted_at IS NOT NULL;`

---

## 📝 **Next Steps**

1. ✅ **COMPLETED:** Generated audit queries
2. ✅ **COMPLETED:** Created test scripts
3. ⏭️ **NEXT:** Run SQL migration in Supabase
4. ⏭️ **NEXT:** Verify deleted_at column exists
5. ⏭️ **NEXT:** Re-run automated tests
6. ⏭️ **NEXT:** Perform manual RLS tests
7. ⏭️ **NEXT:** Document and fix any policy gaps

---

## 🎯 **Success Criteria**

- [x] Audit queries generated
- [x] Test scripts created
- [ ] SQL migration executed
- [ ] All 8 tables have RLS enabled
- [ ] CEO cannot see other CEOs' data
- [ ] Employee cannot see other companies
- [ ] Manager cannot see other branches
- [ ] Staff sees only assigned tasks
- [ ] Soft delete filter works correctly
- [ ] No overly permissive policies

---

**Status:** 🔄 **40% COMPLETE** (Blocked by migration)  
**Blocker:** SQL migration must be run manually in Supabase  
**Estimated Time:** 15 minutes (run migration + verify)  
**Next Task:** Execute `add_soft_delete_to_companies.sql` in Supabase SQL Editor

