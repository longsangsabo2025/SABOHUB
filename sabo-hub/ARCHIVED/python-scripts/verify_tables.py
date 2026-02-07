import psycopg2, os
from dotenv import load_dotenv
load_dotenv('sabohub-automation/.env')
conn = psycopg2.connect(os.getenv('DATABASE_URL'))
cur = conn.cursor()

# Check commissions table
cur.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND table_name='commissions' ORDER BY ordinal_position")
cols = cur.fetchall()
if cols:
    print('commissions table EXISTS:')
    for c in cols:
        print(f'  {c[0]}: {c[1]}')
    cur.execute('SELECT count(*) FROM commissions')
    print(f'  rows: {cur.fetchone()[0]}')
else:
    print('commissions table: NOT FOUND')

# Check stock_movements table
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='stock_movements' ORDER BY ordinal_position")
sm = cur.fetchall()
if sm:
    print(f'\nstock_movements table EXISTS: {[c[0] for c in sm]}')
    cur.execute('SELECT count(*) FROM stock_movements')
    print(f'  rows: {cur.fetchone()[0]}')
else:
    print('\nstock_movements: NOT FOUND')

# Check inventory_movements columns
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='inventory_movements' ORDER BY ordinal_position")
im = cur.fetchall()
print(f'\ninventory_movements columns: {[c[0] for c in im]}')

# Check referrers columns  
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='referrers' ORDER BY ordinal_position")
ref_cols = cur.fetchall()
print(f'\nreferrers columns: {[c[0] for c in ref_cols]}')

conn.close()
