"""
Run AI Assistant tables migration
"""
import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Get Supabase credentials
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ Missing Supabase credentials in .env file")
    exit(1)

# Create Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

print("🔧 Running AI Assistant tables migration...")

# Read migration file
migration_file = 'supabase/migrations/20251102_ai_assistant_tables_fixed.sql'
with open(migration_file, 'r', encoding='utf-8') as f:
    sql = f.read()

try:
    # Execute migration
    supabase.postgrest.rpc('exec_sql', {'query': sql}).execute()
    print("✅ Migration completed successfully!")
except Exception as e:
    print(f"❌ Migration error: {str(e)}")
    print("\nTrying alternative method...")
    
    # Try using psycopg2 if available
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        # Parse database URL
        db_url = os.getenv('DATABASE_URL')
        if not db_url:
            print("❌ DATABASE_URL not found in .env")
            exit(1)
            
        result = urlparse(db_url)
        username = result.username
        password = result.password
        database = result.path[1:]
        hostname = result.hostname
        port = result.port
        
        # Connect to database
        connection = psycopg2.connect(
            database=database,
            user=username,
            password=password,
            host=hostname,
            port=port
        )
        
        cursor = connection.cursor()
        cursor.execute(sql)
        connection.commit()
        
        print("✅ Migration completed successfully (via psycopg2)!")
        
        cursor.close()
        connection.close()
    except ImportError:
        print("❌ psycopg2 not available. Please install it: pip install psycopg2-binary")
    except Exception as e2:
        print(f"❌ Alternative method error: {str(e2)}")
