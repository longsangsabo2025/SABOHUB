"""
Check the actual foreign key constraint for tasks.assigned_to
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
    print("🔍 CHECKING TASKS FOREIGN KEY CONSTRAINTS")
    print("="*80)
    
    # Get all foreign key constraints on tasks table
    cur.execute("""
        SELECT
            tc.constraint_name,
            kcu.column_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
        AND tc.table_name = 'tasks';
    """)
    
    print("\n📋 Foreign key constraints on tasks table:")
    for const_name, column, fk_schema, fk_table, fk_column in cur.fetchall():
        print(f"\n  {const_name}:")
        print(f"    tasks.{column} → {fk_schema}.{fk_table}.{fk_column}")
    
    # Check if employees table exists
    print("\n" + "="*80)
    print("👥 CHECKING EMPLOYEES TABLE")
    print("="*80)
    
    cur.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'employees'
        );
    """)
    
    employees_exists = cur.fetchone()[0]
    
    if employees_exists:
        print("\n✅ employees table EXISTS")
        
        # Count employees
        cur.execute("SELECT COUNT(*) FROM employees WHERE deleted_at IS NULL;")
        emp_count = cur.fetchone()[0]
        print(f"📊 Total active employees: {emp_count}")
        
        if emp_count > 0:
            # Show sample employees
            cur.execute("SELECT id, name, email FROM employees WHERE deleted_at IS NULL LIMIT 10;")
            print("\nSample employees:")
            for emp_id, name, email in cur.fetchall():
                print(f"  - {emp_id} | {name} | {email}")
    else:
        print("\n❌ employees table DOES NOT EXIST!")
    
    # Check users table too
    print("\n" + "="*80)
    print("👤 CHECKING USERS TABLE")
    print("="*80)
    
    cur.execute("SELECT COUNT(*) FROM users WHERE deleted_at IS NULL;")
    user_count = cur.fetchone()[0]
    print(f"📊 Total active users: {user_count}")
    
    if user_count > 0:
        cur.execute("SELECT id, email, role FROM users WHERE deleted_at IS NULL LIMIT 5;")
        print("\nSample users:")
        for user_id, email, role in cur.fetchall():
            print(f"  - {user_id} | {email} | {role}")
    
    print("\n" + "="*80)
    print("💡 ANALYSIS")
    print("="*80)
    print("\nThe error says: 'Key is not present in table \"users\"'")
    print("This means tasks.assigned_to references users.id (NOT employees.id)")
    print("\n⚠️  Need to:")
    print("  1. Drop the current foreign key constraint")
    print("  2. Recreate it to reference employees.id instead of users.id")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
