#!/usr/bin/env python3
"""Check sample and visit tracking tables"""

import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

print('=' * 60)
print('TABLES RELATED TO SAMPLES & VISITS:')
print('=' * 60)

cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND (table_name LIKE '%sample%' 
         OR table_name LIKE '%visit%')
    ORDER BY table_name
""")
tables = cur.fetchall()
for t in tables:
    print(f'  • {t[0]}')

print()
print('=' * 60)
print('STORE_VISITS TABLE STRUCTURE:')
print('=' * 60)
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'store_visits'
    ORDER BY ordinal_position
""")
for col in cur.fetchall():
    print(f'  • {col[0]}: {col[1]}')

print()
cur.execute('SELECT COUNT(*) FROM store_visits')
print(f'Total visits in DB: {cur.fetchone()[0]}')

# Check for sample tracking
print()
print('=' * 60)
print('SAMPLE PRODUCTS TABLE:')
print('=' * 60)
cur.execute("""
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_name = 'sample_products'
    ORDER BY ordinal_position
""")
cols = cur.fetchall()
if cols:
    for col in cols:
        print(f'  • {col[0]}: {col[1]}')
else:
    print('  Table sample_products not found')

# Check visit_samples or similar
cur.execute("""
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%sample%'
""")
sample_tables = cur.fetchall()
print()
print('All sample-related tables:', [t[0] for t in sample_tables])

cur.close()
conn.close()
