#!/usr/bin/env python3
"""
Fix RLS policies for customer_addresses and customer_contacts tables.
The old policies only check 'users' table which has NULL company_id for most users.
The correct table is 'employees' which has the proper company_id.
"""

import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

# Fix for both customer_addresses and customer_contacts
TABLES = ['customer_addresses', 'customer_contacts']

def get_fix_statements():
    statements = []
    
    for table in TABLES:
        # Drop ALL existing policies
        statements.append(f'DROP POLICY IF EXISTS "{table}_select" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_insert" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_update" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_delete" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_select_company" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_insert_company" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_update_company" ON public.{table}')
        statements.append(f'DROP POLICY IF EXISTS "{table}_delete_company" ON public.{table}')
        
        # Enable RLS
        statements.append(f'ALTER TABLE public.{table} ENABLE ROW LEVEL SECURITY')
        
        # New policies that check BOTH employees AND users tables
        company_check = f"""(
            company_id IN (
                SELECT e.company_id FROM public.employees e WHERE e.id = auth.uid()
                UNION
                SELECT u.company_id FROM public.users u WHERE u.id = auth.uid() AND u.company_id IS NOT NULL
                UNION
                SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
            )
        )"""
        
        # SELECT
        statements.append(f'''CREATE POLICY "{table}_select" ON public.{table}
            FOR SELECT USING {company_check}''')
        
        # INSERT
        statements.append(f'''CREATE POLICY "{table}_insert" ON public.{table}
            FOR INSERT WITH CHECK {company_check}''')
        
        # UPDATE
        statements.append(f'''CREATE POLICY "{table}_update" ON public.{table}
            FOR UPDATE USING {company_check}''')
        
        # DELETE (restrict to ceo/manager)
        delete_check = f"""(
            company_id IN (
                SELECT e.company_id FROM public.employees e 
                WHERE e.id = auth.uid() AND e.role IN ('ceo', 'MANAGER', 'manager')
                UNION
                SELECT u.company_id FROM public.users u 
                WHERE u.id = auth.uid() AND u.role IN ('ceo', 'manager') AND u.company_id IS NOT NULL
                UNION
                SELECT c.id FROM public.companies c WHERE c.owner_id = auth.uid()
            )
        )"""
        statements.append(f'''CREATE POLICY "{table}_delete" ON public.{table}
            FOR DELETE USING {delete_check}''')
    
    return statements


def main():
    print("🔧 Fixing RLS policies for customer_addresses & customer_contacts...")
    
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = True
    cursor = conn.cursor()
    
    statements = get_fix_statements()
    
    for i, sql in enumerate(statements):
        try:
            cursor.execute(sql)
            short = sql.strip().split('\n')[0][:80]
            print(f"  ✅ [{i+1}/{len(statements)}] {short}")
        except Exception as e:
            print(f"  ❌ [{i+1}/{len(statements)}] Error: {e}")
            print(f"     SQL: {sql[:100]}")
    
    # Verify
    for table in TABLES:
        cursor.execute(f"""
        SELECT policyname, cmd FROM pg_policies WHERE tablename = '{table}' ORDER BY cmd
        """)
        policies = cursor.fetchall()
        print(f"\n📋 {table} policies: {len(policies)}")
        for p in policies:
            print(f"   {p[1]:8} {p[0]}")
    
    cursor.close()
    conn.close()
    print("\n✅ Done! RLS policies now check employees table.")


if __name__ == '__main__':
    main()
