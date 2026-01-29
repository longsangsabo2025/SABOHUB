#!/usr/bin/env python3
"""
Test delete company and see actual error
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

def test_delete_company():
    """Try to delete Nhà hàng Sabo company"""
    
    company_id = "93fe0057-2274-4ab5-851e-a38241c18b8d"  # Nhà hàng Sabo
    
    print("=" * 60)
    print("TESTING COMPANY DELETION")
    print("=" * 60)
    
    print(f"\n🗑️  Trying to delete company: {company_id}")
    
    try:
        response = supabase.table('companies').delete().eq('id', company_id).execute()
        print(f"\n✅ SUCCESS! Company deleted.")
        print(f"Response: {response}")
    except Exception as e:
        print(f"\n❌ FAILED! Cannot delete company.")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        
        # Parse error details if available
        if hasattr(e, '__dict__'):
            print(f"\nError details:")
            for key, value in e.__dict__.items():
                print(f"  {key}: {value}")

if __name__ == "__main__":
    test_delete_company()
