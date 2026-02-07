import psycopg2
import os
from dotenv import load_dotenv
load_dotenv('sabohub-nexus/.env')

conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

# Check all inventory-related tables
tables = ['products', 'warehouses', 'inventory', 'inventory_movements', 'product_categories']

for table in tables:
    print(f'\n=== TABLE: {table} ===')
    cur.execute('''
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = %s
        ORDER BY ordinal_position
    ''', (table,))
    cols = cur.fetchall()
    if cols:
        for col in cols:
            print(f'  {col[0]}: {col[1]} (nullable: {col[2]})')
    else:
        print('  TABLE NOT FOUND!')

# Check constraints on warehouses
print('\n=== WAREHOUSE TYPE CONSTRAINT ===')
cur.execute('''
    SELECT pg_get_constraintdef(oid) 
    FROM pg_constraint 
    WHERE conname = 'warehouses_type_check'
''')
result = cur.fetchone()
print(f'  {result[0] if result else "Not found"}')

# Check existing warehouse types
cur.execute('SELECT DISTINCT type FROM warehouses')
types = cur.fetchall()
print(f'\nExisting warehouse types: {[t[0] for t in types]}')

# Check movement types constraint
print('\n=== MOVEMENT TYPE CONSTRAINT ===')
cur.execute('''
    SELECT pg_get_constraintdef(oid) 
    FROM pg_constraint 
    WHERE conname = 'inventory_movements_type_check'
''')
result = cur.fetchone()
print(f'  {result[0] if result else "Not found"}')

cur.close()
conn.close()
print('\n✅ Schema check complete!')
