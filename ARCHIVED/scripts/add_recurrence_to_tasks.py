"""
Add recurrence column to tasks table using direct PostgreSQL connection
"""
import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def add_recurrence_column():
    """Add recurrence column to tasks table"""
    try:
        # Get connection string from .env
        connection_string = os.environ.get("SUPABASE_CONNECTION_STRING")
        
        if not connection_string:
            print("❌ SUPABASE_CONNECTION_STRING not found in .env")
            return
        
        print("🔌 Connecting to PostgreSQL...")
        conn = psycopg2.connect(connection_string)
        cur = conn.cursor()
        
        # Check if column exists
        print("🔍 Checking if recurrence column exists...")
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'tasks' AND column_name = 'recurrence';
        """)
        
        exists = cur.fetchone()
        
        if exists:
            print("✅ Column 'recurrence' already exists!")
            
            # Show current values
            cur.execute("SELECT recurrence, COUNT(*) FROM tasks GROUP BY recurrence;")
            results = cur.fetchall()
            print(f"\n📊 Current recurrence values:")
            for row in results:
                print(f"  - {row[0]}: {row[1]} tasks")
        else:
            print("➕ Adding recurrence column...")
            
            # Add column
            cur.execute("""
                ALTER TABLE tasks 
                ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none';
            """)
            
            # Add constraint
            cur.execute("""
                ALTER TABLE tasks 
                ADD CONSTRAINT tasks_recurrence_check 
                CHECK (recurrence IN ('none', 'daily', 'weekly', 'monthly', 'adhoc', 'project'));
            """)
            
            conn.commit()
            print("✅ Successfully added recurrence column!")
            
            # Verify
            cur.execute("SELECT COUNT(*) FROM tasks;")
            count = cur.fetchone()[0]
            print(f"📊 Total tasks: {count}")
            print(f"📊 All tasks now have recurrence = 'none' by default")
        
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()
        raise

if __name__ == "__main__":
    print("🔧 Adding recurrence column to tasks table...")
    add_recurrence_column()
    print("\n✅ Done!")
