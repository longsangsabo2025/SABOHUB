#!/usr/bin/env python3
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
conn.autocommit = True
cur = conn.cursor()

# Get first company and branch
cur.execute("SELECT id, name FROM companies LIMIT 1;")
company = cur.fetchone()
if not company:
    print("❌ No company found!")
    exit(1)
company_id, company_name = company

cur.execute("SELECT id, name FROM branches LIMIT 1;")
branch = cur.fetchone()
if not branch:
    # Create a branch
    cur.execute("INSERT INTO branches (company_id, name, email) VALUES (%s, 'Main Branch', 'main@company.com') RETURNING id, name;", (company_id,))
    branch = cur.fetchone()
    print(f"✓ Created branch: {branch[1]}")
branch_id, branch_name = branch

print(f"Company: {company_name} ({company_id})")
print(f"Branch: {branch_name} ({branch_id})")

# Update all employees to have this branch/company
cur.execute("""
    UPDATE employees 
    SET branch_id = %s, company_id = %s 
    WHERE deleted_at IS NULL;
""", (branch_id, company_id))
print(f"\n✅ Updated {cur.rowcount} employees with branch/company")

# Verify
cur.execute("""
    SELECT id, full_name, role 
    FROM employees 
    WHERE deleted_at IS NULL AND branch_id IS NOT NULL AND company_id IS NOT NULL 
    LIMIT 1;
""")
emp = cur.fetchone()
if emp:
    print(f"\n✓ Sample employee: {emp[1]} ({emp[2]})")
    print(f"  ID: {emp[0]}")

cur.close()
conn.close()
