#!/usr/bin/env python3
"""
Check and update Manager's company information
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

def check_manager_data():
    """Check manager's data and company relationship"""
    
    print("🔍 Checking Manager data...")
    
    # Get manager user
    response = supabase.table('users')\
        .select('*')\
        .eq('email', 'ngocdiem1112@gmail.com')\
        .execute()
    
    if not response.data:
        print("❌ Manager not found!")
        return
    
    manager = response.data[0]
    print(f"\n👤 Manager Info:")
    print(f"   ID: {manager.get('id')}")
    print(f"   Name: {manager.get('name')}")
    print(f"   Email: {manager.get('email')}")
    print(f"   Role: {manager.get('role')}")
    print(f"   Company ID: {manager.get('company_id')}")
    
    company_id = manager.get('company_id')
    
    if not company_id:
        print("\n⚠️  Manager has no company_id!")
        
        # Try to find SABO Billiards company
        company_response = supabase.table('companies')\
            .select('*')\
            .ilike('name', '%SABO%')\
            .execute()
        
        if company_response.data:
            company = company_response.data[0]
            print(f"\n✅ Found company: {company['name']} (ID: {company['id']})")
            
            # Update manager with company_id
            update_response = supabase.table('users')\
                .update({'company_id': company['id']})\
                .eq('id', manager['id'])\
                .execute()
            
            print(f"✅ Updated manager with company_id: {company['id']}")
            return
    
    # Get company info
    if company_id:
        company_response = supabase.table('companies')\
            .select('*')\
            .eq('id', company_id)\
            .execute()
        
        if company_response.data:
            company = company_response.data[0]
            print(f"\n🏢 Company Info:")
            print(f"   ID: {company.get('id')}")
            print(f"   Name: {company.get('name')}")
            print(f"   Type: {company.get('business_type')}")
            
            # Count employees in this company
            employees = supabase.table('users')\
                .select('id,name,email,role', count='exact')\
                .eq('company_id', company_id)\
                .execute()
            
            print(f"\n👥 Employees in company: {employees.count}")
            for emp in employees.data:
                print(f"   - {emp.get('name')} ({emp.get('email')}) - {emp.get('role')}")
        else:
            print(f"\n⚠️  Company {company_id} not found in database!")

if __name__ == "__main__":
    check_manager_data()
