#!/usr/bin/env python3
"""
Update company check-in radius for testing
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Initialize Supabase client
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

def update_radius():
    """Update check-in radius to allow remote check-in"""
    
    print("🔧 Updating SABO Billiards check-in radius...\n")
    
    # Update radius to 70000m (70km) for testing
    response = supabase.table('companies')\
        .update({'check_in_radius': 70000.0})\
        .eq('name', 'SABO Billiards')\
        .execute()
    
    if response.data:
        print("✅ Radius updated successfully!")
        print("   New radius: 70,000m (70km)")
        print("\n💡 Bây giờ Võ Ngọc Diễm có thể check-in từ bất kỳ đâu trong bán kính 70km!")
        print("\n⚠️  Chú ý: Đây chỉ để TEST. Sau khi test xong, nên đổi lại về 100m hoặc 500m.")
    else:
        print("❌ Failed to update!")

if __name__ == "__main__":
    update_radius()
