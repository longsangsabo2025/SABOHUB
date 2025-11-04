import psycopg2
import time
from datetime import datetime

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

def check_users():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        
        cursor = conn.cursor()
        
        # Count users in auth.users
        cursor.execute("SELECT COUNT(*) FROM auth.users")
        auth_count = cursor.fetchone()[0]
        
        # Count users in public.users
        cursor.execute("SELECT COUNT(*) FROM public.users")
        public_count = cursor.fetchone()[0]
        
        # Get latest user from auth.users
        cursor.execute("""
            SELECT email, created_at 
            FROM auth.users 
            ORDER BY created_at DESC 
            LIMIT 1
        """)
        latest_auth = cursor.fetchone()
        
        # Get latest user from public.users
        cursor.execute("""
            SELECT email, full_name, role, created_at 
            FROM public.users 
            ORDER BY created_at DESC 
            LIMIT 1
        """)
        latest_public = cursor.fetchone()
        
        print(f"\n📊 {datetime.now().strftime('%H:%M:%S')} - User Count Status:")
        print(f"   auth.users: {auth_count}")
        print(f"   public.users: {public_count}")
        
        if latest_auth:
            print(f"   Latest auth user: {latest_auth[0]} at {latest_auth[1]}")
        
        if latest_public:
            print(f"   Latest public user: {latest_public[1]} ({latest_public[0]}) - {latest_public[2]} at {latest_public[3]}")
        
        cursor.close()
        conn.close()
        
        return auth_count, public_count
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 0, 0

if __name__ == "__main__":
    print("🔍 Monitoring user registration...")
    print("Press Ctrl+C to stop")
    
    prev_auth, prev_public = check_users()
    
    try:
        while True:
            time.sleep(5)  # Check every 5 seconds
            auth_count, public_count = check_users()
            
            if auth_count != prev_auth or public_count != prev_public:
                print("🎉 NEW USER DETECTED!")
                prev_auth, prev_public = auth_count, public_count
                
    except KeyboardInterrupt:
        print("\n👋 Monitoring stopped")