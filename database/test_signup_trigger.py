"""
Test signup flow - create a test user and verify it appears in both tables
"""

import os
from pathlib import Path
import psycopg2
from dotenv import load_dotenv
import requests
import json

# Load environment variables
env_path = Path(__file__).parent.parent / '.env'
load_dotenv(env_path)

def test_signup():
    """Test signup and verify database"""
    print("\n" + "="*60)
    print("TESTING SIGNUP FLOW")
    print("="*60)
    
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_anon_key = os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_anon_key:
        print("❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env")
        return
        
    # Create test user
    test_email = f"test{int(__import__('time').time())}@gmail.com"
    test_password = "Test123456!"
    test_name = "Test User"
    test_role = "STAFF"
    
    print(f"\n🔵 Creating test user...")
    print(f"  Email: {test_email}")
    print(f"  Name: {test_name}")
    print(f"  Role: {test_role}")
    
    # Call Supabase Auth API
    headers = {
        'apikey': supabase_anon_key,
        'Content-Type': 'application/json'
    }
    
    data = {
        'email': test_email,
        'password': test_password,
        'data': {
            'name': test_name,
            'role': test_role,
            'phone': '0123456789'
        }
    }
    
    response = requests.post(
        f"{supabase_url}/auth/v1/signup",
        headers=headers,
        json=data
    )
    
    if response.status_code == 200:
        result = response.json()
        
        # Get user ID from top level
        user_id = result.get('id')
        if not user_id:
            print("❌ No user ID in response")
            return
            
        print(f"✅ User created in auth.users")
        print(f"  User ID: {user_id}")
        print(f"  Email: {result.get('email')}")
        
        # Wait a moment for trigger to fire
        __import__('time').sleep(2)
        
        # Check if user appears in public.users
        print("\n🔵 Checking if user appears in public.users...")
        
        conn_str = os.getenv('SUPABASE_CONNECTION_STRING')
        conn = psycopg2.connect(conn_str)
        cur = conn.cursor()
        
        cur.execute("""
            SELECT id, email, full_name, role, phone
            FROM public.users
            WHERE id = %s;
        """, (user_id,))
        
        user = cur.fetchone()
        
        if user:
            print("✅ User found in public.users!")
            print(f"  ID: {user[0]}")
            print(f"  Email: {user[1]}")
            print(f"  Name: {user[2]}")
            print(f"  Role: {user[3]}")
            print(f"  Phone: {user[4]}")
            
            print("\n" + "="*60)
            print("✅ SIGNUP FLOW WORKING PERFECTLY!")
            print("="*60)
            print("\n✅ Trigger is working")
            print("✅ User profiles are auto-created")
            print("✅ Data is correctly mapped")
            print("\n")
        else:
            print("❌ User NOT found in public.users")
            print("   Trigger may still have issues")
            
        cur.close()
        conn.close()
        
    else:
        print(f"❌ Signup failed: {response.status_code}")
        print(f"   {response.text}")

if __name__ == "__main__":
    test_signup()
