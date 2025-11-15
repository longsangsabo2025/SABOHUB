import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

# Initialize Supabase
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

print("=" * 60)
print("DAILY_WORK_REPORTS TABLE STRUCTURE")
print("=" * 60)

try:
    # Try to get one record to see column names
    result = supabase.table('daily_work_reports').select('*').limit(1).execute()
    
    if result.data and len(result.data) > 0:
        print("\n✅ Table exists with data!")
        print(f"\n📋 Columns in table:")
        for i, column in enumerate(result.data[0].keys(), 1):
            value = result.data[0][column]
            # Show type based on value
            type_name = type(value).__name__
            print(f"  {i}. {column}: {type_name}")
        
        print(f"\n📊 Sample record:")
        for key, value in result.data[0].items():
            # Truncate long text
            display_value = str(value)[:50] + "..." if len(str(value)) > 50 else value
            print(f"  {key}: {display_value}")
            
        print(f"\nTotal columns: {len(result.data[0])}")
        
    else:
        print("\n⚠️ Table exists but is EMPTY")
        print("Need to create a record to see structure.")
        print("\nAttempting to check via RPC or direct query...")
        
except Exception as e:
    print(f"\n❌ Error accessing table: {e}")
    print("\nPossible reasons:")
    print("  1. Table doesn't exist")
    print("  2. RLS policies blocking access")
    print("  3. Permission issues")
    
print("\n" + "=" * 60)
