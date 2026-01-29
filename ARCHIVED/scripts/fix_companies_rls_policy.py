"""
Fix RLS policy để cho phép CEO và authenticated users đọc companies
"""
import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client với SERVICE_ROLE_KEY
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

def fix_companies_select_policy():
    """Fix RLS policy for companies SELECT"""
    print("\n" + "="*60)
    print("🔧 FIX COMPANIES SELECT POLICY")
    print("="*60)
    
    # Step 1: Drop existing SELECT policies
    print("\n1️⃣ Dropping existing SELECT policies...")
    policies_to_drop = [
        "Companies SELECT policy",
        "Allow CEO to select companies",
        "Allow authenticated users to select companies"
    ]
    
    for policy_name in policies_to_drop:
        try:
            query = f"DROP POLICY IF EXISTS \"{policy_name}\" ON companies;"
            supabase.rpc('exec_sql', {'query': query}).execute()
            print(f"   ✅ Dropped: {policy_name}")
        except Exception as e:
            print(f"   ⚠️  {policy_name}: {str(e)[:100]}")
    
    # Step 2: Create new SELECT policy for all authenticated users
    print("\n2️⃣ Creating new SELECT policy...")
    try:
        query = """
        CREATE POLICY "Allow authenticated users to select companies"
        ON companies
        FOR SELECT
        TO authenticated
        USING (true);
        """
        
        # Note: Supabase Python client doesn't have direct SQL execution
        # We need to use the REST API or create a stored procedure
        print("   ℹ️  Cannot execute CREATE POLICY via Python client")
        print("   ℹ️  Please run this SQL in Supabase SQL Editor:")
        print("\n" + "-"*60)
        print(query)
        print("-"*60)
        
    except Exception as e:
        print(f"   ❌ Error: {e}")

def test_companies_access():
    """Test if we can now read companies"""
    print("\n3️⃣ Testing companies access...")
    try:
        # Use ANON_KEY (like the app does)
        test_client = create_client(
            os.getenv('SUPABASE_URL'),
            os.getenv('SUPABASE_ANON_KEY')
        )
        
        response = test_client.table('companies').select('id, name').execute()
        
        print(f"\n   ✅ Success! Found {len(response.data)} companies")
        for company in response.data:
            print(f"      - {company['name']}")
            
    except Exception as e:
        print(f"\n   ❌ Still cannot access: {e}")
        print("\n   💡 You need to run the SQL in Supabase Dashboard")

if __name__ == '__main__':
    print("\n" + "="*60)
    print("⚠️  IMPORTANT: RLS POLICY FIX")
    print("="*60)
    print("\nVấn đề: CEO không thể đọc companies vì RLS policy chặn")
    print("Giải pháp: Tạo policy cho phép authenticated users SELECT companies")
    print("\nBạn cần chạy SQL sau trong Supabase Dashboard:")
    print("https://supabase.com/dashboard/project/dqddxowyikefqcdiioyh/sql/new")
    print("\n" + "="*60)
    
    sql_to_run = """
-- Drop old policies
DROP POLICY IF EXISTS "Companies SELECT policy" ON companies;
DROP POLICY IF EXISTS "Allow CEO to select companies" ON companies;
DROP POLICY IF EXISTS "Allow authenticated users to select companies" ON companies;

-- Create new policy: Allow all authenticated users to SELECT
CREATE POLICY "Allow authenticated users to select companies"
ON companies
FOR SELECT
TO authenticated
USING (true);

-- Verify
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'companies';
"""
    
    print(sql_to_run)
    print("="*60)
    
    input("\n📌 Nhấn Enter sau khi đã chạy SQL trên Supabase Dashboard...")
    
    # Test after user confirms
    test_companies_access()
    
    print("\n" + "="*60)
    print("✅ HOÀN THÀNH")
    print("="*60)
    print("\nSau khi chạy SQL, hãy:")
    print("1. Press 'R' trong Flutter terminal để hot reload")
    print("2. Mở lại dialog 'Tạo nhiệm vụ mới'")
    print("3. Dropdown 'Công ty' sẽ hiển thị 'SABO Billiards'")
