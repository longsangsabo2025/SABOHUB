#!/usr/bin/env python3
"""
Test creating a company - verify RLS fix worked
"""
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTcxMzYsImV4cCI6MjA3NzM3MzEzNn0.okmsG2R248fxOHUEFFl5OBuCtjtCIlO9q9yVSyCV25Y"

supabase = create_client(SUPABASE_URL, ANON_KEY)

print("🧪 Testing Company Creation...")

# First check if user is authenticated and has CEO role
try:
    user = supabase.auth.get_user()
    print(f"✅ Current user: {user.user.email if user and user.user else 'Not logged in'}")
    
    if user and user.user:
        # Check user role
        user_data = supabase.table('users').select('role').eq('id', user.user.id).execute()
        if user_data.data:
            role = user_data.data[0].get('role')
            print(f"✅ User role: {role}")
            
            if role == 'CEO':
                # Try to create a company
                print("\n🏢 Creating test company...")
                result = supabase.table('companies').insert({
                    'name': 'Test Company ' + str(user.user.id[:8]),
                    'business_type': 'restaurant',
                    'address': '123 Test Street',
                    'phone': '0123456789',
                    'email': 'test@company.com',
                    'is_active': True
                }).execute()
                
                print("✅ Company created successfully!")
                print(f"   ID: {result.data[0]['id']}")
                print(f"   Name: {result.data[0]['name']}")
            else:
                print(f"⚠️  User is not CEO (role: {role}). Cannot create company.")
                print("   Need to update user role to CEO first.")
        else:
            print("⚠️  User not found in users table")
    else:
        print("⚠️  No user logged in")
        
except Exception as e:
    print(f"❌ Error: {e}")
    print("\n💡 Possible issues:")
    print("   1. User not logged in")
    print("   2. User doesn't have CEO role")
    print("   3. RLS policy still blocking")
