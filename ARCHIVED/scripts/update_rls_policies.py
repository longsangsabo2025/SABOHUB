import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')

print("=" * 70)
print("UPDATING RLS POLICIES - REPLACING user_id WITH employee_id")
print("=" * 70)

sql_commands = [
    # Drop all old policies
    "DROP POLICY IF EXISTS ceo_select_all_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS manager_select_branch_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS staff_select_own_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS ceo_insert_any_report ON daily_work_reports;",
    "DROP POLICY IF EXISTS manager_insert_branch_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS staff_insert_own_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS ceo_update_all_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS manager_update_branch_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS staff_update_own_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS ceo_delete_all_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS manager_delete_branch_reports ON daily_work_reports;",
    "DROP POLICY IF EXISTS staff_delete_own_reports ON daily_work_reports;",
    
    # Re-create SELECT policies with employee_id
    """CREATE POLICY ceo_select_all_reports ON daily_work_reports
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees
        WHERE employees.id = auth.uid() 
        AND employees.role = 'ceo'
      )
    );""",
    
    """CREATE POLICY manager_select_branch_reports ON daily_work_reports
    FOR SELECT TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees manager
        WHERE manager.id = auth.uid()
        AND manager.role = 'manager'
        AND manager.branch_id IN (
          SELECT emp.branch_id
          FROM employees emp
          WHERE emp.id = daily_work_reports.employee_id
        )
      )
    );""",
    
    """CREATE POLICY staff_select_own_reports ON daily_work_reports
    FOR SELECT TO authenticated
    USING (employee_id = auth.uid());""",
    
    # Re-create INSERT policies with employee_id
    """CREATE POLICY ceo_insert_any_report ON daily_work_reports
    FOR INSERT TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM employees
        WHERE employees.id = auth.uid()
        AND employees.role = 'ceo'
      )
    );""",
    
    """CREATE POLICY manager_insert_branch_reports ON daily_work_reports
    FOR INSERT TO authenticated
    WITH CHECK (
      EXISTS (
        SELECT 1 FROM employees manager
        WHERE manager.id = auth.uid()
        AND manager.role = 'manager'
        AND manager.branch_id IN (
          SELECT emp.branch_id
          FROM employees emp
          WHERE emp.id = employee_id
        )
      )
    );""",
    
    """CREATE POLICY staff_insert_own_reports ON daily_work_reports
    FOR INSERT TO authenticated
    WITH CHECK (employee_id = auth.uid());""",
    
    # Re-create UPDATE policies with employee_id
    """CREATE POLICY ceo_update_all_reports ON daily_work_reports
    FOR UPDATE TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees
        WHERE employees.id = auth.uid()
        AND employees.role = 'ceo'
      )
    );""",
    
    """CREATE POLICY manager_update_branch_reports ON daily_work_reports
    FOR UPDATE TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees manager
        WHERE manager.id = auth.uid()
        AND manager.role = 'manager'
        AND manager.branch_id IN (
          SELECT emp.branch_id
          FROM employees emp
          WHERE emp.id = daily_work_reports.employee_id
        )
      )
    );""",
    
    """CREATE POLICY staff_update_own_reports ON daily_work_reports
    FOR UPDATE TO authenticated
    USING (employee_id = auth.uid());""",
    
    # Re-create DELETE policies with employee_id
    """CREATE POLICY ceo_delete_all_reports ON daily_work_reports
    FOR DELETE TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees
        WHERE employees.id = auth.uid()
        AND employees.role = 'ceo'
      )
    );""",
    
    """CREATE POLICY manager_delete_branch_reports ON daily_work_reports
    FOR DELETE TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM employees manager
        WHERE manager.id = auth.uid()
        AND manager.role = 'manager'
        AND manager.branch_id IN (
          SELECT emp.branch_id
          FROM employees emp
          WHERE emp.id = daily_work_reports.employee_id
        )
      )
    );""",
    
    """CREATE POLICY staff_delete_own_reports ON daily_work_reports
    FOR DELETE TO authenticated
    USING (employee_id = auth.uid());"""
]

try:
    print("\n🔌 Connecting to database...")
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cur = conn.cursor()
    print("✅ Connected!")
    
    print("\n🔄 Executing SQL commands...")
    
    for i, sql in enumerate(sql_commands, 1):
        preview = sql[:70].replace('\n', ' ').strip()
        print(f"\n[{i}/{len(sql_commands)}] {preview}...")
        cur.execute(sql)
        print("    ✅ Success")
        
    cur.close()
    conn.close()
    
    print("\n" + "=" * 70)
    print("✅ ALL RLS POLICIES UPDATED SUCCESSFULLY!")
    print("=" * 70)
    print("\n📋 Summary:")
    print("  • Dropped 12 old policies")
    print("  • Created 12 new policies with employee_id:")
    print("    - 3 SELECT policies (CEO, Manager, Staff)")
    print("    - 3 INSERT policies (CEO, Manager, Staff)")
    print("    - 3 UPDATE policies (CEO, Manager, Staff)")
    print("    - 3 DELETE policies (CEO, Manager, Staff)")
    print("\n🎉 Database migration 100% complete!")
    print("🚀 Ready to test daily work reports feature!")
    
except psycopg2.Error as e:
    print(f"\n❌ Database Error: {e}")
except Exception as e:
    print(f"\n❌ Error: {e}")
