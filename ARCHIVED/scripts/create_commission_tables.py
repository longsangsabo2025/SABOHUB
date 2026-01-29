"""
Commission System Migration Script
Tạo database schema cho hệ thống quản lý hoa hồng từ bill
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase credentials
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    raise ValueError("Missing Supabase credentials in .env file")

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def run_migration():
    """Run the commission system migration"""
    print("🚀 Starting Commission System Migration...")
    
    # Read migration SQL file
    migration_file = 'database/migrations/008_commission_system.sql'
    
    try:
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f"📄 Read migration file: {migration_file}")
        
        # Execute SQL through Supabase
        # Note: Supabase Python client doesn't support direct SQL execution
        # We need to use the REST API or psycopg2
        print("⚠️  Please run this SQL manually in Supabase SQL Editor:")
        print("   1. Go to Supabase Dashboard")
        print("   2. Navigate to SQL Editor")
        print("   3. Copy and paste the SQL from: database/migrations/008_commission_system.sql")
        print("   4. Click 'Run'")
        print("\n✨ Or use psycopg2 to run it programmatically")
        
        return True
        
    except FileNotFoundError:
        print(f"❌ Migration file not found: {migration_file}")
        return False
    except Exception as e:
        print(f"❌ Error running migration: {str(e)}")
        return False

def create_sample_commission_rule():
    """Create a sample commission rule for testing"""
    print("\n📝 Creating sample commission rule...")
    
    try:
        # Get first company with CEO
        companies = supabase.table('companies').select('id, ceo_id').limit(1).execute()
        
        if not companies.data:
            print("⚠️  No companies found. Please create a company first.")
            return False
        
        company = companies.data[0]
        
        # Check if commission_rules table exists
        try:
            existing_rules = supabase.table('commission_rules').select('id').limit(1).execute()
            print(f"✅ commission_rules table exists")
        except Exception as e:
            print(f"❌ commission_rules table not found. Please run migration first.")
            return False
        
        # Create default rule
        rule_data = {
            'company_id': company['id'],
            'rule_name': 'Default Staff Commission',
            'description': 'Default 5% commission for all staff members',
            'applies_to': 'all',
            'commission_percentage': 5.00,
            'min_bill_amount': 0,
            'is_active': True,
            'priority': 1,
            'created_by': company['ceo_id']
        }
        
        result = supabase.table('commission_rules').insert(rule_data).execute()
        print(f"✅ Sample commission rule created: {result.data[0]['id']}")
        return True
        
    except Exception as e:
        print(f"❌ Error creating sample rule: {str(e)}")
        return False

def verify_tables():
    """Verify that all tables were created successfully"""
    print("\n🔍 Verifying tables...")
    
    tables = [
        'bills',
        'commission_rules', 
        'bill_commissions',
        'commission_rule_history'
    ]
    
    all_exist = True
    for table in tables:
        try:
            result = supabase.table(table).select('id').limit(1).execute()
            print(f"  ✅ {table}: OK")
        except Exception as e:
            print(f"  ❌ {table}: NOT FOUND")
            all_exist = False
    
    return all_exist

if __name__ == '__main__':
    print("=" * 60)
    print("  COMMISSION SYSTEM MIGRATION")
    print("=" * 60)
    
    # Run migration instructions
    run_migration()
    
    print("\n" + "=" * 60)
    print("After running the SQL in Supabase Dashboard, run this script again")
    print("to verify tables and create sample data:")
    print("  python create_commission_tables.py --verify")
    print("=" * 60)
    
    # Check if user wants to verify
    import sys
    if '--verify' in sys.argv:
        if verify_tables():
            print("\n✅ All tables created successfully!")
            create_sample_commission_rule()
        else:
            print("\n❌ Some tables are missing. Please run the migration first.")
