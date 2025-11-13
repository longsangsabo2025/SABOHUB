"""
Add progress column to tasks table
"""
import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def add_progress_column():
    """Add progress column to tasks table"""
    
    sql = """
    -- Add progress column to tasks table
    DO $$ 
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'tasks' 
            AND column_name = 'progress'
        ) THEN
            ALTER TABLE public.tasks 
            ADD COLUMN progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100);
            
            COMMENT ON COLUMN public.tasks.progress IS 'Task completion progress (0-100%)';
        END IF;
    END $$;
    
    -- Update existing tasks to have 0% progress if pending, 50% if in_progress, 100% if completed
    UPDATE public.tasks
    SET progress = CASE 
        WHEN status = 'COMPLETED' THEN 100
        WHEN status = 'IN_PROGRESS' THEN 50
        WHEN status = 'PENDING' THEN 0
        WHEN status = 'CANCELLED' THEN 0
        ELSE 0
    END
    WHERE progress IS NULL;
    """
    
    try:
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print("✅ Successfully added progress column to tasks table")
        return True
    except Exception as e:
        # If rpc method doesn't exist, try direct query
        print(f"⚠️  RPC method not available, trying direct execution...")
        try:
            # Split into individual statements
            statements = [s.strip() for s in sql.split(';') if s.strip()]
            
            for stmt in statements:
                if stmt:
                    result = supabase.postgrest.rpc('exec_sql', {'sql': stmt}).execute()
            
            print("✅ Successfully added progress column to tasks table")
            return True
        except Exception as e2:
            print(f"❌ Error adding progress column: {str(e2)}")
            print(f"Original error: {str(e)}")
            return False

if __name__ == "__main__":
    print("🔧 Adding progress column to tasks table...")
    add_progress_column()
