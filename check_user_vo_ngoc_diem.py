from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

# Tìm user Võ Ngọc Diễm
result = supabase.table('users').select('*').ilike('full_name', '%Võ Ngọc Diễm%').execute()

if result.data:
    user = result.data[0]
    print(f"\n=== Thông tin user Võ Ngọc Diễm ===")
    print(f"ID: {user.get('id')}")
    print(f"Email: {user.get('email')}")
    print(f"Full Name: {user.get('full_name')}")
    print(f"Role: {user.get('role')}")
    print(f"Company ID: {user.get('company_id')}")
    print(f"Status: {user.get('status')}")
else:
    print("Không tìm thấy user Võ Ngọc Diễm")
