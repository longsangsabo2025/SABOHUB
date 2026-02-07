import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('.env.local')

SUPABASE_URL = os.getenv('VITE_SUPABASE_URL') or os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('VITE_SUPABASE_ANON_KEY')

print(f"Connecting to: {SUPABASE_URL}")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get customers with missing or invalid coordinates (columns: lat, lng)
result = supabase.table('customers').select('id, name, address, ward, district, city, lat, lng').or_('lat.is.null,lng.is.null,lat.eq.0,lng.eq.0').execute()

print(f'=== KHÁCH HÀNG CHƯA CÓ TỌA ĐỘ: {len(result.data)} ===\n')

for i, c in enumerate(result.data[:50], 1):
    addr_parts = [c.get('address', ''), c.get('ward', ''), c.get('district', ''), c.get('city', '')]
    addr = ', '.join([p for p in addr_parts if p])
    lat = c.get('lat')
    lng = c.get('lng')
    print(f"{i}. {c['name']}")
    print(f"   Địa chỉ: {addr}")
    print(f"   Tọa độ: lat={lat}, lng={lng}")
    print()

if len(result.data) > 50:
    print(f'... và {len(result.data) - 50} khách hàng khác')

# Summary by district
print('\n=== THỐNG KÊ THEO QUẬN/HUYỆN ===')
districts = {}
for c in result.data:
    d = c.get('district', 'Không rõ') or 'Không rõ'
    districts[d] = districts.get(d, 0) + 1

for d, count in sorted(districts.items(), key=lambda x: -x[1]):
    print(f"  {d}: {count} khách hàng")
