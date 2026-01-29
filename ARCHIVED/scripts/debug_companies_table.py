"""
Script to check companies table structure and fix CEO column issue
"""
import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def check_companies_structure():
    """Check the actual structure of companies table"""
    print("\n" + "="*80)
    print("🔍 CHECKING COMPANIES TABLE STRUCTURE")
    print("="*80)
    
    try:
        # Get a sample company to see its structure
        response = supabase.table('companies').select('*').limit(1).execute()
        
        if response.data:
            company = response.data[0]
            print("\n✅ Companies table exists!")
            print("\n📋 Available columns:")
            for key in sorted(company.keys()):
                value = company[key]
                print(f"   - {key}: {type(value).__name__} = {value}")
            
            # Check for CEO-related columns
            print("\n🔍 CEO-related columns found:")
            ceo_columns = [k for k in company.keys() if 'ceo' in k.lower()]
            if ceo_columns:
                for col in ceo_columns:
                    print(f"   ✅ {col}")
            else:
                print("   ❌ No CEO-related columns found!")
            
            return company.keys()
        else:
            print("\n⚠️ No companies found in database")
            return []
            
    except Exception as e:
        print(f"\n❌ Error checking companies table: {e}")
        return []

def get_current_user_company():
    """Try to get company with different CEO column names"""
    print("\n" + "="*80)
    print("🧪 TESTING DIFFERENT CEO COLUMN NAMES")
    print("="*80)
    
    # Get a test user ID (CEO)
    try:
        users_response = supabase.table('users').select('id, full_name, role').eq('role', 'CEO').limit(1).execute()
        
        if not users_response.data:
            print("\n⚠️ No CEO users found in database")
            return None
            
        test_user = users_response.data[0]
        user_id = test_user['id']
        user_name = test_user['full_name']
        
        print(f"\n👤 Test CEO User: {user_name} (ID: {user_id})")
        
        # Try different column names
        test_columns = [
            'ceo_user_id',
            'ceo_id', 
            'owner_id',
            'created_by',
            'user_id'
        ]
        
        for col_name in test_columns:
            try:
                print(f"\n🔍 Testing: companies.{col_name} = '{user_id}'")
                response = supabase.table('companies').select('id, name').eq(col_name, user_id).execute()
                
                if response.data:
                    print(f"   ✅ FOUND! Column '{col_name}' works!")
                    print(f"   📊 Found {len(response.data)} companies:")
                    for company in response.data:
                        print(f"      - {company.get('name', 'Unknown')} (ID: {company['id']})")
                    return col_name
                else:
                    print(f"   ❌ No results with '{col_name}'")
                    
            except Exception as e:
                print(f"   ❌ Error with '{col_name}': {e}")
        
        print("\n⚠️ No working CEO column found!")
        return None
        
    except Exception as e:
        print(f"\n❌ Error getting test user: {e}")
        return None

def fix_ceo_column():
    """Add or rename CEO column if needed"""
    print("\n" + "="*80)
    print("🔧 ATTEMPTING TO FIX CEO COLUMN")
    print("="*80)
    
    try:
        # Check if we need to add the column
        response = supabase.table('companies').select('*').limit(1).execute()
        
        if response.data:
            columns = list(response.data[0].keys())
            
            if 'ceo_user_id' not in columns:
                print("\n⚠️ Column 'ceo_user_id' does not exist")
                
                # Check if there's another CEO column we can use
                ceo_cols = [c for c in columns if 'ceo' in c.lower() or 'owner' in c.lower()]
                
                if ceo_cols:
                    print(f"\n✅ Found alternative CEO column: {ceo_cols[0]}")
                    print(f"   📝 Recommendation: Use '{ceo_cols[0]}' instead of 'ceo_user_id'")
                    return ceo_cols[0]
                else:
                    print("\n❌ No CEO-related column found!")
                    print("   📝 Need to add 'ceo_user_id' column via SQL migration")
                    print("\n   SQL to run:")
                    print("   ALTER TABLE companies ADD COLUMN ceo_user_id UUID REFERENCES users(id);")
                    return None
            else:
                print("\n✅ Column 'ceo_user_id' exists!")
                return 'ceo_user_id'
                
    except Exception as e:
        print(f"\n❌ Error checking CEO column: {e}")
        return None

def create_sql_migration():
    """Create SQL migration file to add ceo_user_id if needed"""
    sql_content = """-- Add ceo_user_id column to companies table
-- This links companies to their CEO user

-- Add column if it doesn't exist
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS ceo_user_id UUID REFERENCES users(id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_companies_ceo_user_id ON companies(ceo_user_id);

-- Update existing companies to set ceo_user_id from manager_user_id or created_by
UPDATE companies 
SET ceo_user_id = COALESCE(manager_user_id, created_by)
WHERE ceo_user_id IS NULL;

-- Verify the update
SELECT 
    id,
    name,
    ceo_user_id,
    manager_user_id,
    created_by
FROM companies
LIMIT 5;
"""
    
    with open('add_ceo_user_id_to_companies.sql', 'w', encoding='utf-8') as f:
        f.write(sql_content)
    
    print("\n📄 Created SQL migration file: add_ceo_user_id_to_companies.sql")
    print("   Run this in Supabase SQL Editor to add the column")

def main():
    print("\n" + "="*80)
    print("🚀 CEO COLUMN DEBUG & FIX SCRIPT")
    print("="*80)
    
    # Step 1: Check table structure
    columns = check_companies_structure()
    
    # Step 2: Test different CEO column names
    working_column = get_current_user_company()
    
    # Step 3: Try to fix or provide solution
    recommended_column = fix_ceo_column()
    
    # Summary
    print("\n" + "="*80)
    print("📊 SUMMARY & RECOMMENDATIONS")
    print("="*80)
    
    if working_column:
        print(f"\n✅ SOLUTION FOUND!")
        print(f"   Use column: '{working_column}'")
        print(f"\n   Update your Flutter code:")
        print(f"   .eq('{working_column}', user.id)")
    elif recommended_column:
        print(f"\n✅ ALTERNATIVE COLUMN FOUND!")
        print(f"   Use column: '{recommended_column}'")
        print(f"\n   Update your Flutter code:")
        print(f"   .eq('{recommended_column}', user.id)")
    else:
        print(f"\n❌ NO CEO COLUMN FOUND!")
        print(f"   Need to add 'ceo_user_id' column to companies table")
        create_sql_migration()
        print(f"\n   Steps to fix:")
        print(f"   1. Run the SQL migration in Supabase SQL Editor")
        print(f"   2. Then use .eq('ceo_user_id', user.id) in your code")
    
    print("\n" + "="*80)
    print("✅ DEBUG COMPLETE")
    print("="*80 + "\n")

if __name__ == '__main__':
    main()
