"""
Clean up tasks table - Set invalid foreign keys to NULL before changing constraint
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv("SUPABASE_CONNECTION_STRING")

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("="*80)
    print("🧹 CLEANING UP TASKS TABLE")
    print("="*80)
    
    # Check current tasks
    cur.execute("SELECT COUNT(*) FROM tasks;")
    total_tasks = cur.fetchone()[0]
    print(f"\n📊 Total tasks: {total_tasks}")
    
    # Check tasks with assigned_to not in employees
    cur.execute("""
        SELECT COUNT(*)
        FROM tasks t
        LEFT JOIN employees e ON t.assigned_to = e.id
        WHERE t.assigned_to IS NOT NULL AND e.id IS NULL;
    """)
    invalid_assigned = cur.fetchone()[0]
    print(f"❌ Tasks with invalid assigned_to: {invalid_assigned}")
    
    # Check tasks with created_by not in employees
    cur.execute("""
        SELECT COUNT(*)
        FROM tasks t
        LEFT JOIN employees e ON t.created_by = e.id
        WHERE t.created_by IS NOT NULL AND e.id IS NULL;
    """)
    invalid_created = cur.fetchone()[0]
    print(f"❌ Tasks with invalid created_by: {invalid_created}")
    
    if invalid_assigned > 0 or invalid_created > 0:
        print("\n🔧 Cleaning up invalid references...")
        
        # Option 1: Set to NULL
        if invalid_assigned > 0:
            cur.execute("""
                UPDATE tasks t
                SET assigned_to = NULL
                FROM (
                    SELECT t.id
                    FROM tasks t
                    LEFT JOIN employees e ON t.assigned_to = e.id
                    WHERE t.assigned_to IS NOT NULL AND e.id IS NULL
                ) AS invalid
                WHERE t.id = invalid.id;
            """)
            print(f"  ✅ Set {cur.rowcount} invalid assigned_to to NULL")
        
        if invalid_created > 0:
            # For created_by, let's try to find a valid employee first
            cur.execute("SELECT id FROM employees LIMIT 1;")
            default_employee = cur.fetchone()
            
            if default_employee:
                default_id = default_employee[0]
                cur.execute("""
                    UPDATE tasks t
                    SET created_by = %s
                    FROM (
                        SELECT t.id
                        FROM tasks t
                        LEFT JOIN employees e ON t.created_by = e.id
                        WHERE t.created_by IS NOT NULL AND e.id IS NULL
                    ) AS invalid
                    WHERE t.id = invalid.id;
                """, (default_id,))
                print(f"  ✅ Updated {cur.rowcount} invalid created_by to first employee")
            else:
                cur.execute("""
                    UPDATE tasks t
                    SET created_by = NULL
                    FROM (
                        SELECT t.id
                        FROM tasks t
                        LEFT JOIN employees e ON t.created_by = e.id
                        WHERE t.created_by IS NOT NULL AND e.id IS NULL
                    ) AS invalid
                    WHERE t.id = invalid.id;
                """)
                print(f"  ✅ Set {cur.rowcount} invalid created_by to NULL")
        
        conn.commit()
        print("\n✅ Cleanup complete!")
    else:
        print("\n✅ No invalid references found!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
