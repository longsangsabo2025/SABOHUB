#!/usr/bin/env python3
"""
Script to delete all users from Supabase Auth
WARNING: This will permanently delete all users!
"""

import os
from supabase import create_client, Client

# Load environment variables
SUPABASE_URL = "https://dqddxowyikefqcdiioyh.supabase.co"
SUPABASE_SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.kPmlYlVd7wi_Luzp3MHjXmR8gUqrqDHy9PSzwFDq3XI"

def delete_all_users():
    """Delete all users from Supabase Auth"""
    try:
        # Create Supabase client with service role key
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
        
        print("🔍 Fetching all users...")
        # Get all users
        response = supabase.auth.admin.list_users()
        users = response if isinstance(response, list) else getattr(response, 'users', [])
        
        total_users = len(users)
        print(f"📊 Found {total_users} users")
        
        if total_users == 0:
            print("✅ No users to delete!")
            return
        
        print("\n👥 Users to be deleted:")
        for user in users:
            email = getattr(user, 'email', 'No email')
            user_id = getattr(user, 'id', 'No ID')
            print(f"  - {email} (ID: {user_id})")
        
        # Confirm deletion
        print(f"\n⚠️  WARNING: This will permanently delete {total_users} users!")
        confirm = input("Type 'DELETE' to confirm: ")
        
        if confirm != "DELETE":
            print("❌ Operation cancelled")
            return
        
        print(f"\n🗑️  Deleting {total_users} users...")
        deleted_count = 0
        failed_count = 0
        
        for user in users:
            try:
                user_id = getattr(user, 'id', None)
                email = getattr(user, 'email', 'No email')
                
                if user_id:
                    supabase.auth.admin.delete_user(user_id)
                    deleted_count += 1
                    print(f"  ✅ Deleted: {email}")
                else:
                    print(f"  ⚠️  Skipped: {email} (No ID)")
                    failed_count += 1
                    
            except Exception as e:
                failed_count += 1
                print(f"  ❌ Failed to delete {email}: {str(e)}")
        
        print(f"\n📊 Summary:")
        print(f"  ✅ Successfully deleted: {deleted_count}")
        print(f"  ❌ Failed: {failed_count}")
        print(f"  📝 Total processed: {total_users}")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    delete_all_users()
