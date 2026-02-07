import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check table structure
cur.execute('''
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
  WHERE table_name = 'product_categories'
  ORDER BY ordinal_position
''')
print('=== product_categories table structure ===')
for row in cur.fetchall():
    print(f'{row[0]}: {row[1]} (nullable: {row[2]})')

# Check sample data
cur.execute('''SELECT * FROM product_categories LIMIT 10''')
print()
print('=== Sample data ===')
cols = [desc[0] for desc in cur.description]
print(cols)
for row in cur.fetchall():
    print(row)
    
conn.close()
