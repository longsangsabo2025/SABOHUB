"""
Kiểm tra xem CEO có thể đọc companies không
"""
import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_ANON_KEY')
)

def check_companies_access():
    """Check if we can read companies table"""
    print("\n" + "="*60)
    print("🔍 KIỂM TRA QUYỀN TRUY CẬP COMPANIES TABLE")
    print("="*60)
    
    try:
        # Get all companies
        response = supabase.table('companies').select('*').execute()
        
        print(f"\n✅ Đọc companies thành công!")
        print(f"📊 Số công ty tìm thấy: {len(response.data)}")
        
        if response.data:
            print("\n🏢 Danh sách công ty:")
            for company in response.data:
                print(f"\n  ID: {company['id']}")
                print(f"  Tên: {company['name']}")
                print(f"  Loại hình: {company.get('business_type', 'N/A')}")
                print(f"  Trạng thái: {'✅ Active' if company.get('is_active') else '❌ Inactive'}")
        else:
            print("\n⚠️  KHÔNG CÓ CÔNG TY NÀO TRONG DATABASE!")
            print("\n💡 Giải pháp: Bạn cần tạo ít nhất 1 công ty trước!")
            
    except Exception as e:
        print(f"\n❌ LỖI khi đọc companies: {e}")
        print("\n🔧 Có thể do:")
        print("   1. RLS policy chặn CEO đọc companies")
        print("   2. Kết nối database có vấn đề")
        print("   3. Bảng companies không tồn tại")

def check_select_policy():
    """Check RLS policies for companies table"""
    print("\n" + "="*60)
    print("🔒 KIỂM TRA RLS POLICIES CHO COMPANIES")
    print("="*60)
    
    try:
        # Query RLS policies
        query = """
        SELECT 
            schemaname,
            tablename,
            policyname,
            permissive,
            roles,
            cmd,
            qual,
            with_check
        FROM pg_policies 
        WHERE tablename = 'companies'
        ORDER BY policyname;
        """
        
        response = supabase.rpc('exec_sql', {'query': query}).execute()
        
        if response.data:
            print(f"\n📋 Tìm thấy {len(response.data)} policies:")
            for policy in response.data:
                print(f"\n  Policy: {policy['policyname']}")
                print(f"  Command: {policy['cmd']}")
                print(f"  Roles: {policy['roles']}")
                print(f"  Condition: {policy['qual']}")
        else:
            print("\n⚠️  Không tìm thấy RLS policies!")
            
    except Exception as e:
        print(f"\n⚠️  Không thể kiểm tra policies (cần quyền admin): {e}")

if __name__ == '__main__':
    check_companies_access()
    check_select_policy()
    
    print("\n" + "="*60)
    print("✅ HOÀN THÀNH KIỂM TRA")
    print("="*60)
