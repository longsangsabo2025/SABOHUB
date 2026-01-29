from supabase import create_client, Client
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")  # Use service role key for admin operations
supabase: Client = create_client(url, key)

print("🔧 Fixing RLS policies for employees table...")
print("=" * 80)

# Read SQL file
with open("fix_employees_rls_policy.sql", "r", encoding="utf-8") as f:
    sql_content = f.read()

# Split into individual statements (skip comments and empty lines)
statements = []
current_statement = []

for line in sql_content.split("\n"):
    line = line.strip()
    
    # Skip comments and empty lines
    if line.startswith("--") or not line:
        continue
        
    current_statement.append(line)
    
    # If line ends with semicolon, it's end of statement
    if line.endswith(";"):
        statement = " ".join(current_statement)
        statements.append(statement)
        current_statement = []

print(f"📝 Found {len(statements)} SQL statements to execute")
print()

# Execute each statement
for i, statement in enumerate(statements, 1):
    # Skip SELECT statements (just for verification)
    if statement.strip().upper().startswith("SELECT"):
        print(f"⏭️  Skipping statement {i}: SELECT query")
        continue
        
    try:
        # Extract first word for display
        first_word = statement.split()[0].upper()
        print(f"⚙️  Executing statement {i}: {first_word}...")
        
        # Execute using rpc or raw SQL
        result = supabase.rpc("exec_sql", {"sql": statement}).execute()
        
        print(f"✅ Statement {i} executed successfully")
        
    except Exception as e:
        # Try direct postgrest API if rpc fails
        try:
            response = supabase.postgrest.rpc("exec_sql", {"sql": statement}).execute()
            print(f"✅ Statement {i} executed successfully (via postgrest)")
        except Exception as e2:
            print(f"❌ Failed to execute statement {i}: {str(e)}")
            print(f"   Alternative attempt also failed: {str(e2)}")
            print(f"   Statement: {statement[:100]}...")
            print()

print()
print("=" * 80)
print("✅ RLS policy fix completed!")
print()
print("📋 Please manually run this SQL in Supabase SQL Editor:")
print("   1. Go to Supabase Dashboard > SQL Editor")
print("   2. Open file: fix_employees_rls_policy.sql")
print("   3. Click 'Run' to execute all statements")
print()
print("🔍 After running, verify with this query:")
print("   SELECT * FROM pg_policies WHERE tablename = 'employees';")
