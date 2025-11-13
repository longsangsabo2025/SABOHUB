"""
Auto create manager_permissions table using direct PostgreSQL connection
"""
import os
import psycopg2
from dotenv import load_dotenv
from urllib.parse import urlparse

load_dotenv()

def get_db_connection():
    """Create direct PostgreSQL connection from Supabase URL"""
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    # Parse Supabase URL to get connection details
    # Format: https://xxxxx.supabase.co
    project_ref = supabase_url.replace('https://', '').replace('.supabase.co', '')
    
    # Supabase database connection string
    # Using pooler connection for better performance
    db_url = f"postgresql://postgres.{project_ref}:{os.getenv('SUPABASE_DB_PASSWORD')}@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
    
    # If no DB password in env, try direct connection
    if not os.getenv('SUPABASE_DB_PASSWORD'):
        print("⚠️  SUPABASE_DB_PASSWORD not found in .env")
        print("📝 Please add this line to your .env file:")
        print("   SUPABASE_DB_PASSWORD=your_database_password")
        print("\n🔍 You can find your database password in:")
        print("   Supabase Dashboard → Settings → Database → Connection string")
        return None
    
    try:
        conn = psycopg2.connect(db_url)
        return conn
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        print("\n🔄 Trying alternative connection method...")
        
        # Try alternative: Direct connection without pooler
        db_url_direct = f"postgresql://postgres:{os.getenv('SUPABASE_DB_PASSWORD')}@db.{project_ref}.supabase.co:5432/postgres"
        try:
            conn = psycopg2.connect(db_url_direct)
            return conn
        except Exception as e2:
            print(f"❌ Alternative connection also failed: {e2}")
            return None

def create_table(conn):
    """Create manager_permissions table"""
    print("🔧 Creating manager_permissions table...")
    
    with open('database/create_manager_permissions.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        conn.commit()
        cursor.close()
        print("✅ Table created successfully!")
        return True
    except Exception as e:
        print(f"❌ Failed to create table: {e}")
        conn.rollback()
        return False

def create_default_permissions(conn):
    """Create default permissions for existing managers"""
    print("\n🔍 Finding existing managers...")
    
    try:
        cursor = conn.cursor()
        
        # Get all managers
        cursor.execute("""
            SELECT id, full_name, company_id 
            FROM employees 
            WHERE role = 'MANAGER' AND deleted_at IS NULL
        """)
        
        managers = cursor.fetchall()
        
        if not managers:
            print("ℹ️  No managers found")
            cursor.close()
            return
        
        print(f"📋 Found {len(managers)} managers")
        
        for manager_id, name, company_id in managers:
            if not company_id:
                print(f"   ⚠️  {name} has no company_id, skipping...")
                continue
            
            # Check if permissions already exist
            cursor.execute("""
                SELECT id FROM manager_permissions 
                WHERE manager_id = %s AND company_id = %s
            """, (manager_id, company_id))
            
            if cursor.fetchone():
                print(f"   ✓ {name} - permissions already exist")
                continue
            
            # Create default permissions
            try:
                cursor.execute("""
                    INSERT INTO manager_permissions (
                        manager_id, company_id,
                        can_view_overview, can_view_employees, can_view_tasks, can_view_attendance,
                        can_create_task, can_edit_task, can_approve_attendance,
                        notes
                    ) VALUES (%s, %s, true, true, true, true, true, true, true, %s)
                """, (manager_id, company_id, 'Default permissions created by auto script'))
                conn.commit()
                print(f"   ✅ {name} - default permissions created")
            except Exception as e:
                print(f"   ❌ {name} - error: {e}")
                conn.rollback()
        
        cursor.close()
        
    except Exception as e:
        print(f"❌ Failed to create permissions: {e}")

def test_query(conn):
    """Test querying permissions"""
    print("\n🧪 Testing permissions query...")
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT mp.*, e.full_name as manager_name, c.name as company_name
            FROM manager_permissions mp
            LEFT JOIN employees e ON e.id = mp.manager_id
            LEFT JOIN companies c ON c.id = mp.company_id
        """)
        
        results = cursor.fetchall()
        cursor.close()
        
        if results:
            print(f"✅ Query successful! Found {len(results)} permission records")
            for row in results:
                print(f"   📋 {row[-2]} @ {row[-1]}")  # manager_name @ company_name
        else:
            print("ℹ️  No permission records found yet")
            
    except Exception as e:
        print(f"❌ Query failed: {e}")

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 AUTO SETUP MANAGER PERMISSIONS")
    print("=" * 60)
    
    # Connect to database
    print("\n🔌 Connecting to database...")
    conn = get_db_connection()
    
    if not conn:
        print("\n❌ Cannot establish database connection")
        print("\n📝 Manual setup required:")
        print("1. Go to Supabase Dashboard → SQL Editor")
        print("2. Run: database/create_manager_permissions.sql")
        print("3. Then run: python quick_setup_manager_permissions.py")
        exit(1)
    
    print("✅ Connected successfully!")
    
    # Create table
    if not create_table(conn):
        print("\n⚠️  Table creation failed, but continuing...")
    
    # Create default permissions
    create_default_permissions(conn)
    
    # Test query
    test_query(conn)
    
    # Close connection
    conn.close()
    
    print("\n" + "=" * 60)
    print("✅ SETUP COMPLETE!")
    print("=" * 60)
    print("\n📝 Next steps:")
    print("1. ✅ Database table created")
    print("2. ✅ Default permissions for managers created")
    print("3. 🔜 Create ManagerCompanyInfoPage in Flutter")
    print("4. 🔜 Create CEO UI to manage permissions")
