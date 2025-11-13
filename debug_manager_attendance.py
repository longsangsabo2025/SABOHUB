import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

# Database connection
conn = psycopg2.connect(
    host=os.getenv('DB_HOST'),
    database=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    port=os.getenv('DB_PORT', '5432')
)

cur = conn.cursor()

print("\n" + "="*80)
print("🔍 CHECKING MANAGER ATTENDANCE ISSUE")
print("="*80)

# 1. Check all users with role
print("\n📋 ALL USERS:")
cur.execute("""
    SELECT id, email, 
           raw_user_meta_data->>'role' as role,
           raw_user_meta_data->>'name' as name
    FROM auth.users
    ORDER BY created_at DESC
    LIMIT 10
""")
for row in cur.fetchall():
    print(f"  User: {row[1]}")
    print(f"    ID: {row[0]}")
    print(f"    Role: {row[2]}")
    print(f"    Name: {row[3]}")
    print()

# 2. Check companies table
print("\n🏢 COMPANIES:")
cur.execute("""
    SELECT id, name, owner_id, manager_id, created_at
    FROM companies
    ORDER BY created_at DESC
""")
for row in cur.fetchall():
    print(f"  Company: {row[1]}")
    print(f"    ID: {row[0]}")
    print(f"    Owner ID: {row[2]}")
    print(f"    Manager ID: {row[3]}")
    print(f"    Created: {row[4]}")
    print()

# 3. Check employees table for manager role
print("\n👔 EMPLOYEES WITH MANAGER ROLE:")
cur.execute("""
    SELECT e.id, e.user_id, e.company_id, e.branch_id, e.name, e.role,
           u.email
    FROM employees e
    LEFT JOIN auth.users u ON e.user_id = u.id
    WHERE e.role = 'manager'
    ORDER BY e.created_at DESC
""")
for row in cur.fetchall():
    print(f"  Employee: {row[4]} ({row[6]})")
    print(f"    Employee ID: {row[0]}")
    print(f"    User ID: {row[1]}")
    print(f"    Company ID: {row[2]}")
    print(f"    Branch ID: {row[3]}")
    print(f"    Role: {row[5]}")
    print()

# 4. Check branches
print("\n🏪 BRANCHES:")
cur.execute("""
    SELECT b.id, b.name, b.company_id, b.manager_id,
           c.name as company_name
    FROM branches b
    LEFT JOIN companies c ON b.company_id = c.id
    ORDER BY b.created_at DESC
""")
for row in cur.fetchall():
    print(f"  Branch: {row[1]} (Company: {row[4]})")
    print(f"    Branch ID: {row[0]}")
    print(f"    Company ID: {row[2]}")
    print(f"    Manager ID: {row[3]}")
    print()

# 5. Check attendance table structure
print("\n📊 ATTENDANCE TABLE STRUCTURE:")
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'attendance' AND table_schema = 'public'
    ORDER BY ordinal_position
""")
for row in cur.fetchall():
    print(f"  {row[0]}: {row[1]} (nullable: {row[2]})")

print("\n" + "="*80)

cur.close()
conn.close()
