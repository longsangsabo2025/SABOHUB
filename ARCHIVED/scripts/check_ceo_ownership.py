"""
Check CEO login and company ownership
"""
import psycopg2
from psycopg2.extras import RealDictCursor

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print('=' * 80)
print('🔍 CHECK CEO AND COMPANY OWNERSHIP')
print('=' * 80)

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    
    # 1. Check all CEOs
    print('\n1️⃣ ALL CEOs IN DATABASE (auth.users)')
    cursor.execute("""
        SELECT id, email, 
               raw_user_meta_data->>'full_name' as full_name,
               raw_user_meta_data->>'role' as role
        FROM auth.users
        WHERE raw_user_meta_data->>'role' = 'CEO'
        ORDER BY created_at
    """)
    ceos = cursor.fetchall()
    print(f'   Total: {len(ceos)} CEOs\n')
    for ceo in ceos:
        print(f'   👔 {ceo.get("full_name", "Unknown")}')
        print(f'      Email: {ceo["email"]}')
        print(f'      ID: {ceo["id"]}\n')
    
    # 2. Check company and who created it
    print('\n2️⃣ COMPANIES AND OWNERS')
    cursor.execute("""
        SELECT 
            c.id, 
            c.name, 
            c.created_by,
            u.email as owner_email,
            u.raw_user_meta_data->>'full_name' as owner_name
        FROM companies c
        LEFT JOIN auth.users u ON c.created_by = u.id
    """)
    companies = cursor.fetchall()
    print(f'   Total: {len(companies)} companies\n')
    for comp in companies:
        print(f'   🏢 {comp["name"]}')
        print(f'      ID: {comp["id"]}')
        print(f'      Created by: {comp.get("owner_name", "Unknown")} ({comp.get("owner_email", "N/A")})')
        print(f'      Owner ID: {comp["created_by"]}\n')
    
    # 3. Check if RLS would allow each CEO to see employees
    print('\n3️⃣ RLS CHECK: Which CEO can see employees?')
    for ceo in ceos:
        ceo_id = ceo['id']
        ceo_name = ceo.get('full_name', ceo['email'])
        
        # Simulate RLS query
        cursor.execute("""
            SELECT COUNT(*) as count
            FROM employees e
            WHERE e.company_id IN (
                SELECT c.id 
                FROM companies c
                WHERE c.created_by = %s
            )
            AND e.deleted_at IS NULL
        """, (ceo_id,))
        
        result = cursor.fetchone()
        count = result['count']
        
        if count > 0:
            print(f'   ✅ {ceo_name}: CAN see {count} employees')
        else:
            print(f'   ❌ {ceo_name}: CANNOT see any employees')
    
    cursor.close()
    conn.close()
    
    print('\n' + '=' * 80)
    print('💡 SOLUTION:')
    print('=' * 80)
    
    if len(ceos) == 0:
        print('\n❌ NO CEO EXISTS - Need to create CEO account first')
    elif len(companies) == 0:
        print('\n❌ NO COMPANY EXISTS - Need to create company')
    elif not companies[0]['created_by']:
        print('\n⚠️  COMPANY HAS NO OWNER (created_by is NULL)')
        print('\n   Fix: Assign company to a CEO')
        if ceos:
            print(f'\n   SQL:')
            print(f"   UPDATE companies SET created_by = '{ceos[0]['id']}' WHERE id = '{companies[0]['id']}';")
    else:
        print('\n✅ Company has owner, check which CEO is logged in')
        print('\n   If wrong CEO is logged in:')
        print('   1. Logout current CEO')
        print(f"   2. Login as: {companies[0].get('owner_email', 'owner email')}")
        print('\n   OR assign company to current CEO:')
        print(f"   UPDATE companies SET created_by = '<current_ceo_id>' WHERE id = '{companies[0]['id']}';")
    
    print('=' * 80)
    
except Exception as e:
    print(f'\n❌ ERROR: {e}')
    import traceback
    traceback.print_exc()
