"""
Kiểm tra companies với SERVICE_ROLE_KEY (bypass RLS)
"""
import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client với SERVICE_ROLE_KEY để bypass RLS
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')  # ✅ Dùng SERVICE_ROLE_KEY thay vì ANON_KEY
)

def check_companies():
    """Check companies table with service role"""
    print("\n" + "="*60)
    print("🔍 KIỂM TRA COMPANIES VỚI SERVICE_ROLE_KEY")
    print("="*60)
    
    try:
        # Get all companies
        response = supabase.table('companies').select('*').execute()
        
        print(f"\n✅ Đọc companies thành công!")
        print(f"📊 Tổng số công ty: {len(response.data)}")
        
        if response.data:
            print("\n🏢 DANH SÁCH CÔNG TY:")
            for idx, company in enumerate(response.data, 1):
                print(f"\n{idx}. {company['name']}")
                print(f"   ID: {company['id']}")
                print(f"   Loại hình: {company.get('business_type', 'N/A')}")
                print(f"   Địa chỉ: {company.get('address', 'N/A')}")
                print(f"   Trạng thái: {'✅ Hoạt động' if company.get('is_active') else '❌ Ngừng'}")
        else:
            print("\n❌ DATABASE KHÔNG CÓ CÔNG TY NÀO!")
            print("\n💡 Cần tạo công ty đầu tiên trong app!")
            
    except Exception as e:
        print(f"\n❌ LỖI: {e}")

def test_getcompanies_query():
    """Test query giống như trong ManagementTaskService.getCompanies()"""
    print("\n" + "="*60)
    print("🧪 TEST QUERY GIỐNG APP (service.getCompanies)")
    print("="*60)
    
    try:
        # Query giống y hệt trong management_task_service.dart
        response = supabase.table('companies').select('id, name').order('name', ascending=True).execute()
        
        print(f"\n✅ Query thành công!")
        print(f"📊 Số công ty trả về: {len(response.data)}")
        
        if response.data:
            print("\n📋 Data trả về (giống app nhận được):")
            for company in response.data:
                print(f"  - id: {company['id']}")
                print(f"    name: {company['name']}")
        else:
            print("\n❌ Query không trả về công ty nào!")
            print("   → Đây là lý do dropdown rỗng!")
            
    except Exception as e:
        print(f"\n❌ LỖI khi query: {e}")

if __name__ == '__main__':
    check_companies()
    test_getcompanies_query()
    
    print("\n" + "="*60)
    print("✅ HOÀN THÀNH")
    print("="*60)
