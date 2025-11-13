import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n" + "="*80)
print("🔥 APPLYING CEO FULL CONTROL - ALL TABLES")
print("="*80 + "\n")

# Read and execute SQL file
with open('ceo_full_control_all_tables.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

try:
    # Execute all statements
    cur.execute(sql)
    conn.commit()
    
    print("✅ ALL RLS POLICIES UPDATED SUCCESSFULLY!\n")
    
    # Count policies per table
    cur.execute("""
        SELECT tablename, COUNT(*) as policy_count
        FROM pg_policies
        WHERE schemaname = 'public'
        GROUP BY tablename
        ORDER BY tablename
    """)
    
    tables = cur.fetchall()
    
    print("📋 POLICIES PER TABLE:\n")
    for table, count in tables:
        print(f"   ✅ {table:<30} {count} policies")
    
    print("\n" + "="*80)
    print("💪 CEO NOW HAS GOD MODE - FULL CONTROL:")
    print("="*80)
    print("""
   ✅ Companies           - CREATE, SELECT, UPDATE, DELETE
   ✅ Branches            - Full control all branches
   ✅ Employees           - Hire, fire, update employees
   ✅ Tasks               - Create, assign, update, delete (including soft-deleted)
   ✅ Task Templates      - Manage task templates
   ✅ Attendance          - View all check-in/out records
   ✅ Orders              - View all orders & transactions
   ✅ Accounting          - Full financial control
   ✅ Commission Rules    - Set commission for all employees
   ✅ Labor Contracts     - Manage all employment contracts
   ✅ Employee Invitations- Send & manage invitations
    """)
    print("="*80 + "\n")
    
except Exception as e:
    print(f"❌ ERROR: {e}")
    conn.rollback()
    import traceback
    traceback.print_exc()

cur.close()
conn.close()
