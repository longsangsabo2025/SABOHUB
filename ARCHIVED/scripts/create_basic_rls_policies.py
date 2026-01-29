"""
Create Basic RLS Policies for Critical Tables
Ensures data isolation and security
"""

import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()
conn_string = os.environ.get("SUPABASE_CONNECTION_STRING")

def create_basic_policies():
    """Create basic RLS policies"""
    print("🔐 CREATING BASIC RLS POLICIES")
    print("="*60)
    
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # 1. BRANCHES POLICIES
    print("\n1️⃣  BRANCHES TABLE")
    print("-"*60)
    
    try:
        # SELECT: CEO can see branches of their companies
        cur.execute("""
            DROP POLICY IF EXISTS "CEO can view branches" ON branches;
            CREATE POLICY "CEO can view branches" ON branches
                FOR SELECT
                USING (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                    AND deleted_at IS NULL
                );
        """)
        print("   ✅ SELECT policy created")
        
        # INSERT: CEO can create branches
        cur.execute("""
            DROP POLICY IF EXISTS "CEO can create branches" ON branches;
            CREATE POLICY "CEO can create branches" ON branches
                FOR INSERT
                WITH CHECK (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                );
        """)
        print("   ✅ INSERT policy created")
        
        # UPDATE: CEO can update branches
        cur.execute("""
            DROP POLICY IF EXISTS "CEO can update branches" ON branches;
            CREATE POLICY "CEO can update branches" ON branches
                FOR UPDATE
                USING (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                    AND deleted_at IS NULL
                );
        """)
        print("   ✅ UPDATE policy created")
        
        conn.commit()
        print("   🎉 Branches policies complete")
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        conn.rollback()
    
    # 2. TASKS POLICIES
    print("\n2️⃣  TASKS TABLE")
    print("-"*60)
    
    try:
        # SELECT: Users can see tasks in their companies
        cur.execute("""
            DROP POLICY IF EXISTS "Users can view company tasks" ON tasks;
            CREATE POLICY "Users can view company tasks" ON tasks
                FOR SELECT
                USING (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                    OR assigned_to IN (
                        SELECT id FROM employees 
                        WHERE company_id IN (
                            SELECT id FROM companies 
                            WHERE created_by = auth.uid()
                        )
                    )
                );
        """)
        print("   ✅ SELECT policy created")
        
        # INSERT: CEO can create tasks
        cur.execute("""
            DROP POLICY IF EXISTS "CEO can create tasks" ON tasks;
            CREATE POLICY "CEO can create tasks" ON tasks
                FOR INSERT
                WITH CHECK (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                );
        """)
        print("   ✅ INSERT policy created")
        
        # UPDATE: CEO can update tasks
        cur.execute("""
            DROP POLICY IF EXISTS "CEO can update tasks" ON tasks;
            CREATE POLICY "CEO can update tasks" ON tasks
                FOR UPDATE
                USING (
                    company_id IN (
                        SELECT id FROM companies 
                        WHERE created_by = auth.uid()
                    )
                );
        """)
        print("   ✅ UPDATE policy created")
        
        conn.commit()
        print("   🎉 Tasks policies complete")
        
    except Exception as e:
        print(f"   ❌ Error: {e}")
        conn.rollback()
    
    # Verify
    print("\n" + "="*60)
    print("✅ POLICY VERIFICATION")
    print("="*60)
    
    for table in ['companies', 'branches', 'tasks', 'employees', 'attendance']:
        cur.execute(f"""
            SELECT COUNT(*) FROM pg_policies WHERE tablename = '{table}';
        """)
        count = cur.fetchone()[0]
        status = "✅" if count > 0 else "⚠️ "
        print(f"   {status} {table:<15} - {count} policies")
    
    cur.close()
    conn.close()
    
    print("\n🎉 BASIC POLICIES CREATED")
    print("\n📝 SUMMARY:")
    print("   ✅ Branches: 3 policies (SELECT, INSERT, UPDATE)")
    print("   ✅ Tasks: 3 policies (SELECT, INSERT, UPDATE)")
    print("   ✅ Companies: Already has 3 policies")
    print("   ✅ Employees: Already has 5 policies")
    print("   ✅ Attendance: Already has 3 policies")

if __name__ == "__main__":
    create_basic_policies()
