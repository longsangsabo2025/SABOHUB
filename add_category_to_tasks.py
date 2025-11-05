"""
Add category column to tasks table
"""
import os
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv()

def add_category_column():
    """Add category column to tasks table"""
    
    # Get database credentials from environment
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not db_url:
        print("❌ Error: SUPABASE_CONNECTION_STRING not found in environment")
        return False
    
    try:
        # Connect to database
        print("📡 Connecting to database...")
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Check if column already exists
        print("🔍 Checking if category column exists...")
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'category'
        """)
        
        if cur.fetchone():
            print("✅ Column 'category' already exists in tasks table")
            return True
        
        # Add category column with default value
        print("➕ Adding category column to tasks table...")
        cur.execute("""
            ALTER TABLE tasks 
            ADD COLUMN category TEXT DEFAULT 'operations';
        """)
        
        print("✅ Successfully added category column to tasks table")
        
        # Add comment to column
        print("📝 Adding column comment...")
        cur.execute("""
            COMMENT ON COLUMN tasks.category IS 
            'Task category: operations, sales, delivery, inventory, customer_service, maintenance, admin, other';
        """)
        
        # Verify the column was added
        print("🔍 Verifying column addition...")
        cur.execute("""
            SELECT column_name, data_type, column_default, is_nullable
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'category'
        """)
        
        result = cur.fetchone()
        if result:
            col_name, data_type, default_val, nullable = result
            print(f"✅ Verification successful:")
            print(f"   - Column: {col_name}")
            print(f"   - Type: {data_type}")
            print(f"   - Default: {default_val}")
            print(f"   - Nullable: {nullable}")
        else:
            print("❌ Error: Could not verify column addition")
            return False
        
        # Show updated table structure
        print("\n📊 Updated tasks table structure:")
        cur.execute("""
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'tasks'
            ORDER BY ordinal_position
        """)
        
        columns = cur.fetchall()
        for col in columns:
            col_name, data_type, nullable, default = col
            default_str = f" DEFAULT {default}" if default else ""
            nullable_str = "NULL" if nullable == "YES" else "NOT NULL"
            print(f"   - {col_name}: {data_type} {nullable_str}{default_str}")
        
        cur.close()
        conn.close()
        
        print("\n✅ Migration completed successfully!")
        print("📝 You can now create tasks with category field")
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        print(f"   Error details: {e.pgerror}")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("🚀 Adding category column to tasks table")
    print("=" * 60)
    
    success = add_category_column()
    
    if success:
        print("\n✅ All operations completed successfully!")
    else:
        print("\n❌ Migration failed. Please check the errors above.")
