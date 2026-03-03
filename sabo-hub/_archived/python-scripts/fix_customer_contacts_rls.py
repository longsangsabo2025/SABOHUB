import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
conn.autocommit = True
cur = conn.cursor()

# Fix RLS policies for customer_contacts - remove references to non-existent 'users' table
# Only use 'employees' table which is what the system actually uses

tables = ['customer_contacts', 'customer_addresses']

for table in tables:
    print(f'\n=== Fixing {table} ===')
    
    # Drop existing policies
    cur.execute(f"""
        SELECT policyname FROM pg_policies WHERE tablename = '{table}'
    """)
    policies = cur.fetchall()
    for p in policies:
        cur.execute(f'DROP POLICY IF EXISTS "{p[0]}" ON {table}')
        print(f'  Dropped: {p[0]}')
    
    # Create clean policies using only employees table
    # SELECT - all employees of the same company
    cur.execute(f"""
        CREATE POLICY "{table}_select" ON {table}
        FOR SELECT USING (
            company_id IN (
                SELECT e.company_id FROM employees e WHERE e.id = auth.uid()
            )
        )
    """)
    print(f'  Created: {table}_select')
    
    # INSERT - all employees of the same company
    cur.execute(f"""
        CREATE POLICY "{table}_insert" ON {table}
        FOR INSERT WITH CHECK (
            company_id IN (
                SELECT e.company_id FROM employees e WHERE e.id = auth.uid()
            )
        )
    """)
    print(f'  Created: {table}_insert')
    
    # UPDATE - all employees of the same company
    cur.execute(f"""
        CREATE POLICY "{table}_update" ON {table}
        FOR UPDATE USING (
            company_id IN (
                SELECT e.company_id FROM employees e WHERE e.id = auth.uid()
            )
        )
    """)
    print(f'  Created: {table}_update')
    
    # DELETE - only ceo/manager
    cur.execute(f"""
        CREATE POLICY "{table}_delete" ON {table}
        FOR DELETE USING (
            company_id IN (
                SELECT e.company_id FROM employees e 
                WHERE e.id = auth.uid() 
                AND e.role IN ('ceo', 'manager', 'superAdmin')
            )
        )
    """)
    print(f'  Created: {table}_delete')

# Verify
for table in tables:
    cur.execute(f"""
        SELECT policyname, cmd FROM pg_policies WHERE tablename = '{table}'
    """)
    print(f'\n=== {table} policies ===')
    for r in cur.fetchall():
        print(f'  {r[0]}: {r[1]}')

conn.close()
print('\n✅ Done!')
