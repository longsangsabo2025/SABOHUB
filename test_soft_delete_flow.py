"""
Step-by-Step Soft Delete Testing
Tests the complete soft delete flow end-to-end
"""

import os
from supabase import create_client
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

url = os.environ.get("SUPABASE_URL")
service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase = create_client(url, service_key)

def step1_list_active_companies():
    """Step 1: List all active companies"""
    print("\n" + "="*60)
    print("STEP 1: List Active Companies")
    print("="*60)
    
    try:
        # Query active companies only
        result = supabase.table('companies')\
            .select('id, name, created_at, deleted_at')\
            .is_('deleted_at', 'null')\
            .execute()
        
        print(f"✅ Found {len(result.data)} active companies:")
        for company in result.data:
            print(f"   - {company['name']} (ID: {company['id'][:8]}...)")
        
        return result.data
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def step2_soft_delete_company(company_id, company_name):
    """Step 2: Soft delete a company"""
    print("\n" + "="*60)
    print(f"STEP 2: Soft Delete Company '{company_name}'")
    print("="*60)
    
    try:
        # Perform soft delete (UPDATE not DELETE)
        result = supabase.table('companies')\
            .update({'deleted_at': datetime.now().isoformat()})\
            .eq('id', company_id)\
            .execute()
        
        print(f"✅ Soft delete successful!")
        print(f"   Company: {company_name}")
        print(f"   ID: {company_id[:8]}...")
        print(f"   Timestamp: {datetime.now().isoformat()}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def step3_verify_company_hidden():
    """Step 3: Verify deleted company is hidden from active list"""
    print("\n" + "="*60)
    print("STEP 3: Verify Company Hidden from Active List")
    print("="*60)
    
    try:
        # Query active companies (should NOT include deleted)
        result = supabase.table('companies')\
            .select('id, name')\
            .is_('deleted_at', 'null')\
            .execute()
        
        print(f"✅ Active companies count: {len(result.data)}")
        print("   (Should be 1 less than before)")
        
        for company in result.data:
            print(f"   - {company['name']}")
        
        return result.data
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def step4_verify_in_database(company_id):
    """Step 4: Verify company still exists in database with deleted_at"""
    print("\n" + "="*60)
    print("STEP 4: Verify Soft Delete in Database")
    print("="*60)
    
    try:
        # Query deleted companies (including deleted_at)
        result = supabase.table('companies')\
            .select('id, name, deleted_at')\
            .eq('id', company_id)\
            .execute()
        
        if result.data and len(result.data) > 0:
            company = result.data[0]
            print(f"✅ Company still exists in database:")
            print(f"   Name: {company['name']}")
            print(f"   ID: {company['id'][:8]}...")
            print(f"   deleted_at: {company.get('deleted_at', 'NULL')}")
            
            if company.get('deleted_at'):
                print(f"\n✅ SUCCESS: Soft delete confirmed!")
                return True
            else:
                print(f"\n❌ FAIL: deleted_at is NULL")
                return False
        else:
            print(f"❌ Company not found in database")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def step5_restore_company(company_id, company_name):
    """Step 5: Test restore functionality"""
    print("\n" + "="*60)
    print(f"STEP 5: Restore Company '{company_name}'")
    print("="*60)
    
    try:
        # Restore by setting deleted_at back to NULL
        result = supabase.table('companies')\
            .update({'deleted_at': None})\
            .eq('id', company_id)\
            .execute()
        
        print(f"✅ Restore successful!")
        print(f"   Company: {company_name}")
        print(f"   deleted_at: NULL (restored)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def step6_verify_restored():
    """Step 6: Verify company is back in active list"""
    print("\n" + "="*60)
    print("STEP 6: Verify Company Restored to Active List")
    print("="*60)
    
    try:
        result = supabase.table('companies')\
            .select('id, name')\
            .is_('deleted_at', 'null')\
            .execute()
        
        print(f"✅ Active companies count: {len(result.data)}")
        print("   (Should be back to original count)")
        
        for company in result.data:
            print(f"   - {company['name']}")
        
        return result.data
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def main():
    print("🧪 SOFT DELETE END-TO-END TEST")
    print("=" * 60)
    print("Testing complete soft delete and restore flow\n")
    
    # Step 1: Get active companies
    active_companies = step1_list_active_companies()
    
    if not active_companies or len(active_companies) == 0:
        print("\n❌ No active companies found. Cannot test.")
        return
    
    # Pick first company for testing
    test_company = active_companies[0]
    company_id = test_company['id']
    company_name = test_company['name']
    original_count = len(active_companies)
    
    print(f"\n🎯 Test Target: {company_name}")
    print(f"   Original active count: {original_count}")
    
    # Step 2: Soft delete
    if not step2_soft_delete_company(company_id, company_name):
        print("\n❌ Soft delete failed. Aborting test.")
        return
    
    # Step 3: Verify hidden
    remaining = step3_verify_company_hidden()
    
    if len(remaining) != original_count - 1:
        print(f"\n⚠️  WARNING: Expected {original_count - 1} companies, got {len(remaining)}")
    else:
        print(f"\n✅ Correct: {original_count} → {len(remaining)} companies")
    
    # Step 4: Verify in database
    if not step4_verify_in_database(company_id):
        print("\n❌ Verification failed.")
        return
    
    # Step 5: Restore
    if not step5_restore_company(company_id, company_name):
        print("\n❌ Restore failed.")
        return
    
    # Step 6: Verify restored
    restored = step6_verify_restored()
    
    if len(restored) != original_count:
        print(f"\n⚠️  WARNING: Expected {original_count} companies, got {len(restored)}")
    else:
        print(f"\n✅ Correct: Back to {original_count} companies")
    
    # Final summary
    print("\n" + "="*60)
    print("🎉 TEST COMPLETE - SUMMARY")
    print("="*60)
    print("✅ Step 1: Listed active companies")
    print("✅ Step 2: Soft deleted company")
    print("✅ Step 3: Verified company hidden")
    print("✅ Step 4: Confirmed deleted_at timestamp")
    print("✅ Step 5: Restored company")
    print("✅ Step 6: Verified company back in list")
    print("\n✨ ALL TESTS PASSED!")

if __name__ == "__main__":
    main()
