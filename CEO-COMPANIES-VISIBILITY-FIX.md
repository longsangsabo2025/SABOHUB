# 🔍 CEO COMPANIES VISIBILITY ISSUE - DIAGNOSIS & FIX

**Date:** November 12, 2025  
**Status:** 🔴 ISSUE IDENTIFIED - FIX READY

---

## 🎯 PROBLEM SUMMARY

**Issue:** CEO không thấy công ty nào trên giao diện, mặc dù database đã có dữ liệu công ty.

**Affected:** 
- CEO Dashboard → Companies Tab
- Tất cả CEO users không thể xem danh sách companies

---

## 🔬 ROOT CAUSE ANALYSIS

### 1. Database Has Data ✅
```
Companies in DB: 1
- SABO Billiards (ID: feef10d3-899d-4554-8107-b2256918213a)
  Active: True, Deleted: None
```

### 2. CEO Users Exist ✅
```
Total CEOs: 5
- Võ Long Sang (longsangsabo1@gmail.com) - HAS company_id ✅
- Võ Long Sang (longsangsabo@gmail.com) - NO company_id ❌
- Võ Long Sang (longsang063@gmail.com) - NO company_id ❌
- Võ Long Sang (longsangsabo2025@gmail.com) - NO company_id ❌
- Võ Long Sang (sabotothesky@gmail.com) - NO company_id ❌
```

### 3. App Code Is Correct ✅
**File:** `lib/services/company_service.dart`
```dart
Future<List<Company>> getAllCompanies() async {
  final response = await _supabase
      .from('companies')
      .select('id, name, address, phone, email, business_type, is_active, created_at, updated_at')
      .isFilter('deleted_at', null) // Only get non-deleted companies
      .order('created_at', ascending: false);

  return (response as List).map((json) => Company.fromJson(json)).toList();
}
```

**File:** `lib/features/ceo/widgets/companies_tab_simple.dart`
```dart
final companiesAsync = ref.watch(companiesProvider); // ✅ Uses correct provider

companiesAsync.when(
  data: (companies) => _buildContent(companies),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Lỗi: $error'), // ❌ Error shown here
)
```

### 4. **ROOT CAUSE: RLS POLICY** 🎯

**Problem:** Row Level Security (RLS) trên table `companies` đang **BLOCK** CEO từ việc SELECT companies.

**Evidence:**
- RLS is enabled on `companies` table
- Current policies không cho phép CEO xem companies
- App báo lỗi khi fetch companies (error in UI)

---

## 🔧 SOLUTION

### Step 1: Run SQL Fix in Supabase SQL Editor

**File:** `fix_ceo_companies_rls.sql`

```sql
-- Drop conflicting policies
DROP POLICY IF EXISTS "companies_select_policy" ON companies;
DROP POLICY IF EXISTS "CEO can view all companies" ON companies;
DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;

-- Create correct SELECT policy
CREATE POLICY "companies_select_policy"
ON companies
FOR SELECT
TO authenticated
USING (
  -- CEO can see ALL companies
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.role = 'CEO'
  )
  OR
  -- Other users can see their own company
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND users.company_id = companies.id
  )
);
```

### Step 2: Verify Fix

**Test Query:**
```sql
SELECT id, name, business_type, is_active, created_at
FROM companies
WHERE deleted_at IS NULL
ORDER BY created_at DESC;
```

**Expected Result:** CEO users should now see all companies.

### Step 3: Reload App

```bash
# In Chrome, refresh the page (F5)
# Or restart Flutter app
flutter run -d chrome
```

---

## 📊 VERIFICATION CHECKLIST

After applying fix:

- [ ] Run SQL fix in Supabase SQL Editor
- [ ] Verify policy created: `companies_select_policy`
- [ ] Test SELECT query in SQL Editor (should return companies)
- [ ] Login as CEO in app
- [ ] Navigate to Companies tab
- [ ] **EXPECTED:** Companies list displays SABO Billiards
- [ ] **EXPECTED:** Can add new companies
- [ ] **EXPECTED:** Can click into company details

---

## 🎯 WHY THIS HAPPENED

### RLS Policy History

Looking at project files:
- `fix_companies_rls_simple.sql` - Previous attempt to fix RLS
- `fix_companies_select_policy.sql` - Another attempt
- Multiple conflicting policies were created
- None of them properly allowed CEO to SELECT companies

### Correct Policy Logic

**What CEO needs:**
```
CEO → role = 'CEO' → CAN see ALL companies (no company_id filter)
```

**What was happening:**
```
CEO → tries to SELECT companies
→ RLS checks policies
→ No policy allows SELECT for CEO
→ Returns empty result []
→ UI shows "no companies"
```

---

## 🚀 NEXT STEPS

### Immediate (After Fix)
1. ✅ Apply SQL fix
2. ✅ Test CEO login
3. ✅ Verify companies visible

### Short-term
1. Clean up duplicate CEO accounts
   - Keep: `longsangsabo1@gmail.com` (has company_id)
   - Remove or assign company_id to others
   
2. Audit all RLS policies
   ```bash
   python auto_fix_rls.py
   ```

### Long-term
1. Document RLS policies for all tables
2. Create RLS testing script
3. Add RLS policy tests to CI/CD

---

## 📚 RELATED FILES

**SQL Fixes:**
- `fix_ceo_companies_rls.sql` (NEW - use this one)
- `fix_companies_rls_simple.sql` (old)
- `fix_companies_select_policy.sql` (old)

**App Code:**
- `lib/services/company_service.dart`
- `lib/features/ceo/widgets/companies_tab_simple.dart`
- `lib/providers/company_provider.dart`

**Diagnostic Scripts:**
- `check_ceo_companies.py` (NEW)
- `auto_test_all_roles.py`
- `audit_all_tables_rls.py`

---

## 💡 LESSONS LEARNED

1. **Always check RLS first** when data exists in DB but not in UI
2. **RLS errors are silent** - app doesn't show "RLS blocked" error
3. **CEO role needs special handling** - can see ALL data, not filtered by company_id
4. **Test with real users** after RLS changes
5. **Document RLS policies** in code/database

---

## ✅ FIX IMPLEMENTATION

**To apply fix:**

```bash
# 1. Open Supabase Dashboard
https://dqddxowyikefqcdiioyh.supabase.co

# 2. Go to SQL Editor

# 3. Paste content from fix_ceo_companies_rls.sql

# 4. Click "Run"

# 5. Verify output shows policy created

# 6. Refresh app in browser
```

**Expected time:** 2-3 minutes

---

**Status:** 🟡 FIX READY - WAITING FOR SQL EXECUTION
