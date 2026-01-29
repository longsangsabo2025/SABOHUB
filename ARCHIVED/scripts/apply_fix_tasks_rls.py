import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🔧 FIXING TASKS RLS POLICIES - CEO FULL CONTROL\n")
print("=" * 80)

# Read and execute SQL file
with open('fix_tasks_rls_ceo_full_control.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

try:
    # Execute all statements
    cur.execute(sql)
    conn.commit()
    
    print("✅ RLS POLICIES UPDATED SUCCESSFULLY!\n")
    
    # Show new policies
    print("📋 NEW POLICIES:\n")
    cur.execute("""
        SELECT policyname, cmd, qual
        FROM pg_policies
        WHERE tablename = 'tasks'
        ORDER BY policyname
    """)
    
    policies = cur.fetchall()
    for policy in policies:
        print(f"\n✅ {policy[0]}")
        print(f"   Command: {policy[1]}")
        print(f"   Using: {policy[2][:100]}..." if policy[2] and len(policy[2]) > 100 else f"   Using: {policy[2]}")
    
    print("\n" + "=" * 80)
    print("\n💪 CEO NOW HAS FULL CONTROL:")
    print("   ✅ SELECT all tasks (including deleted)")
    print("   ✅ UPDATE all tasks (including setting deleted_at)")
    print("   ✅ DELETE tasks permanently")
    print("   ✅ No more 'deleted_at IS NULL' blocking updates!")
    print("\n")
    
except Exception as e:
    print(f"❌ ERROR: {e}")
    conn.rollback()

cur.close()
conn.close()
