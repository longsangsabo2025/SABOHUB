"""
Check if AI Assistant tables exist in database
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

print("🔍 Checking AI Assistant tables...\n")

# Check ai_assistants table
try:
    result = supabase.table('ai_assistants').select('*').limit(1).execute()
    print(f"✅ ai_assistants table exists")
    print(f"   Records: {len(result.data)}")
except Exception as e:
    print(f"❌ ai_assistants table error: {str(e)}")

print()

# Check ai_messages table
try:
    result = supabase.table('ai_messages').select('*').limit(1).execute()
    print(f"✅ ai_messages table exists")
    print(f"   Records: {len(result.data)}")
except Exception as e:
    print(f"❌ ai_messages table error: {str(e)}")

print("\n✨ Done!")
