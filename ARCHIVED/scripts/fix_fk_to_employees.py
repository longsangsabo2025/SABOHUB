"""
Fix foreign key constraints: Point to employees table instead of users
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
    print("🔧 FIXING FOREIGN KEY CONSTRAINTS")
    print("="*80)
    print("\nChanging tasks foreign keys to reference employees table\n")
    
    # Step 1: Drop old foreign key constraints
    print("Step 1: Dropping old foreign key constraints...")
    
    constraints_to_drop = [
        'tasks_assigned_to_fkey',
        'tasks_created_by_fkey'
    ]
    
    for constraint in constraints_to_drop:
        try:
            cur.execute(f"ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS {constraint};")
            print(f"  ✅ Dropped: {constraint}")
        except Exception as e:
            print(f"  ⚠️  Could not drop {constraint}: {str(e)}")
    
    conn.commit()
    
    # Step 2: Add new foreign key constraints pointing to employees table
    print("\nStep 2: Adding new foreign key constraints to employees table...")
    
    new_constraints = [
        (
            "tasks_assigned_to_fkey",
            """
            ALTER TABLE public.tasks 
            ADD CONSTRAINT tasks_assigned_to_fkey 
            FOREIGN KEY (assigned_to) 
            REFERENCES public.employees(id) 
            ON DELETE SET NULL;
            """
        ),
        (
            "tasks_created_by_fkey",
            """
            ALTER TABLE public.tasks 
            ADD CONSTRAINT tasks_created_by_fkey 
            FOREIGN KEY (created_by) 
            REFERENCES public.employees(id) 
            ON DELETE SET NULL;
            """
        ),
    ]
    
    for name, query in new_constraints:
        try:
            cur.execute(query)
            print(f"  ✅ Added: {name}")
        except Exception as e:
            print(f"  ❌ Error adding {name}: {str(e)}")
    
    conn.commit()
    
    # Step 3: Verify
    print("\n" + "="*80)
    print("✅ VERIFICATION")
    print("="*80)
    
    cur.execute("""
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'tasks'
        AND kcu.column_name IN ('assigned_to', 'created_by');
    """)
    
    print("\nNew foreign key constraints:")
    for const_name, column, fk_table, fk_column in cur.fetchall():
        print(f"  {const_name}:")
        print(f"    tasks.{column} → {fk_table}.{fk_column}")
    
    # Check employees table columns
    print("\n" + "="*80)
    print("📋 EMPLOYEES TABLE COLUMNS")
    print("="*80)
    
    cur.execute("""
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'employees'
        ORDER BY ordinal_position
        LIMIT 10;
    """)
    
    print("\nColumns in employees table:")
    for col_name, data_type in cur.fetchall():
        print(f"  - {col_name:30} {data_type}")
    
    # Count employees
    cur.execute("SELECT COUNT(*) FROM employees WHERE deleted_at IS NULL;")
    emp_count = cur.fetchone()[0]
    print(f"\n📊 Total active employees: {emp_count}")
    
    print("\n" + "="*80)
    print("✅ Foreign keys now point to employees table!")
    print("="*80)
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
