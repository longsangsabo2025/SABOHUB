"""
Make company_id nullable in tasks table
"""
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

def make_company_id_nullable():
    """Change company_id column to allow NULL values"""
    
    db_url = os.getenv('SUPABASE_CONNECTION_STRING')
    
    if not db_url:
        print("❌ Error: SUPABASE_CONNECTION_STRING not found")
        return False
    
    try:
        print("=" * 70)
        print("🔧 MAKING company_id NULLABLE IN TASKS TABLE")
        print("=" * 70)
        
        conn = psycopg2.connect(db_url)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Check current constraint
        print("\n🔍 Checking current company_id constraint...")
        cur.execute("""
            SELECT column_name, is_nullable, data_type
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'company_id'
        """)
        
        result = cur.fetchone()
        if result:
            col_name, nullable, data_type = result
            print(f"   Column: {col_name}")
            print(f"   Type: {data_type}")
            print(f"   Nullable: {nullable}")
            
            if nullable == 'YES':
                print("\n✅ company_id is already nullable!")
                return True
        
        # Make company_id nullable
        print("\n🔄 Changing company_id to allow NULL values...")
        cur.execute("""
            ALTER TABLE tasks 
            ALTER COLUMN company_id DROP NOT NULL;
        """)
        
        print("   ✅ Changed company_id to nullable")
        
        # Verify the change
        print("\n🔍 Verifying change...")
        cur.execute("""
            SELECT column_name, is_nullable, data_type, column_default
            FROM information_schema.columns 
            WHERE table_name = 'tasks' 
            AND column_name = 'company_id'
        """)
        
        result = cur.fetchone()
        if result:
            col_name, nullable, data_type, default = result
            print(f"   Column: {col_name}")
            print(f"   Type: {data_type}")
            print(f"   Nullable: {nullable}")
            print(f"   Default: {default if default else 'NULL'}")
            
            if nullable == 'YES':
                print("\n✅ SUCCESS: company_id now allows NULL!")
            else:
                print("\n⚠️  WARNING: company_id still NOT NULL")
        
        cur.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ MIGRATION COMPLETED!")
        print("=" * 70)
        
        return True
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        print(f"   Error code: {e.pgcode}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Making company_id nullable...\n")
    success = make_company_id_nullable()
    
    if success:
        print("\n✅ You can now create tasks without company_id!")
    else:
        print("\n❌ Failed to make company_id nullable")
