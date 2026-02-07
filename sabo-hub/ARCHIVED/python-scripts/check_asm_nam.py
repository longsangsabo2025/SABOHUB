import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check asm.nam user
cur.execute('''
  SELECT id, username, password_hash, full_name, role, is_active
  FROM employees 
  WHERE username = 'asm.nam'
''')
row = cur.fetchone()
if row:
    print(f'ID: {row[0]}')
    print(f'Username: {row[1]}')
    pwd = row[2] or 'NULL'
    print(f'Password hash: {pwd[:60]}...' if len(str(pwd)) > 60 else f'Password hash: {pwd}')
    print(f'Full name: {row[3]}')
    print(f'Role: {row[4]}')
    print(f'Is active: {row[5]}')
    
    # Reset password to Odori@2026 with proper hash
    print('\n--- Resetting password to Odori@2026 ---')
    cur.execute('''
      UPDATE employees 
      SET password_hash = crypt('Odori@2026', gen_salt('bf'))
      WHERE username = 'asm.nam'
      RETURNING password_hash
    ''')
    new_hash = cur.fetchone()[0]
    conn.commit()
    print(f'New password hash: {new_hash[:50]}...')
    print('✅ Password reset to: Odori@2026')
else:
    print('User not found')
conn.close()
