#!/usr/bin/env python3
"""
Test Supabase connection và signup functionality
"""

import requests
import json
import os
from datetime import datetime

# Load environment variables
def load_env():
    env_vars = {}
    try:
        with open('.env', 'r') as f:
            for line in f:
                if '=' in line and not line.startswith('#'):
                    key, value = line.strip().split('=', 1)
                    env_vars[key] = value
    except FileNotFoundError:
        print("❌ File .env không tìm thấy")
    return env_vars

def test_supabase_connection():
    """Test Supabase API connection"""
    print("🧪 Testing Supabase Connection...")
    
    env = load_env()
    supabase_url = env.get('SUPABASE_URL')
    supabase_anon_key = env.get('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_anon_key:
        print("❌ Missing Supabase credentials in .env")
        return False
    
    print(f"🔍 Supabase URL: {supabase_url}")
    print(f"🔑 Anon Key: {supabase_anon_key[:20]}...")
    
    # Test auth endpoint
    auth_url = f"{supabase_url}/auth/v1/health"
    headers = {
        'apikey': supabase_anon_key,
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(auth_url, headers=headers, timeout=10)
        print(f"📡 Auth Health Status: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ Supabase connection successful!")
            return True
        else:
            print(f"❌ Auth health check failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return False

def test_signup_api():
    """Test signup API directly"""
    print("\n🧪 Testing Signup API...")
    
    env = load_env()
    supabase_url = env.get('SUPABASE_URL')
    supabase_anon_key = env.get('SUPABASE_ANON_KEY')
    
    signup_url = f"{supabase_url}/auth/v1/signup"
    headers = {
        'apikey': supabase_anon_key,
        'Content-Type': 'application/json'
    }
    
    # Test user data - using simple email format
    timestamp = int(datetime.now().timestamp())
    test_user = {
        'email': f'test{timestamp}@gmail.com',
        'password': 'password123',
        'data': {
            'name': 'Test User API',
            'role': 'STAFF',
            'phone': '0123456789'
        }
    }
    
    print(f"📝 Test email: {test_user['email']}")
    
    try:
        response = requests.post(signup_url, 
                               headers=headers, 
                               json=test_user, 
                               timeout=30)
        
        print(f"📡 Signup Response Status: {response.status_code}")
        
        if response.status_code in [200, 201]:
            data = response.json()
            user_id = data.get('user', {}).get('id')
            print(f"✅ Signup successful! User ID: {user_id}")
            print(f"📧 Confirmation sent: {data.get('user', {}).get('email_confirmed_at') is None}")
            return True
        else:
            print(f"❌ Signup failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Signup API error: {e}")
        return False

def main():
    print("🚀 SABOHUB Signup Test Suite")
    print("=" * 50)
    
    # Test 1: Supabase Connection
    conn_success = test_supabase_connection()
    
    # Test 2: Signup API
    if conn_success:
        signup_success = test_signup_api()
    else:
        print("\n⚠️ Skipping signup test due to connection failure")
        signup_success = False
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Summary:")
    print(f"   🔗 Connection: {'✅ PASS' if conn_success else '❌ FAIL'}")
    print(f"   📝 Signup API: {'✅ PASS' if signup_success else '❌ FAIL'}")
    
    if conn_success and signup_success:
        print("\n🎉 All tests passed! Signup should work in the app.")
        print("\n💡 Next steps:")
        print("   1. Open SABOHUB app: http://localhost:64554/#/signup")
        print("   2. Fill signup form with test data")
        print("   3. Check browser console for debug logs")
    else:
        print("\n❌ Some tests failed. Check Supabase configuration.")

if __name__ == "__main__":
    main()