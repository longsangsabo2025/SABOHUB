#!/usr/bin/env python3
"""
Ensure current logged-in user has CEO role
"""
from supabase import create_client

SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

print("👤 Checking users and setting CEO role...")

try:
    # Get all users
    users = supabase.table('users').select('*').execute()
    
    if not users.data:
        print("⚠️  No users found in database!")
        print("   Please create a user account first by logging in to the app")
    else:
        print(f"✅ Found {len(users.data)} user(s):")
        
        for user in users.data:
            print(f"\n   📧 {user.get('email', 'N/A')}")
            print(f"   👤 {user.get('full_name', 'N/A')}")
            print(f"   🎭 Role: {user.get('role', 'N/A')}")
            print(f"   🆔 ID: {user['id']}")
            
            # Update to CEO if not already
            if user.get('role') != 'CEO':
                print(f"   🔄 Updating to CEO role...")
                result = supabase.table('users').update({
                    'role': 'CEO',
                    'company_id': None,  # CEO không thuộc company cụ thể
                    'branch_id': None    # CEO không thuộc branch cụ thể
                }).eq('id', user['id']).execute()
                print(f"   ✅ Updated to CEO!")
            else:
                print(f"   ✅ Already CEO")
                
except Exception as e:
    print(f"❌ Error: {e}")
