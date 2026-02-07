import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Check current password_hash for asm.nam
cur.execute("""
  SELECT id, username, password_hash 
  FROM employees 
  WHERE username = 'asm.nam'
""")
row = cur.fetchone()
if row:
    print(f'ID: {row[0]}')
    print(f'Username: {row[1]}')
    pwd_hash = row[2] or 'NULL'
    print(f'Current password_hash: {pwd_hash[:50] if len(pwd_hash) > 50 else pwd_hash}')
    
    # Reset password to a known value using proper hash
    cur.execute("""
      UPDATE employees 
      SET password_hash = crypt('123456', gen_salt('bf'))
      WHERE username = 'asm.nam'
      RETURNING password_hash
    """)
    new_hash = cur.fetchone()[0]
    conn.commit()
    print(f'\nNew password hash: {new_hash[:50]}...')
    print('✅ Password reset to: 123456')
else:
    print('User not found')
conn.close()
