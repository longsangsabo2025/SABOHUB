#!/usr/bin/env python3
"""
Comprehensive fix for ALL 63 broken RLS policies.
Adds employees table lookup alongside users table.
Preserves existing role restrictions and business logic.
"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

# ============================================================
# Helper expressions
# ============================================================

def company_in_all():
    """company_id IN (...) - all roles"""
    return """company_id IN (
        SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid()
        UNION
        SELECT u.company_id FROM public.users u WHERE u.id = auth.uid() AND u.company_id IS NOT NULL
        UNION
        SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
    )"""

def company_in_roles(roles):
    """company_id IN (...) - specific roles only"""
    r = ", ".join([f"'{x}'::text" for x in roles])
    return f"""company_id IN (
        SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid() AND e.role IN ({r})
        UNION
        SELECT u.company_id FROM public.users u WHERE u.id = auth.uid() AND u.role IN ({r}) AND u.company_id IS NOT NULL
        UNION
        SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
    )"""

def exists_company_match(tbl, roles=None):
    """EXISTS (...) checking table.company_id match"""
    role_filter_e = f" AND e.role IN ({', '.join([chr(39)+r+chr(39)+'::text' for r in roles])})" if roles else ""
    role_filter_u = f" AND u.role IN ({', '.join([chr(39)+r+chr(39)+'::text' for r in roles])})" if roles else ""
    return f"""(EXISTS (
        SELECT 1 FROM public.employees e 
        WHERE e.id = auth.uid() AND e.company_id = {tbl}.company_id{role_filter_e}
    ) OR EXISTS (
        SELECT 1 FROM public.users u 
        WHERE u.id = auth.uid() AND u.company_id = {tbl}.company_id{role_filter_u}
    ) OR EXISTS (
        SELECT 1 FROM public.companies c 
        WHERE c.owner_id = auth.uid() AND c.id = {tbl}.company_id
    ))"""

def exists_role_only(roles):
    """EXISTS check for role only, no company_id match"""
    r = ", ".join([f"'{x}'::text" for x in roles])
    return f"""(EXISTS (
        SELECT 1 FROM public.employees e WHERE e.id = auth.uid() AND e.role IN ({r})
    ) OR EXISTS (
        SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role IN ({r})
    ))"""


# ============================================================
# All 63 policy definitions: (table, name, cmd, qual, with_check)
# qual/with_check = None means not applicable for that command type
# ============================================================

policies = []

# --- accounting_transactions (4) ---
policies.append(('accounting_transactions', 'Users can view transactions in their company', 'SELECT',
    f'({company_in_all()})', None))

policies.append(('accounting_transactions', 'Managers and CEOs can create transactions', 'INSERT',
    None, f'{exists_company_match("accounting_transactions", ["CEO", "Manager"])}'))

policies.append(('accounting_transactions', 'Managers and CEOs can update transactions', 'UPDATE',
    f'{exists_company_match("accounting_transactions", ["CEO", "Manager"])}', None))

policies.append(('accounting_transactions', 'Only CEOs can delete transactions', 'DELETE',
    f'{exists_company_match("accounting_transactions", ["CEO"])}', None))

# --- attendance (4) ---
policies.append(('attendance', 'attendance_select_policy', 'SELECT',
    f"""((deleted_at IS NULL) AND ((user_id = auth.uid()) OR ({company_in_roles(["ceo", "manager"])})))""", None))

policies.append(('attendance', 'attendance_insert_policy', 'INSERT',
    None, f"""((user_id = auth.uid()) AND (deleted_at IS NULL) AND ({company_in_all()}))"""))

policies.append(('attendance', 'attendance_update_policy', 'UPDATE',
    f"""((deleted_at IS NULL) AND ((user_id = auth.uid()) OR ({company_in_roles(["ceo", "manager"])})))""",
    f"""((deleted_at IS NULL) AND ((user_id = auth.uid()) OR ({company_in_roles(["ceo", "manager"])})))"""))

policies.append(('attendance', 'attendance_delete_policy', 'DELETE',
    f'({company_in_roles(["ceo", "manager"])})', None))

# --- business_documents (4) ---
policies.append(('business_documents', 'business_documents_select_policy', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('business_documents', 'business_documents_insert_policy', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('business_documents', 'business_documents_update_policy', 'UPDATE',
    f'({company_in_all()})', None))
policies.append(('business_documents', 'business_documents_delete_policy', 'DELETE',
    f'({company_in_all()})', None))

# --- collection_schedules (2) ---
policies.append(('collection_schedules', 'collection_schedules_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('collection_schedules', 'collection_schedules_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- customer_visits (3) ---
policies.append(('customer_visits', 'customer_visits_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('customer_visits', 'customer_visits_insert_company', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('customer_visits', 'customer_visits_update_company', 'UPDATE',
    f'({company_in_all()})', None))

# --- customers (4) ---
policies.append(('customers', 'customers_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('customers', 'customers_insert_company', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('customers', 'customers_update_company', 'UPDATE',
    f'({company_in_all()})', None))
policies.append(('customers', 'customers_delete_company', 'DELETE',
    f'({company_in_roles(["ceo", "manager"])})', None))

# --- deliveries (2) ---
policies.append(('deliveries', 'deliveries_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('deliveries', 'deliveries_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- departments (2) ---
policies.append(('departments', 'departments_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('departments', 'departments_all_managers', 'ALL',
    f'({company_in_roles(["ceo", "manager"])})', f'({company_in_roles(["ceo", "manager"])})'))

# --- employee_documents (4) ---
policies.append(('employee_documents', 'employee_documents_select_policy', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('employee_documents', 'employee_documents_insert_policy', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('employee_documents', 'employee_documents_update_policy', 'UPDATE',
    f'({company_in_all()})', None))
policies.append(('employee_documents', 'employee_documents_delete_policy', 'DELETE',
    f'({company_in_all()})', None))

# --- employees (2) - CEO only ---
policies.append(('employees', 'ceo_create_employees', 'INSERT',
    None, f'{exists_role_only(["CEO"])}'))
policies.append(('employees', 'ceo_delete_employees', 'DELETE',
    f'{exists_role_only(["CEO"])}', None))

# --- inventory (2) ---
policies.append(('inventory', 'inventory_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('inventory', 'inventory_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- inventory_movements (2) ---
policies.append(('inventory_movements', 'inventory_movements_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('inventory_movements', 'inventory_movements_insert_company', 'INSERT',
    None, f'({company_in_all()})'))

# --- labor_contracts (4) ---
policies.append(('labor_contracts', 'labor_contracts_select_policy', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('labor_contracts', 'labor_contracts_insert_policy', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('labor_contracts', 'labor_contracts_update_policy', 'UPDATE',
    f'({company_in_all()})', None))
policies.append(('labor_contracts', 'labor_contracts_delete_policy', 'DELETE',
    f'({company_in_all()})', None))

# --- manager_permissions (2) - CEO with company match ---
policies.append(('manager_permissions', 'CEO can manage manager permissions', 'ALL',
    f'{exists_company_match("manager_permissions", ["CEO"])}',
    f'{exists_company_match("manager_permissions", ["CEO"])}'))
policies.append(('manager_permissions', 'CEO can view manager permissions', 'SELECT',
    f'{exists_company_match("manager_permissions", ["CEO"])}', None))

# --- payments (3) ---
policies.append(('payments', 'payments_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('payments', 'payments_insert_company', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('payments', 'payments_update_managers', 'UPDATE',
    f'({company_in_roles(["ceo", "manager"])})', None))

# --- product_categories (2) ---
policies.append(('product_categories', 'product_categories_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('product_categories', 'product_categories_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- products (2) ---
policies.append(('products', 'products_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('products', 'products_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- receivables (2) ---
policies.append(('receivables', 'receivables_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('receivables', 'receivables_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))

# --- sales_orders (4) ---
policies.append(('sales_orders', 'sales_orders_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('sales_orders', 'sales_orders_insert_company', 'INSERT',
    None, f'({company_in_all()})'))
policies.append(('sales_orders', 'sales_orders_update_company', 'UPDATE',
    f'({company_in_all()})', None))
policies.append(('sales_orders', 'sales_orders_delete_managers', 'DELETE',
    f'({company_in_roles(["ceo", "manager"])})', None))

# --- tasks (6) ---
policies.append(('tasks', 'CEO can view all tasks', 'SELECT',
    f'{exists_role_only(["CEO"])}', None))

policies.append(('tasks', 'Manager can view tasks in company', 'SELECT',
    f'{exists_company_match("tasks", ["CEO", "MANAGER"])}', None))

policies.append(('tasks', 'Staff can view their assigned tasks', 'SELECT',
    f"""((assigned_to = auth.uid()) OR {exists_company_match("tasks")})""", None))

policies.append(('tasks', 'CEO and Manager can create tasks', 'INSERT',
    None, f'{exists_company_match("tasks", ["CEO", "MANAGER"])}'))

policies.append(('tasks', 'CEO and Manager can update tasks', 'UPDATE',
    f'{exists_company_match("tasks", ["CEO", "MANAGER"])}',
    f'{exists_company_match("tasks", ["CEO", "MANAGER"])}'))

policies.append(('tasks', 'CEO can delete tasks', 'DELETE',
    f'{exists_company_match("tasks", ["CEO"])}', None))

# --- users (1) ---
policies.append(('users', 'company_users_select', 'SELECT',
    f"""((id = auth.uid()) OR (company_id IN (
        SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid()
        UNION
        SELECT u2.company_id FROM public.users u2 WHERE u2.id = auth.uid() AND u2.company_id IS NOT NULL
    )))""", None))

# --- warehouses (2) ---
policies.append(('warehouses', 'warehouses_select_company', 'SELECT',
    f'({company_in_all()})', None))
policies.append(('warehouses', 'warehouses_all_company', 'ALL',
    f'({company_in_all()})', f'({company_in_all()})'))


# ============================================================
# Execute
# ============================================================

def main():
    print(f"🔧 Fixing {len(policies)} RLS policies across 22 tables...")
    print(f"{'='*60}")
    
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    ok = 0
    fail = 0
    errors = []
    
    for i, (table, name, cmd, qual, wc) in enumerate(policies, 1):
        try:
            # Drop
            cur.execute(f'DROP POLICY IF EXISTS "{name}" ON public.{table}')
            
            # Build CREATE
            sql = f'CREATE POLICY "{name}" ON public.{table}\n  FOR {cmd}\n  TO authenticated'
            if qual:
                sql += f'\n  USING ({qual})'
            if wc:
                sql += f'\n  WITH CHECK ({wc})'
            
            cur.execute(sql)
            ok += 1
            print(f"  ✅ [{i:2d}/{len(policies)}] {table} | {name} [{cmd}]")
        except Exception as e:
            fail += 1
            err_msg = str(e).strip()
            errors.append((table, name, cmd, err_msg))
            print(f"  ❌ [{i:2d}/{len(policies)}] {table} | {name} [{cmd}]")
            print(f"       {err_msg[:200]}")
    
    print(f"\n{'='*60}")
    print(f"✅ Success: {ok}")
    print(f"❌ Failed:  {fail}")
    
    if errors:
        print(f"\n--- ERRORS ---")
        for t, n, c, e in errors:
            print(f"  {t}.{n} [{c}]: {e[:150]}")
    
    # Verification: any policies still referencing only 'users'?
    cur.execute("""
    SELECT tablename, policyname, cmd
    FROM pg_policies 
    WHERE schemaname = 'public'
      AND ((coalesce(qual::text,'') LIKE '%public.users%' OR coalesce(qual::text,'') LIKE '%FROM users%')
           OR (coalesce(with_check::text,'') LIKE '%public.users%' OR coalesce(with_check::text,'') LIKE '%FROM users%'))
      AND (coalesce(qual::text,'') || coalesce(with_check::text,'')) NOT LIKE '%employees%'
    ORDER BY tablename, cmd
    """)
    remaining = cur.fetchall()
    
    print(f"\n{'='*60}")
    print(f"VERIFICATION: Policies still referencing ONLY 'users': {len(remaining)}")
    if remaining:
        for r in remaining:
            print(f"  ⚠️  {r[0]}.{r[1]} [{r[2]}]")
    else:
        print("  🎉 ALL CLEAR — no broken policies remain!")
    
    cur.close()
    conn.close()


if __name__ == '__main__':
    main()
