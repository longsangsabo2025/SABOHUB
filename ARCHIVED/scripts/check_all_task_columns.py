"""
Check all columns in tasks table vs code requirements
"""
import os
from dotenv import load_dotenv
import psycopg2
import re

# Load environment variables
load_dotenv()

def check_task_schema():
    """Check tasks table schema and compare with code"""
    
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not db_url:
        print("❌ Error: SUPABASE_CONNECTION_STRING not found")
        return
    
    try:
        print("=" * 70)
        print("🔍 CHECKING TASKS TABLE SCHEMA")
        print("=" * 70)
        
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        
        # Get current tasks table structure
        print("\n📊 Current tasks table columns:")
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'tasks'
            ORDER BY ordinal_position
        """)
        
        current_columns = {}
        for row in cur.fetchall():
            col_name, data_type, nullable, default = row
            current_columns[col_name] = {
                'type': data_type,
                'nullable': nullable,
                'default': default
            }
            print(f"   ✓ {col_name}: {data_type} ({'NULL' if nullable == 'YES' else 'NOT NULL'})")
        
        # Expected columns based on task_service.dart analysis
        print("\n📝 Expected columns from task_service.dart:")
        expected_columns = {
            'id': 'uuid',
            'company_id': 'uuid',
            'store_id': 'uuid',
            'branch_id': 'uuid',
            'title': 'text',
            'description': 'text',
            'category': 'text',
            'priority': 'text',
            'status': 'text',
            'assigned_to': 'uuid',
            'assigned_to_name': 'text',
            'created_by': 'uuid',
            'created_by_name': 'text',  # Missing!
            'due_date': 'timestamp with time zone',
            'completed_at': 'timestamp with time zone',
            'created_at': 'timestamp with time zone',
            'updated_at': 'timestamp with time zone'
        }
        
        # Find missing columns
        missing_columns = []
        for col_name, col_type in expected_columns.items():
            if col_name in current_columns:
                print(f"   ✓ {col_name}: EXISTS")
            else:
                print(f"   ❌ {col_name}: MISSING")
                missing_columns.append((col_name, col_type))
        
        # Find extra columns (not expected)
        print("\n🔍 Extra columns in database (not in code):")
        extra_columns = []
        for col_name in current_columns.keys():
            if col_name not in expected_columns:
                print(f"   ⚠️  {col_name}: NOT USED IN CODE")
                extra_columns.append(col_name)
        
        if not extra_columns:
            print("   ✓ No extra columns")
        
        # Generate ALTER TABLE statements
        if missing_columns:
            print("\n" + "=" * 70)
            print("🔧 REQUIRED MIGRATIONS")
            print("=" * 70)
            print("\nSQL statements to add missing columns:\n")
            
            for col_name, col_type in missing_columns:
                default_value = "'Unknown'"
                if col_type == 'uuid':
                    default_value = "NULL"
                elif col_type == 'text':
                    default_value = "'Unknown'"
                elif 'timestamp' in col_type:
                    default_value = "NULL"
                
                if default_value == "NULL":
                    print(f"ALTER TABLE tasks ADD COLUMN {col_name} {col_type} DEFAULT {default_value};")
                else:
                    print(f"ALTER TABLE tasks ADD COLUMN {col_name} {col_type} DEFAULT {default_value};")
            
            print("\n" + "-" * 70)
            return missing_columns
        else:
            print("\n✅ All required columns exist!")
            return []
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return None
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

def add_missing_columns(missing_columns):
    """Add all missing columns to tasks table"""
    
    if not missing_columns:
        print("\n✅ No columns to add!")
        return True
    
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    try:
        print("\n" + "=" * 70)
        print("🚀 ADDING MISSING COLUMNS")
        print("=" * 70)
        
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        for col_name, col_type in missing_columns:
            print(f"\n➕ Adding column: {col_name} ({col_type})")
            
            # Determine default value
            if col_name == 'created_by_name':
                default_value = "'Unknown'"
            else:
                default_value = "NULL"
            
            # Add column
            if default_value == "NULL":
                sql = f"ALTER TABLE tasks ADD COLUMN IF NOT EXISTS {col_name} {col_type} DEFAULT {default_value};"
            else:
                sql = f"ALTER TABLE tasks ADD COLUMN IF NOT EXISTS {col_name} {col_type} DEFAULT {default_value};"
            
            print(f"   SQL: {sql}")
            cur.execute(sql)
            print(f"   ✅ Added {col_name}")
        
        # Verify all columns were added
        print("\n🔍 Verifying columns...")
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'tasks'
            ORDER BY ordinal_position
        """)
        
        print("\n📊 Final tasks table structure:")
        for row in cur.fetchall():
            col_name, data_type, nullable, default = row
            default_str = f" DEFAULT {default}" if default else ""
            nullable_str = "NULL" if nullable == "YES" else "NOT NULL"
            print(f"   {col_name}: {data_type} {nullable_str}{default_str}")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ ALL MISSING COLUMNS ADDED SUCCESSFULLY!")
        print("=" * 70)
        return True
        
    except Exception as e:
        print(f"\n❌ Error adding columns: {e}")
        return False

if __name__ == "__main__":
    # Step 1: Check schema and find missing columns
    missing = check_task_schema()
    
    if missing is None:
        print("\n❌ Failed to check schema")
    elif missing:
        # Step 2: Add missing columns
        print("\n" + "=" * 70)
        response = input("Do you want to add these missing columns? (yes/no): ")
        if response.lower() in ['yes', 'y']:
            success = add_missing_columns(missing)
            if not success:
                print("\n❌ Failed to add columns")
        else:
            print("\n⏭️  Skipped adding columns")
    else:
        print("\n✅ Schema is complete!")
