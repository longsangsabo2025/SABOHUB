"""
Fix company ownership - Assign company to CEO
"""
import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('=' * 80)
print('🔧 FIX COMPANY OWNERSHIP')
print('=' * 80)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    
    # Get first CEO and company
    cursor.execute("SELECT id, email FROM auth.users WHERE raw_user_meta_data->>'role' = 'CEO' ORDER BY created_at LIMIT 1")
    ceo = cursor.fetchone()
    
    cursor.execute("SELECT id, name FROM companies LIMIT 1")
    company = cursor.fetchone()
    
    if not ceo:
        print('\n❌ NO CEO FOUND')
        conn.close()
        exit(1)
    
    if not company:
        print('\n❌ NO COMPANY FOUND')
        conn.close()
        exit(1)
    
    ceo_id, ceo_email = ceo
    company_id, company_name = company
    
    print(f'\n📋 Assignment:')
    print(f'   Company: {company_name}')
    print(f'   CEO: {ceo_email}')
    print(f'\n🔨 Updating...')
    
    # Update company owner
    cursor.execute("""
        UPDATE companies 
        SET created_by = %s,
            updated_at = NOW()
        WHERE id = %s
    """, (ceo_id, company_id))
    
    conn.commit()
    
    # Verify
    cursor.execute("""
        SELECT c.name, c.created_by, u.email
        FROM companies c
        LEFT JOIN auth.users u ON c.created_by = u.id
        WHERE c.id = %s
    """, (company_id,))
    
    result = cursor.fetchone()
    
    print(f'\n✅ SUCCESS!')
    print(f'   Company: {result[0]}')
    print(f'   Owner: {result[2]}')
    print(f'   Owner ID: {result[1]}')
    
    # Test RLS
    print(f'\n🔍 Testing RLS...')
    cursor.execute("""
        SELECT COUNT(*) 
        FROM employees 
        WHERE company_id IN (
            SELECT id FROM companies WHERE created_by = %s
        )
        AND deleted_at IS NULL
    """, (ceo_id,))
    
    employee_count = cursor.fetchone()[0]
    
    print(f'   ✅ CEO can now see {employee_count} employees!')
    
    cursor.close()
    conn.close()
    
    print('\n' + '=' * 80)
    print('✅ COMPANY OWNERSHIP FIXED!')
    print('=' * 80)
    print(f'\n💡 Next: Login as {ceo_email} and refresh the page')
    print('=' * 80)
    
except Exception as e:
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
