#!/usr/bin/env python3
"""
Check company check-in location settings
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

def check_company_location():
    """Check company check-in location configuration"""
    
    print("🔍 Checking company check-in location settings...\n")
    
    # Get all companies with location data
    response = supabase.table('companies')\
        .select('id, name, check_in_latitude, check_in_longitude, check_in_radius')\
        .execute()
    
    if not response.data:
        print("❌ No companies found!")
        return
    
    for company in response.data:
        print(f"🏢 Company: {company['name']}")
        print(f"   ID: {company['id']}")
        
        lat = company.get('check_in_latitude')
        lng = company.get('check_in_longitude')
        radius = company.get('check_in_radius')
        
        if lat and lng:
            print(f"   ✅ LOCATION CONFIGURED:")
            print(f"      Latitude:  {lat}")
            print(f"      Longitude: {lng}")
            print(f"      Radius:    {radius}m")
            print(f"      Google Maps: https://www.google.com/maps?q={lat},{lng}")
        else:
            print(f"   ⚠️  NO LOCATION CONFIGURED")
            print(f"      Latitude:  {lat}")
            print(f"      Longitude: {lng}")
            print(f"      Radius:    {radius}m")
        
        print()

if __name__ == "__main__":
    check_company_location()
