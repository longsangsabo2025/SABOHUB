#!/usr/bin/env python3
"""
FIX ALL RLS POLICIES that reference only 'users' table.
Replace with queries that check BOTH 'employees' AND 'users' tables.

63 policies across these tables need fixing:
- accounting_transactions (4)
- attendance (4) 
- business_documents (4)
- collection_schedules (2)
- customer_visits (3)
- customers (4)
- deliveries (2)
- departments (2)
- employee_documents (4)
- employees (2 - ceo_delete, ceo_create)
- inventory (2)
- inventory_movements (2)
- labor_contracts (4)
- manager_permissions (2)
- payments (3)
- product_categories (2)
- products (2)
- receivables (2)
- sales_orders (4)
- tasks (7)
- users (1)
- warehouses (2)
"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

# ============================================================
# Helper: standard company_id check patterns
# ============================================================

def company_check_all():
    """All roles can access based on company_id"""
    return """(
        company_id IN (
            SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid()
            UNION
            SELECT u.company_id FROM public.users u WHERE u.id = auth.uid() AND u.company_id IS NOT NULL
            UNION
            SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
        )
    )"""

def company_check_roles(roles):
    """Only specific roles can access based on company_id"""
    roles_str = ", ".join([f"'{r}'::text" for r in roles])
    return f"""(
        company_id IN (
            SELECT e.company_id FROM public.employees e 
            WHERE e.id = auth.uid() AND e.role IN ({roles_str})
            UNION
            SELECT u.company_id FROM public.users u 
            WHERE u.id = auth.uid() AND u.role IN ({roles_str}) AND u.company_id IS NOT NULL
            UNION
            SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
        )
    )"""

def exists_company_check_all(table_alias):
    """EXISTS check matching company_id"""
    return f"""(EXISTS (
        SELECT 1 FROM public.employees e 
        WHERE e.id = auth.uid() AND e.company_id = {table_alias}.company_id
    ) OR EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.company_id = {table_alias}.company_id
    ) OR EXISTS (
        SELECT 1 FROM public.companies c 
        WHERE c.owner_id = auth.uid() AND c.id = {table_alias}.company_id
    ))"""

def exists_company_roles(table_alias, roles):
    """EXISTS check with role restriction"""
    roles_str = ", ".join([f"'{r}'::text" for r in roles])
    return f"""(EXISTS (
        SELECT 1 FROM public.employees e 
        WHERE e.id = auth.uid() AND e.company_id = {table_alias}.company_id 
          AND e.role IN ({roles_str})
    ) OR EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.company_id = {table_alias}.company_id 
          AND u.role IN ({roles_str})
    ) OR EXISTS (
        SELECT 1 FROM public.companies c 
        WHERE c.owner_id = auth.uid() AND c.id = {table_alias}.company_id
    ))"""

def exists_role_only(roles):
    """EXISTS check for role only (no company_id match needed)"""
    roles_str = ", ".join([f"'{r}'::text" for r in roles])
    return f"""(EXISTS (
        SELECT 1 FROM public.employees e 
        WHERE e.id = auth.uid() AND e.role IN ({roles_str})
    ) OR EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.role IN ({roles_str})
    ))"""


# ============================================================
# Define all policy fixes
# ============================================================

fixes = []

# --- accounting_transactions ---
fixes.append(('accounting_transactions', 'Users can view transactions in their company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('accounting_transactions', 'Managers and CEOs can create transactions', 'INSERT',
    None, f'WITH CHECK {exists_company_roles("accounting_transactions", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}'))
fixes.append(('accounting_transactions', 'Managers and CEOs can update transactions', 'UPDATE',
    f'USING {exists_company_roles("accounting_transactions", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}', None))
fixes.append(('accounting_transactions', 'Only CEOs can delete transactions', 'DELETE',
    f'USING {exists_company_roles("accounting_transactions", ["ceo", "CEO"])}', None))

# --- attendance ---
fixes.append(('attendance', 'attendance_select_policy', 'SELECT',
    f"""USING ((deleted_at IS NULL) AND ((user_id = auth.uid()) OR {company_check_roles(["ceo", "manager"])}))""", None))
fixes.append(('attendance', 'attendance_insert_policy', 'INSERT',
    None, f"""WITH CHECK ((user_id = auth.uid()) AND (deleted_at IS NULL) AND {company_check_all()})"""))
fixes.append(('attendance', 'attendance_update_policy', 'UPDATE',
    f"""USING ((deleted_at IS NULL) AND ((user_id = auth.uid()) OR {company_check_roles(["ceo", "manager"])}))""",
    f"""WITH CHECK ((deleted_at IS NULL) AND ((user_id = auth.uid()) OR {company_check_roles(["ceo", "manager"])}))"""))
fixes.append(('attendance', 'attendance_delete_policy', 'DELETE',
    f'USING {company_check_roles(["ceo", "manager"])}', None))

# --- business_documents ---
for cmd, name in [('SELECT', 'business_documents_select_policy'), 
                  ('INSERT', 'business_documents_insert_policy'),
                  ('UPDATE', 'business_documents_update_policy'),
                  ('DELETE', 'business_documents_delete_policy')]:
    if cmd == 'INSERT':
        fixes.append(('business_documents', name, cmd, None, f'WITH CHECK {company_check_all()}'))
    else:
        fixes.append(('business_documents', name, cmd, f'USING {company_check_all()}', None))

# --- collection_schedules ---
fixes.append(('collection_schedules', 'collection_schedules_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('collection_schedules', 'collection_schedules_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- customer_visits ---
fixes.append(('customer_visits', 'customer_visits_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('customer_visits', 'customer_visits_insert_company', 'INSERT',
    None, f'WITH CHECK {company_check_all()}'))
fixes.append(('customer_visits', 'customer_visits_update_company', 'UPDATE',
    f'USING {company_check_all()}', None))

# --- customers ---
fixes.append(('customers', 'customers_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('customers', 'customers_insert_company', 'INSERT',
    None, f'WITH CHECK {company_check_all()}'))
fixes.append(('customers', 'customers_update_company', 'UPDATE',
    f'USING {company_check_all()}', None))
fixes.append(('customers', 'customers_delete_company', 'DELETE',
    f'USING {company_check_roles(["ceo", "manager", "MANAGER"])}', None))

# --- deliveries ---
fixes.append(('deliveries', 'deliveries_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('deliveries', 'deliveries_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- departments ---
fixes.append(('departments', 'departments_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('departments', 'departments_all_managers', 'ALL',
    f'USING {company_check_roles(["ceo", "manager", "MANAGER"])}', 
    f'WITH CHECK {company_check_roles(["ceo", "manager", "MANAGER"])}'))

# --- employee_documents ---
for cmd, name in [('SELECT', 'employee_documents_select_policy'), 
                  ('INSERT', 'employee_documents_insert_policy'),
                  ('UPDATE', 'employee_documents_update_policy'),
                  ('DELETE', 'employee_documents_delete_policy')]:
    if cmd == 'INSERT':
        fixes.append(('employee_documents', name, cmd, None, f'WITH CHECK {company_check_all()}'))
    else:
        fixes.append(('employee_documents', name, cmd, f'USING {company_check_all()}', None))

# --- employees (ceo_create_employees, ceo_delete_employees) ---
fixes.append(('employees', 'ceo_create_employees', 'INSERT',
    None, f'WITH CHECK {exists_role_only(["ceo", "CEO"])}'))
fixes.append(('employees', 'ceo_delete_employees', 'DELETE',
    f'USING {exists_role_only(["ceo", "CEO"])}', None))

# --- inventory ---
fixes.append(('inventory', 'inventory_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('inventory', 'inventory_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- inventory_movements ---
fixes.append(('inventory_movements', 'inventory_movements_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('inventory_movements', 'inventory_movements_insert_company', 'INSERT',
    None, f'WITH CHECK {company_check_all()}'))

# --- labor_contracts ---
for cmd, name in [('SELECT', 'labor_contracts_select_policy'), 
                  ('INSERT', 'labor_contracts_insert_policy'),
                  ('UPDATE', 'labor_contracts_update_policy'),
                  ('DELETE', 'labor_contracts_delete_policy')]:
    if cmd == 'INSERT':
        fixes.append(('labor_contracts', name, cmd, None, f'WITH CHECK {company_check_all()}'))
    else:
        fixes.append(('labor_contracts', name, cmd, f'USING {company_check_all()}', None))

# --- manager_permissions (the 2 that use 'users') ---
fixes.append(('manager_permissions', 'CEO can manage manager permissions', 'ALL',
    f'USING {exists_company_roles("manager_permissions", ["ceo", "CEO"])}',
    f'WITH CHECK {exists_company_roles("manager_permissions", ["ceo", "CEO"])}'))
fixes.append(('manager_permissions', 'CEO can view manager permissions', 'SELECT',
    f'USING {exists_company_roles("manager_permissions", ["ceo", "CEO"])}', None))

# --- payments ---
fixes.append(('payments', 'payments_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('payments', 'payments_insert_company', 'INSERT',
    None, f'WITH CHECK {company_check_all()}'))
fixes.append(('payments', 'payments_update_managers', 'UPDATE',
    f'USING {company_check_roles(["ceo", "manager", "MANAGER"])}', None))

# --- product_categories ---
fixes.append(('product_categories', 'product_categories_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('product_categories', 'product_categories_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- products ---
fixes.append(('products', 'products_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('products', 'products_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- receivables ---
fixes.append(('receivables', 'receivables_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('receivables', 'receivables_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))

# --- sales_orders ---
fixes.append(('sales_orders', 'sales_orders_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('sales_orders', 'sales_orders_insert_company', 'INSERT',
    None, f'WITH CHECK {company_check_all()}'))
fixes.append(('sales_orders', 'sales_orders_update_company', 'UPDATE',
    f'USING {company_check_all()}', None))
fixes.append(('sales_orders', 'sales_orders_delete_managers', 'DELETE',
    f'USING {company_check_roles(["ceo", "manager", "MANAGER"])}', None))

# --- tasks ---
fixes.append(('tasks', 'CEO can view all tasks', 'SELECT',
    f'USING {exists_role_only(["ceo", "CEO"])}', None))
fixes.append(('tasks', 'Manager can view tasks in company', 'SELECT',
    f'USING {exists_company_roles("tasks", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}', None))
fixes.append(('tasks', 'Staff can view their assigned tasks', 'SELECT',
    f"""USING ((assigned_to = auth.uid()) OR {exists_company_roles("tasks", ["ceo", "CEO", "manager", "Manager", "MANAGER"])})""", None))
fixes.append(('tasks', 'CEO and Manager can create tasks', 'INSERT',
    None, f'WITH CHECK {exists_company_roles("tasks", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}'))
fixes.append(('tasks', 'CEO and Manager can update tasks', 'UPDATE',
    f'USING {exists_company_roles("tasks", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}',
    f'WITH CHECK {exists_company_roles("tasks", ["ceo", "CEO", "manager", "Manager", "MANAGER"])}'))
fixes.append(('tasks', 'CEO can delete tasks', 'DELETE',
    f'USING {exists_company_roles("tasks", ["ceo", "CEO"])}', None))

# --- users (company_users_select) ---
fixes.append(('users', 'company_users_select', 'SELECT',
    f"""USING ((id = auth.uid()) OR (company_id IN (
        SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid()
        UNION
        SELECT u2.company_id FROM public.users u2 WHERE u2.id = auth.uid() AND u2.company_id IS NOT NULL
    )))""", None))

# --- warehouses ---
fixes.append(('warehouses', 'warehouses_select_company', 'SELECT',
    f'USING {company_check_all()}', None))
fixes.append(('warehouses', 'warehouses_all_company', 'ALL',
    f'USING {company_check_all()}', f'WITH CHECK {company_check_all()}'))


# ============================================================
# Execute all fixes
# ============================================================

def main():
    print(f"🔧 Fixing {len(fixes)} RLS policies across all tables...")
    
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cursor = conn.cursor()
    
    success = 0
    failed = 0
    
    for i, fix in enumerate(fixes):
        table, policy_name, cmd, using_clause, with_check_clause = fix
        
        try:
            # Drop old policy
            cursor.execute(f'DROP POLICY IF EXISTS "{policy_name}" ON public.{table}')
            
            # Build CREATE POLICY
            sql = f'CREATE POLICY "{policy_name}" ON public.{table}\n  FOR {cmd}'
            if using_clause:
                sql += f'\n  {using_clause}'
            if with_check_clause:
                sql += f'\n  {with_check_clause}'
            
            cursor.execute(sql)
            success += 1
            print(f"  ✅ [{i+1}/{len(fixes)}] {table}.{policy_name} [{cmd}]")
        except Exception as e:
            failed += 1
            print(f"  ❌ [{i+1}/{len(fixes)}] {table}.{policy_name} [{cmd}]")
            print(f"       Error: {e}")
    
    print(f"\n{'='*60}")
    print(f"Results: {success} fixed, {failed} failed out of {len(fixes)}")
    
    # Quick verification
    cursor.execute("""
    SELECT tablename, policyname, cmd
    FROM pg_policies 
    WHERE schemaname = 'public'
      AND (coalesce(qual::text,'') || coalesce(with_check::text,'')) LIKE '%public.users%'
      AND (coalesce(qual::text,'') || coalesce(with_check::text,'')) NOT LIKE '%employees%'
    ORDER BY tablename, cmd
    """)
    remaining = cursor.fetchall()
    print(f"\nRemaining policies that ONLY reference 'users': {len(remaining)}")
    for r in remaining:
        print(f"  ⚠️  {r[0]}.{r[1]} [{r[2]}]")
    
    cursor.close()
    conn.close()


if __name__ == '__main__':
    main()
