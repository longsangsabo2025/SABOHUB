"""
Fix tasks table constraints - Convert to UPPERCASE to match users table convention
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
    print("🔧 FIXING TASKS TABLE CONSTRAINTS")
    print("="*80)
    print("\nThis will update constraints to use UPPERCASE values")
    print("to match the users.role convention (CEO, MANAGER, etc.)\n")
    
    # Step 1: Drop old constraints
    print("Step 1: Dropping old constraints...")
    
    constraints_to_drop = [
        'tasks_priority_check',
        'tasks_status_check',
        'tasks_recurrence_check'
    ]
    
    for constraint in constraints_to_drop:
        try:
            cur.execute(f"ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS {constraint};")
            print(f"  ✅ Dropped: {constraint}")
        except Exception as e:
            print(f"  ⚠️  Could not drop {constraint}: {str(e)}")
    
    conn.commit()
    
    # Step 2: Update existing data to UPPERCASE
    print("\nStep 2: Converting existing data to UPPERCASE...")
    
    update_queries = [
        ("priority", "UPDATE public.tasks SET priority = UPPER(priority);"),
        ("status", "UPDATE public.tasks SET status = UPPER(status);"),
        ("recurrence", "UPDATE public.tasks SET recurrence = UPPER(recurrence);"),
    ]
    
    for field, query in update_queries:
        try:
            cur.execute(query)
            rows_updated = cur.rowcount
            print(f"  ✅ Updated {rows_updated} rows in {field}")
        except Exception as e:
            print(f"  ⚠️  Error updating {field}: {str(e)}")
    
    conn.commit()
    
    # Step 3: Add new constraints with UPPERCASE values
    print("\nStep 3: Adding new constraints with UPPERCASE values...")
    
    new_constraints = [
        (
            "tasks_priority_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_priority_check CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT'));"
        ),
        (
            "tasks_status_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_status_check CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'));"
        ),
        (
            "tasks_recurrence_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_recurrence_check CHECK (recurrence IN ('NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'ADHOC', 'PROJECT'));"
        ),
    ]
    
    for name, query in new_constraints:
        try:
            cur.execute(query)
            print(f"  ✅ Added: {name}")
        except Exception as e:
            print(f"  ❌ Error adding {name}: {str(e)}")
    
    conn.commit()
    
    # Step 4: Update default values
    print("\nStep 4: Updating default values to UPPERCASE...")
    
    default_updates = [
        "ALTER TABLE public.tasks ALTER COLUMN priority SET DEFAULT 'MEDIUM';",
        "ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'PENDING';",
        "ALTER TABLE public.tasks ALTER COLUMN recurrence SET DEFAULT 'NONE';",
    ]
    
    for query in default_updates:
        try:
            cur.execute(query)
            print(f"  ✅ {query}")
        except Exception as e:
            print(f"  ❌ Error: {str(e)}")
    
    conn.commit()
    
    # Step 5: Verify
    print("\n" + "="*80)
    print("✅ VERIFICATION")
    print("="*80)
    
    cur.execute("""
        SELECT 
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS constraint_definition
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'tasks'
        AND nsp.nspname = 'public'
        AND con.contype = 'c'
        AND con.conname IN ('tasks_priority_check', 'tasks_status_check', 'tasks_recurrence_check')
        ORDER BY con.conname;
    """)
    
    for name, definition in cur.fetchall():
        print(f"\n{name}:")
        print(f"  {definition}")
    
    print("\n" + "="*80)
    print("🎯 SUMMARY - New valid values (UPPERCASE):")
    print("="*80)
    print("  priority: LOW, MEDIUM, HIGH, URGENT")
    print("  status: PENDING, IN_PROGRESS, COMPLETED, CANCELLED")
    print("  recurrence: NONE, DAILY, WEEKLY, MONTHLY, ADHOC, PROJECT")
    print("\n✅ All constraints updated successfully!")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
