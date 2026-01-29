"""
Revert tasks table constraints back to lowercase
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
    print("🔧 REVERTING TASKS TABLE CONSTRAINTS TO lowercase")
    print("="*80)
    print("\nConverting back to lowercase to match enum.name in Flutter\n")
    
    # Step 1: Drop current constraints
    print("Step 1: Dropping UPPERCASE constraints...")
    
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
    
    # Step 2: Convert existing data to lowercase
    print("\nStep 2: Converting existing data to lowercase...")
    
    update_queries = [
        ("priority", "UPDATE public.tasks SET priority = LOWER(priority);"),
        ("status", "UPDATE public.tasks SET status = LOWER(status);"),
        ("recurrence", "UPDATE public.tasks SET recurrence = LOWER(recurrence);"),
    ]
    
    for field, query in update_queries:
        try:
            cur.execute(query)
            rows_updated = cur.rowcount
            print(f"  ✅ Updated {rows_updated} rows in {field}")
        except Exception as e:
            print(f"  ⚠️  Error updating {field}: {str(e)}")
    
    conn.commit()
    
    # Step 3: Add new constraints with lowercase values
    print("\nStep 3: Adding new constraints with lowercase values...")
    
    new_constraints = [
        (
            "tasks_priority_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_priority_check CHECK (priority IN ('low', 'medium', 'high', 'urgent'));"
        ),
        (
            "tasks_status_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_status_check CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'));"
        ),
        (
            "tasks_recurrence_check",
            "ALTER TABLE public.tasks ADD CONSTRAINT tasks_recurrence_check CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly', 'adhoc', 'project'));"
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
    print("\nStep 4: Updating default values to lowercase...")
    
    default_updates = [
        "ALTER TABLE public.tasks ALTER COLUMN priority SET DEFAULT 'medium';",
        "ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'pending';",
        "ALTER TABLE public.tasks ALTER COLUMN recurrence SET DEFAULT 'none';",
    ]
    
    for query in default_updates:
        try:
            cur.execute(query)
            print(f"  ✅ {query}")
        except Exception as e:
            print(f"  ❌ Error: {str(e)}")
    
    conn.commit()
    
    # Step 5: Also need to update users.role to lowercase
    print("\nStep 5: Checking users.role constraint...")
    
    # Check current role constraint
    cur.execute("""
        SELECT pg_get_constraintdef(con.oid) AS constraint_definition
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'users'
        AND nsp.nspname = 'public'
        AND con.conname = 'users_role_check';
    """)
    
    result = cur.fetchone()
    if result:
        print(f"  Current: {result[0]}")
        
        # Drop and recreate with lowercase
        try:
            cur.execute("ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;")
            print("  ✅ Dropped users_role_check")
            
            # Convert existing roles to lowercase
            cur.execute("UPDATE public.users SET role = LOWER(role);")
            print(f"  ✅ Converted {cur.rowcount} user roles to lowercase")
            
            # Add new constraint
            cur.execute("""
                ALTER TABLE public.users 
                ADD CONSTRAINT users_role_check 
                CHECK (role IN ('ceo', 'manager', 'shift_leader', 'staff'));
            """)
            print("  ✅ Added new lowercase constraint for users.role")
            
            conn.commit()
        except Exception as e:
            print(f"  ❌ Error updating users.role: {str(e)}")
            conn.rollback()
    
    # Step 6: Verify
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
    print("🎯 SUMMARY - New valid values (lowercase):")
    print("="*80)
    print("  priority: low, medium, high, urgent")
    print("  status: pending, in_progress, completed, cancelled")
    print("  recurrence: none, daily, weekly, monthly, adhoc, project")
    print("  role (users): ceo, manager, shift_leader, staff")
    print("\n✅ All constraints reverted to lowercase!")
    print("\n💡 This matches Flutter enum.name behavior:")
    print("   TaskPriority.medium.name = 'medium' ✅")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
