import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    database='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Check current bank info
cur.execute("""
    SELECT id, name, bank_name, bank_account_number, bank_account_name, bank_bin 
    FROM companies 
    WHERE id = '9f8921df-3760-44b5-9a7f-20f8484b0300'
""")
row = cur.fetchone()
print('Current:', row)

# Update to new bank info
cur.execute("""
    UPDATE companies SET 
        bank_name = 'VietinBank CN 12 - TP HCM - PGD PHAN HUY ICH',
        bank_account_number = '669671868686',
        bank_account_name = 'HUYNH THI MONG DIEP',
        bank_bin = '970415'
    WHERE id = '9f8921df-3760-44b5-9a7f-20f8484b0300'
""")
conn.commit()
print(f'Updated {cur.rowcount} row')

# Verify
cur.execute("""
    SELECT bank_name, bank_account_number, bank_account_name, bank_bin 
    FROM companies 
    WHERE id = '9f8921df-3760-44b5-9a7f-20f8484b0300'
""")
print('New:', cur.fetchone())

cur.close()
conn.close()
print('Done!')
