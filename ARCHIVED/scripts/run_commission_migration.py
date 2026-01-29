"""
Commission System Migration Script
Sử dụng psycopg2 để kết nối trực tiếp với PostgreSQL
"""

import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection string
DB_CONNECTION_STRING = os.getenv('SUPABASE_CONNECTION_STRING')

if not DB_CONNECTION_STRING:
    raise ValueError("Missing SUPABASE_CONNECTION_STRING in .env file")

def run_migration():
    """Run the commission system migration"""
    print("=" * 70)
    print("  🚀 COMMISSION SYSTEM MIGRATION")
    print("=" * 70)
    
    try:
        # Connect to database
        print("\n📡 Connecting to database...")
        conn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = conn.cursor()
        print("✅ Connected successfully!")
        
        # Read migration SQL file
        migration_file = 'database/migrations/008_commission_system_no_rls.sql'
        print(f"\n📄 Reading migration file: {migration_file}")
        
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f"✅ Migration file loaded ({len(sql_content)} characters)")
        
        # Execute SQL
        print("\n⚙️  Executing migration SQL...")
        cursor.execute(sql_content)
        conn.commit()
        print("✅ Migration executed successfully!")
        
        # Verify tables
        print("\n🔍 Verifying tables...")
        tables = ['bills', 'commission_rules', 'bill_commissions', 'commission_rule_history']
        
        for table in tables:
            cursor.execute(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = '{table}'
                );
            """)
            exists = cursor.fetchone()[0]
            status = "✅" if exists else "❌"
            print(f"  {status} {table}: {'OK' if exists else 'NOT FOUND'}")
        
        # Close connection
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("  ✨ MIGRATION COMPLETED SUCCESSFULLY!")
        print("=" * 70)
        
        return True
        
    except FileNotFoundError:
        print(f"❌ Migration file not found: {migration_file}")
        return False
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def create_sample_commission_rule():
    """Create a sample commission rule for testing"""
    print("\n" + "=" * 70)
    print("  📝 CREATING SAMPLE COMMISSION RULE")
    print("=" * 70)
    
    try:
        conn = psycopg2.connect(DB_CONNECTION_STRING)
        cursor = conn.cursor()
        
        # Get first company and first CEO user
        cursor.execute("SELECT id FROM companies LIMIT 1")
        company = cursor.fetchone()
        
        if not company:
            print("⚠️  No companies found. Please create a company first.")
            return False
        
        company_id = company[0]
        
        # Get first CEO user
        cursor.execute("SELECT user_id FROM user_roles WHERE role = 'ceo' LIMIT 1")
        ceo = cursor.fetchone()
        
        if not ceo:
            print("⚠️  No CEO users found. Please create a CEO user first.")
            return False
        
        ceo_id = ceo[0]
        print(f"✅ Found company: {company_id}")
        print(f"✅ Found CEO: {ceo_id}")
        
        # Check if rule already exists
        cursor.execute("""
            SELECT id FROM commission_rules 
            WHERE company_id = %s AND rule_name = 'Default Staff Commission'
        """, (company_id,))
        
        if cursor.fetchone():
            print("ℹ️  Sample rule already exists, skipping...")
            return True
        
        # Create default rule
        cursor.execute("""
            INSERT INTO commission_rules (
                company_id, rule_name, description, applies_to, 
                commission_percentage, min_bill_amount, is_active, 
                priority, created_by
            ) VALUES (
                %s, 'Default Staff Commission', 
                'Default 5%% commission for all staff members', 
                'all', 5.00, 0, true, 1, %s
            ) RETURNING id
        """, (company_id, ceo_id))
        
        rule_id = cursor.fetchone()[0]
        conn.commit()
        
        print(f"✅ Sample commission rule created: {rule_id}")
        print("   - Applies to: All staff")
        print("   - Commission: 5%")
        print("   - Min bill amount: 0")
        
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == '__main__':
    # Run migration
    success = run_migration()
    
    if success:
        # Create sample data
        create_sample_commission_rule()
        
        print("\n" + "=" * 70)
        print("  🎉 ALL DONE!")
        print("=" * 70)
        print("\n📚 Next steps:")
        print("  1. Check Supabase Dashboard to verify tables")
        print("  2. Implement Flutter UI for commission management")
        print("  3. Test the commission calculation flow")
        print("\n" + "=" * 70)
    else:
        print("\n" + "=" * 70)
        print("  ❌ MIGRATION FAILED")
        print("=" * 70)
        print("\nPlease check the error messages above and fix the issues.")
