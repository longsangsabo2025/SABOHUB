"""
Direct PostgreSQL migration: Add employee names to tasks table
Uses psycopg2 to connect directly to Supabase Postgres
"""

import psycopg2
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Get connection string from .env
DATABASE_URL = os.getenv('SUPABASE_CONNECTION_STRING')

if not DATABASE_URL:
    print("❌ SUPABASE_CONNECTION_STRING not found in .env file")
    exit(1)

def run_migration():
    """Run the migration to add employee names to tasks"""
    print("\n📋 === ADDING EMPLOYEE NAMES TO TASKS TABLE ===\n")
    
    conn = None
    cursor = None
    
    try:
        # Connect to database
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        print("   ✅ Connected successfully")
        
        # Step 1: Add columns
        print("\n1️⃣ Adding columns to tasks table...")
        cursor.execute("""
            ALTER TABLE tasks 
            ADD COLUMN IF NOT EXISTS assigned_to_name TEXT,
            ADD COLUMN IF NOT EXISTS assigned_to_role TEXT;
        """)
        conn.commit()
        print("   ✅ Columns added: assigned_to_name, assigned_to_role")
        
        # Step 2: Update existing records with assigned_to info
        print("\n2️⃣ Updating existing tasks with employee names...")
        cursor.execute("""
            UPDATE tasks t
            SET 
              assigned_to_name = u.full_name,
              assigned_to_role = u.role
            FROM users u
            WHERE t.assigned_to = u.id AND t.assigned_to_name IS NULL;
        """)
        rows_updated = cursor.rowcount
        conn.commit()
        print(f"   ✅ Updated {rows_updated} tasks with assigned_to info")
        
        # Step 4: Create indexes
        print("\n3️⃣ Creating performance indexes...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_name 
            ON tasks(assigned_to_name) 
            WHERE assigned_to_name IS NOT NULL;
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_company_assignee 
            ON tasks(company_id, assigned_to);
        """)
        conn.commit()
        print("   ✅ Indexes created for better query performance")
        
        # Step 5: Get total task count
        print("\n4️⃣ Verifying migration...")
        cursor.execute("SELECT COUNT(*) FROM tasks;")
        result = cursor.fetchone()
        total_tasks = result[0] if result else 0
        
        cursor.execute("SELECT COUNT(*) FROM tasks WHERE assigned_to_name IS NOT NULL;")
        result2 = cursor.fetchone()
        tasks_with_names = result2[0] if result2 else 0
        
        # Get sample task
        cursor.execute("""
            SELECT id, title, assigned_to_name, assigned_to_role 
            FROM tasks 
            WHERE assigned_to_name IS NOT NULL 
            LIMIT 1;
        """)
        sample = cursor.fetchone()
        
        if sample:
            print("   ✅ Sample task:")
            print(f"      - ID: {sample[0]}")
            print(f"      - Title: {sample[1]}")
            print(f"      - Assigned to: {sample[2]}")
            print(f"      - Role: {sample[3]}")
        
        print("\n✅ === MIGRATION COMPLETED SUCCESSFULLY ===\n")
        
        # Summary
        print("📊 SUMMARY:")
        print(f"   • Total tasks: {total_tasks}")
        print(f"   • Tasks with names: {tasks_with_names}")
        print("   • New columns: 2 (assigned_to_name, assigned_to_role)")
        print("   • New indexes: 2")
        print("\n💡 NEXT STEPS:")
        print("   1. Update TaskService.createTask() to populate these fields")
        print("   2. Update TaskService.updateTask() to maintain name consistency")
        print("   3. Update UI to display names instead of UUIDs")
        
    except psycopg2.Error as e:
        print(f"\n❌ Database Error: {e}")
        if conn:
            conn.rollback()
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        if conn:
            conn.rollback()
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
            print("\n🔌 Database connection closed")

if __name__ == "__main__":
    run_migration()
