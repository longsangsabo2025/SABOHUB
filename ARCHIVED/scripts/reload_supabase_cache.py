"""
Reload Supabase schema cache by calling NOTIFY
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
    print("🔄 RELOADING SUPABASE SCHEMA CACHE")
    print("="*80)
    
    # Send NOTIFY to reload PostgREST schema cache
    print("\nSending NOTIFY pgrst to reload schema cache...")
    cur.execute("NOTIFY pgrst, 'reload schema';")
    conn.commit()
    print("✅ Schema cache reload signal sent!")
    
    print("\nℹ️  PostgREST will reload the schema cache within a few seconds.")
    print("   You can also restart the Supabase project for immediate effect.")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"\n❌ Error: {str(e)}")
    print("\nAlternative: Restart your Supabase project from the dashboard:")
    print("  1. Go to https://supabase.com/dashboard")
    print("  2. Select your project")
    print("  3. Go to Settings > Database")
    print("  4. Click 'Restart' or wait for auto-reload")
