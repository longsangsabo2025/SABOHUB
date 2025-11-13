"""
RLS Policy Audit - Manual Check
Generate SQL queries to check RLS policies
Run these queries in Supabase SQL Editor
"""

print("🔒 RLS POLICY AUDIT - SQL QUERIES")
print("=" * 80)
print("\nCopy and run these queries in Supabase SQL Editor:")
print("=" * 80)

# Query 1: Check which tables have RLS enabled
print("\n📋 QUERY 1: Check RLS Status on All Tables")
print("-" * 80)
query1 = """
SELECT 
    schemaname,
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
"""
print(query1)

# Query 2: List all RLS policies
print("\n📋 QUERY 2: List All RLS Policies")
print("-" * 80)
query2 = """
SELECT 
    tablename,
    policyname,
    cmd as command,
    permissive,
    roles,
    qual as using_clause,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename IN (
        'companies', 'employees', 'branches', 'tasks', 
        'documents', 'contracts', 'attendance', 'shifts'
    )
ORDER BY tablename, policyname;
"""
print(query2)

# Query 3: Check companies table policies specifically
print("\n📋 QUERY 3: Companies Table RLS Policies (Detailed)")
print("-" * 80)
query3 = """
SELECT 
    policyname,
    cmd,
    qual as using_expression
FROM pg_policies 
WHERE tablename = 'companies'
ORDER BY policyname;
"""
print(query3)

# Query 4: Check for soft delete in policies
print("\n📋 QUERY 4: Check if Soft Delete Filter Exists in Policies")
print("-" * 80)
query4 = """
SELECT 
    tablename,
    policyname,
    cmd,
    qual as using_clause
FROM pg_policies 
WHERE tablename = 'companies'
    AND qual LIKE '%deleted_at%';
"""
print(query4)

print("\n" + "=" * 80)
print("✅ COPY QUERIES ABOVE TO SUPABASE SQL EDITOR")
print("=" * 80)

# Security checklist
print("\n🔐 MANUAL SECURITY CHECKLIST:")
print("=" * 80)
print("""
1. ✓ All critical tables have RLS ENABLED
   - companies
   - employees
   - branches
   - tasks
   - documents
   - contracts
   - attendance
   - shifts

2. ✓ Companies table policies check:
   - SELECT: (created_by = auth.uid() OR owner_id = auth.uid()) AND deleted_at IS NULL
   - INSERT: created_by = auth.uid()
   - UPDATE: (created_by = auth.uid() OR owner_id = auth.uid()) AND deleted_at IS NULL
   - DELETE: Should be UPDATE policy for soft delete

3. ✓ Employees table policies check:
   - SELECT: company_id IN (SELECT id FROM companies WHERE created_by = auth.uid())
   - Cannot access other companies' employees

4. ✓ Tasks table policies check:
   - CEO: Can see all tasks in their companies
   - Manager: Can see tasks in their branch
   - Staff: Can see only assigned tasks

5. ✓ Documents table policies check:
   - Role-based access
   - Company isolation

6. ✓ Test cross-company access:
   - CEO A cannot see CEO B's data
   - Manager cannot see other companies
   - Staff cannot see other employees' data
""")

print("\n📝 EXPECTED POLICY PATTERNS:")
print("=" * 80)
print("""
✅ GOOD POLICY EXAMPLES:

-- User owns the company
(created_by = auth.uid() OR owner_id = auth.uid())

-- User's employee record is in this company
company_id IN (
    SELECT company_id FROM employees 
    WHERE user_id = auth.uid()
)

-- Exclude soft-deleted records
deleted_at IS NULL

-- Role-based access
EXISTS (
    SELECT 1 FROM employees 
    WHERE user_id = auth.uid() 
    AND role = 'manager'
)

❌ BAD POLICY EXAMPLES:

-- Too permissive (allows all users)
true

-- Missing auth check (no auth.uid())
company_id = 'some-id'

-- Missing soft delete filter
created_by = auth.uid()  -- Should include: AND deleted_at IS NULL
""")

print("\n" + "=" * 80)
print("🎯 ACTION ITEMS:")
print("=" * 80)
print("""
1. Run all 4 queries above in Supabase SQL Editor
2. Save results to a text file
3. Review each policy against the checklist
4. Identify any missing or weak policies
5. Generate SQL fixes for issues found
6. Test policies with different user contexts
""")
