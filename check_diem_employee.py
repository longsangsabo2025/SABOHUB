"""
Check Manager Diễm's employee record
"""
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cur = conn.cursor()

cur.execute("""
    SELECT id, full_name, email, role, company_id, branch_id
    FROM employees
    WHERE full_name LIKE '%Diễm%'
""")

result = cur.fetchone()

print("=" * 60)
print("MANAGER DIỄM EMPLOYEE RECORD")
print("=" * 60)

if result:
    emp_id, full_name, email, role, company_id, branch_id = result
    
    print(f"\n✅ Found employee:")
    print(f"   ID: {emp_id}")
    print(f"   Name: {full_name}")
    print(f"   Email: {email}")
    print(f"   Role: {role}")
    print(f"   Company ID: {company_id}")
    print(f"   Branch ID: {branch_id}")
    
    print("\n" + "=" * 60)
    print("VERIFICATION")
    print("=" * 60)
    
    expected_company = "feef10d3-899d-4554-8107-b2256918213a"
    
    if company_id == expected_company:
        print(f"\n✅ Company ID matches: {expected_company}")
    else:
        print(f"\n❌ PROBLEM! Company ID does not match!")
        print(f"   Current: {company_id}")
        print(f"   Expected: {expected_company}")
        print(f"\n   This is why Manager Diễm sees 'Không tìm thấy công ty'!")
        
        # Fix it
        print("\n🔧 Fixing company_id...")
        cur.execute("""
            UPDATE employees
            SET company_id = %s
            WHERE id = %s
        """, (expected_company, emp_id))
        conn.commit()
        print("   ✅ Fixed! Company ID updated.")
else:
    print("\n❌ Employee not found!")

cur.close()
conn.close()
