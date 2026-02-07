import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

print('=== Adding warehouse_id to employees table ===')

# Add warehouse_id column if not exists
cur.execute('''
    ALTER TABLE employees 
    ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL;
''')

# Add index for faster lookup
cur.execute('''
    CREATE INDEX IF NOT EXISTS idx_employees_warehouse_id ON employees(warehouse_id);
''')

# Add comment
cur.execute('''
    COMMENT ON COLUMN employees.warehouse_id IS 'Kho mà nhân viên được phân công quản lý';
''')

conn.commit()
print('✅ Added warehouse_id column to employees table')

# Show updated schema
cur.execute('''
    SELECT column_name, data_type
    FROM information_schema.columns 
    WHERE table_name = 'employees'
    AND column_name = 'warehouse_id'
''')
result = cur.fetchone()
if result:
    print(f'   Column: {result[0]} | Type: {result[1]}')

# List warehouses for reference
print('\n=== Available Warehouses ===')
cur.execute('''
    SELECT id, name, type, code 
    FROM warehouses 
    WHERE is_active = true
    ORDER BY name
''')
for row in cur.fetchall():
    print(f'   {row[0]} | {row[1]} ({row[2]}) - Code: {row[3]}')

# List warehouse employees
print('\n=== Warehouse Employees (role=warehouse) ===')
cur.execute('''
    SELECT id, full_name, username, warehouse_id
    FROM employees 
    WHERE role = 'warehouse'
    ORDER BY full_name
''')
for row in cur.fetchall():
    print(f'   {row[0]} | {row[1]} ({row[2]}) - warehouse_id: {row[3]}')

conn.close()
