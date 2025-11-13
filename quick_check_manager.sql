-- Quick check manager setup
-- Copy and run this in Supabase SQL Editor

-- 1. Check current user (you should be logged in as manager)
SELECT 
    'CURRENT USERS' as section,
    id,
    email,
    raw_user_meta_data->>'role' as role,
    raw_user_meta_data->>'name' as name
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check employees with manager role
SELECT 
    'EMPLOYEES WITH MANAGER ROLE' as section,
    e.id as employee_id,
    e.user_id,
    e.company_id,
    e.branch_id,
    e.name,
    e.role,
    u.email,
    c.name as company_name,
    b.name as branch_name
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
LEFT JOIN companies c ON e.company_id = c.id
LEFT JOIN branches b ON e.branch_id = b.id
WHERE e.role = 'manager'
ORDER BY e.created_at DESC;

-- 3. Check all employees for any user
SELECT 
    'ALL EMPLOYEES' as section,
    e.id as employee_id,
    e.user_id,
    e.company_id,
    e.branch_id,
    e.name,
    e.role,
    u.email
FROM employees e
LEFT JOIN auth.users u ON e.user_id = u.id
ORDER BY e.created_at DESC
LIMIT 10;

-- 4. Check companies
SELECT 
    'COMPANIES' as section,
    id,
    name,
    owner_id,
    manager_id
FROM companies
ORDER BY created_at DESC;

-- 5. Check branches
SELECT 
    'BRANCHES' as section,
    b.id,
    b.name,
    b.company_id,
    b.manager_id,
    c.name as company_name
FROM branches b
LEFT JOIN companies c ON b.company_id = c.id
ORDER BY b.created_at DESC;
