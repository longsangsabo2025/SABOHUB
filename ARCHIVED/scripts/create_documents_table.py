"""
Auto-create documents table in Supabase
"""
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

def create_documents_table():
    """Create documents table using SQL file"""
    
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("❌ Error: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not found in .env")
        return
    
    try:
        # Create Supabase client with service role
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        
        print("🔄 Reading SQL file...")
        with open('create_documents_table.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("🔄 Executing SQL...")
        # Execute SQL via RPC
        result = supabase.rpc('exec_sql', {'query': sql_content}).execute()
        
        print("✅ Documents table created successfully!")
        print("\n📋 Table structure:")
        print("- id (UUID, Primary Key)")
        print("- google_drive_file_id (TEXT, UNIQUE)")
        print("- file_name (TEXT)")
        print("- file_type (TEXT)")
        print("- file_size (BIGINT)")
        print("- company_id (UUID, FK)")
        print("- uploaded_by (UUID, FK)")
        print("- document_type (TEXT)")
        print("- description (TEXT)")
        print("- created_at (TIMESTAMPTZ)")
        print("- updated_at (TIMESTAMPTZ)")
        print("\n✅ RLS Policies enabled!")
        print("✅ Indexes created!")
        
    except Exception as e:
        print(f"❌ Error creating documents table: {e}")
        print("\n💡 Alternative: Run the SQL manually in Supabase Dashboard:")
        print("1. Go to Supabase Dashboard → SQL Editor")
        print("2. Copy content from create_documents_table.sql")
        print("3. Paste and execute")

if __name__ == "__main__":
    print("🚀 Creating documents table in Supabase...")
    print("=" * 60)
    create_documents_table()
