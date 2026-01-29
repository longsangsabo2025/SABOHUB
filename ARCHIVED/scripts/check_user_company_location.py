#!/usr/bin/env python3
"""
Check user Võ Ngọc Diễm's company relationship
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

def check_user_company():
    """Check user's company and location settings"""
    
    print("🔍 Checking Võ Ngọc Diễm's company...\n")
    
    # Get user
    user_response = supabase.table('users')\
        .select('id, full_name, email, company_id')\
        .ilike('full_name', '%Võ Ngọc Diễm%')\
        .execute()
    
    if not user_response.data:
        print("❌ User not found!")
        return
    
    user = user_response.data[0]
    print(f"👤 User: {user['full_name']}")
    print(f"   Email: {user['email']}")
    print(f"   Company ID: {user['company_id']}")
    
    if not user['company_id']:
        print("\n⚠️  USER HAS NO COMPANY!")
        return
    
    # Get company
    company_response = supabase.table('companies')\
        .select('id, name, check_in_latitude, check_in_longitude, check_in_radius')\
        .eq('id', user['company_id'])\
        .execute()
    
    if not company_response.data:
        print("\n❌ Company not found!")
        return
    
    company = company_response.data[0]
    print(f"\n🏢 Company: {company['name']}")
    print(f"   ID: {company['id']}")
    
    lat = company.get('check_in_latitude')
    lng = company.get('check_in_longitude')
    radius = company.get('check_in_radius', 100)
    
    if lat and lng:
        print(f"\n✅ Company Location:")
        print(f"   Latitude:  {lat}")
        print(f"   Longitude: {lng}")
        print(f"   Radius:    {radius}m")
        print(f"\n📍 Google Maps: https://www.google.com/maps?q={lat},{lng}")
        print(f"\n💡 Để check-in được, Võ Ngọc Diễm phải ở trong bán kính {radius}m từ vị trí này!")
    else:
        print(f"\n⚠️  NO LOCATION CONFIGURED for this company!")
        print(f"   Latitude:  {lat}")
        print(f"   Longitude: {lng}")

if __name__ == "__main__":
    check_user_company()
