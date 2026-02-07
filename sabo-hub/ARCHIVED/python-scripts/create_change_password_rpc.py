import psycopg2

conn = psycopg2.connect('postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres')
cur = conn.cursor()

# Create or replace function to change employee password
sql = '''
CREATE OR REPLACE FUNCTION change_employee_password(
  p_employee_id UUID,
  p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
  -- Update password using pgcrypto crypt function (same as used in employee_login)
  UPDATE employees
  SET password_hash = crypt(p_new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE id = p_employee_id
    AND is_active = true
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Nhân viên không tồn tại hoặc đã bị vô hiệu hóa'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Đã đổi mật khẩu thành công'
  );
END;
$func$;
'''

cur.execute(sql)
conn.commit()
print('✅ Created change_employee_password function successfully!')
conn.close()
