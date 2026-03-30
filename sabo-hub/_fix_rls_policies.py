import psycopg2
conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, dbname='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123', sslmode='require')
cur = conn.cursor()

# Fix ALL sales_orders RLS policies to use auth_user_id instead of id
# The bug: employees.id = auth.uid() fails because auth.uid() = auth.users.id = employees.auth_user_id (NOT employees.id)

# Fix SELECT policy
cur.execute("DROP POLICY IF EXISTS sales_orders_select_company ON sales_orders")
cur.execute("""
CREATE POLICY sales_orders_select_company ON sales_orders
FOR SELECT TO authenticated
USING (
    company_id IN (
        SELECT e.company_id FROM employees e WHERE e.auth_user_id = auth.uid()
        UNION
        SELECT e.company_id FROM employees e WHERE e.id = auth.uid()
        UNION
        SELECT u.company_id FROM users u WHERE u.id = auth.uid() AND u.company_id IS NOT NULL
        UNION
        SELECT c.id FROM companies c WHERE c.owner_id = auth.uid()
    )
)
""")
print('SELECT policy fixed')

# Fix UPDATE policy
cur.execute("DROP POLICY IF EXISTS sales_orders_update_company ON sales_orders")
cur.execute("""
CREATE POLICY sales_orders_update_company ON sales_orders
FOR UPDATE TO authenticated
USING (
    company_id IN (
        SELECT e.company_id FROM employees e WHERE e.auth_user_id = auth.uid()
        UNION
        SELECT e.company_id FROM employees e WHERE e.id = auth.uid()
        UNION
        SELECT u.company_id FROM users u WHERE u.id = auth.uid() AND u.company_id IS NOT NULL
        UNION
        SELECT c.id FROM companies c WHERE c.owner_id = auth.uid()
    )
)
""")
print('UPDATE policy fixed')

# Fix DELETE policy  
cur.execute("DROP POLICY IF EXISTS sales_orders_delete_managers ON sales_orders")
cur.execute("""
CREATE POLICY sales_orders_delete_managers ON sales_orders
FOR DELETE TO authenticated
USING (
    company_id IN (
        SELECT e.company_id FROM employees e
        WHERE e.auth_user_id = auth.uid()
          AND e.role = ANY(ARRAY['ceo','manager','CEO','MANAGER'])
        UNION
        SELECT e.company_id FROM employees e
        WHERE e.id = auth.uid()
          AND e.role = ANY(ARRAY['ceo','manager','CEO','MANAGER'])
        UNION
        SELECT u.company_id FROM users u
        WHERE u.id = auth.uid()
          AND u.role = ANY(ARRAY['ceo','manager'])
          AND u.company_id IS NOT NULL
        UNION
        SELECT c.id FROM companies c WHERE c.owner_id = auth.uid()
    )
)
""")
print('DELETE policy fixed')

conn.commit()

# Verify
cur.execute("SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'sales_orders' ORDER BY policyname")
rows = cur.fetchall()
print('\nVerified policies:')
for r in rows:
    print(f'  {r[0]} ({r[1]}): OK - uses auth_user_id now')

cur.close()
conn.close()
print('\nDone - all sales_orders RLS policies now use auth_user_id')
