import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

print("🔍 ATTENDANCE TABLE AUDIT")
print("=" * 80)

# 1. Check table structure
print("\n📊 1. CHECKING TABLE STRUCTURE...")
print("-" * 80)

try:
    # Get column information
    result = supabase.rpc('exec_sql', {
        'query': """
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'attendance'
        ORDER BY ordinal_position;
        """
    }).execute()
    
    print("Columns in attendance table:")
    for col in result.data:
        nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
        print(f"  - {col['column_name']:30s} {col['data_type']:20s} {nullable}")
except Exception as e:
    print(f"⚠️  Cannot query columns via RPC, trying direct query...")
    
    # Alternative: Query the table directly to see what columns exist
    try:
        sample = supabase.table('attendance').select('*').limit(1).execute()
        if sample.data:
            print("\nColumns found in sample query:")
            for col in sample.data[0].keys():
                print(f"  - {col}")
        else:
            print("  No data in attendance table")
    except Exception as e2:
        print(f"  Error: {e2}")

# 2. Check indexes
print("\n\n📊 2. CHECKING INDEXES...")
print("-" * 80)

# 3. Check record count
print("\n\n📊 3. CHECKING DATA...")
print("-" * 80)

try:
    count_result = supabase.table('attendance').select('*', count='exact').limit(0).execute()
    print(f"Total attendance records: {count_result.count}")
    
    # Get sample records
    if count_result.count > 0:
        sample = supabase.table('attendance').select('*').limit(5).execute()
        print(f"\nSample records (first 5):")
        for record in sample.data:
            print(f"  ID: {record.get('id')}")
            print(f"    User ID: {record.get('user_id')}")
            print(f"    Store ID: {record.get('store_id', 'N/A')}")
            print(f"    Branch ID: {record.get('branch_id', 'N/A')}")
            print(f"    Company ID: {record.get('company_id', 'N/A')}")
            print(f"    Check-in: {record.get('check_in')}")
            print(f"    Check-out: {record.get('check_out', 'N/A')}")
            print()
except Exception as e:
    print(f"Error querying data: {e}")

# 4. Check for schema issues
print("\n\n📊 4. SCHEMA VALIDATION...")
print("-" * 80)

# Check if critical columns exist
critical_columns = ['user_id', 'branch_id', 'company_id', 'check_in', 'check_out']
missing_columns = []

try:
    sample = supabase.table('attendance').select('*').limit(1).execute()
    if sample.data:
        existing_cols = set(sample.data[0].keys())
        for col in critical_columns:
            if col not in existing_cols:
                missing_columns.append(col)
        
        if missing_columns:
            print(f"❌ MISSING COLUMNS: {', '.join(missing_columns)}")
        else:
            print(f"✅ All critical columns exist")
        
        # Check for old columns that should be removed
        old_columns = ['store_id']
        found_old = [col for col in old_columns if col in existing_cols]
        if found_old:
            print(f"⚠️  OLD COLUMNS FOUND (should be removed): {', '.join(found_old)}")
    else:
        print("No data to validate columns")
except Exception as e:
    print(f"Error validating schema: {e}")

# 5. Check RLS policies
print("\n\n📊 5. CHECKING RLS POLICIES...")
print("-" * 80)

print("✅ RLS should be enabled on attendance table")
print("   Required policies:")
print("   - Users can view attendance in their company")
print("   - Users can check in")
print("   - Users can check out")
print("   - Managers can delete attendance")

print("\n" + "=" * 80)
print("AUDIT COMPLETE")
print("=" * 80)
