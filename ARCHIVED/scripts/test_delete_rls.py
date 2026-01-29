#!/usr/bin/env python3
"""
Check RLS policies on companies table
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables
load_dotenv()

# Initialize Supabase client with ANON KEY (not service role)
url: str = os.environ.get("SUPABASE_URL")
anon_key: str = os.environ.get("SUPABASE_ANON_KEY")
supabase_anon: Client = create_client(url, anon_key)

# Also create service role client
service_key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase_service: Client = create_client(url, service_key)

def test_delete_with_anon_key():
    """Test delete with anon key (simulating app behavior)"""
    
    print("=" * 60)
    print("TEST 1: DELETE WITH ANON KEY (App behavior)")
    print("=" * 60)
    
    # First, re-create the company we deleted
    print("\n📝 Re-creating Nhà hàng Sabo...")
    try:
        create_response = supabase_service.table('companies').insert({
            'id': '93fe0057-2274-4ab5-851e-a38241c18b8d',
            'name': 'Nhà hàng Sabo',
            'business_type': 'RESTAURANT',
            'address': '123 Nguyễn Huệ, Quận 1, TP.HCM',
            'phone': '0901234567',
            'is_active': True
        }).execute()
        print(f"✅ Company re-created")
    except Exception as e:
        print(f"⚠️  Company may already exist: {e}")
    
    # Now try to delete with anon key
    company_id = "93fe0057-2274-4ab5-851e-a38241c18b8d"
    print(f"\n🗑️  Trying to delete with ANON KEY (no auth)...")
    
    try:
        response = supabase_anon.table('companies').delete().eq('id', company_id).execute()
        print(f"✅ SUCCESS with anon key!")
        print(f"Response: {response}")
    except Exception as e:
        print(f"❌ FAILED with anon key!")
        print(f"Error: {str(e)}")
    
    print("\n" + "=" * 60)
    print("TEST 2: CHECK RLS POLICIES")
    print("=" * 60)
    
    # Query RLS policies
    try:
        # This is a PostgreSQL system query - only works with service role
        result = supabase_service.rpc('exec_sql', {
            'query': """
                SELECT 
                    schemaname, tablename, policyname, 
                    permissive, roles, cmd, qual, with_check
                FROM pg_policies 
                WHERE tablename = 'companies'
            """
        }).execute()
        print("\n📋 RLS Policies on companies table:")
        print(result.data)
    except Exception as e:
        print(f"\n⚠️  Cannot query RLS policies: {e}")
        
def check_ceo_permissions():
    """Check what CEO can do with companies"""
    
    print("\n" + "=" * 60)
    print("TEST 3: CHECK CEO USER PERMISSIONS")
    print("=" * 60)
    
    # Get CEO user
    ceo_response = supabase_service.table('users').select('*').eq('email', 'longsangsabo1@gmail.com').execute()
    
    if ceo_response.data:
        ceo = ceo_response.data[0]
        print(f"\n👤 CEO: {ceo.get('full_name')}")
        print(f"   ID: {ceo.get('id')}")
        print(f"   Company ID: {ceo.get('company_id')}")
        print(f"   Role: {ceo.get('role')}")
        
        # Try to delete Nhà hàng Sabo (not CEO's company)
        print(f"\n🗑️  Trying to delete company that CEO doesn't own...")
        company_id = "93fe0057-2274-4ab5-851e-a38241c18b8d"
        
        try:
            # This simulates what happens in the app when CEO is logged in
            response = supabase_service.table('companies').delete().eq('id', company_id).execute()
            print(f"✅ Can delete other companies!")
        except Exception as e:
            print(f"❌ Cannot delete: {str(e)}")

if __name__ == "__main__":
    test_delete_with_anon_key()
    check_ceo_permissions()
