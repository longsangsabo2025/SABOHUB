"""Fix company ownership - simple version"""
import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cursor = conn.cursor()

# CEO ID from public.users
ceo_id = '944f7536-6c9a-4bea-99fc-f1c984fef2ef'
company_id = 'feef10d3-899d-4554-8107-b2256918213a'

cursor.execute("UPDATE companies SET created_by = %s WHERE id = %s", (ceo_id, company_id))
conn.commit()

cursor.execute("SELECT name, created_by FROM companies WHERE id = %s", (company_id,))
result = cursor.fetchone()

print(f'\n✅ SUCCESS!')
print(f'Company: {result[0]}')
print(f'Owner: {ceo_id}')

# Test RLS
cursor.execute("""
    SELECT COUNT(*) FROM employees 
    WHERE company_id IN (SELECT id FROM companies WHERE created_by = %s)
    AND deleted_at IS NULL
""", (ceo_id,))

count = cursor.fetchone()[0]
print(f'\n✅ CEO can now see {count} employees!')

conn.close()
