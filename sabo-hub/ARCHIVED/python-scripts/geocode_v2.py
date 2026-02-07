import os
import time
import requests
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('.env.local')

SUPABASE_URL = os.getenv('VITE_SUPABASE_URL')
SUPABASE_KEY = os.getenv('VITE_SUPABASE_ANON_KEY')
# Google Maps API key - bạn cần thêm vào .env.local
GOOGLE_API_KEY = os.getenv('GOOGLE_MAPS_API_KEY', '')

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def clean_address(address, ward, district, city):
    """Làm sạch và chuẩn hóa địa chỉ"""
    parts = []
    
    if address:
        addr = address.strip()
        # Remove existing location info that will be added separately
        addr = addr.replace('Thành phố Hồ Chí Minh', '')
        addr = addr.replace('TP.HCM', '').replace('TPHCM', '')
        addr = addr.replace('Hồ Chí Minh', '')
        # Clean up common patterns
        addr = addr.replace(',Phường', ', Phường')
        addr = addr.replace('Quận Quận', 'Quận')
        if addr.strip():
            parts.append(addr.strip())
    
    if ward:
        w = ward.strip()
        # Skip if already has prefix
        if not any(w.lower().startswith(p) for p in ['phường', 'p.', 'p ', 'xã', 'thị trấn']):
            if w.isdigit() or (len(w) <= 2 and w[0].isdigit()):
                w = f"Phường {w}"
        parts.append(w)
    
    if district:
        d = district.strip()
        # Normalize district names
        d = d.replace('Q.', 'Quận ')
        if d.isdigit():
            d = f"Quận {d}"
        elif d == 'Q12':
            d = 'Quận 12'
        parts.append(d)
    
    if city and city.strip():
        parts.append(city.strip())
    else:
        parts.append('TP Hồ Chí Minh')
    
    return ', '.join([p for p in parts if p and p.strip()])

def geocode_google(address):
    """Geocode using Google Maps API"""
    if not GOOGLE_API_KEY:
        return None, None
    
    url = "https://maps.googleapis.com/maps/api/geocode/json"
    params = {
        'address': address,
        'key': GOOGLE_API_KEY,
        'region': 'vn',
        'language': 'vi'
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        data = response.json()
        if data['status'] == 'OK' and data['results']:
            loc = data['results'][0]['geometry']['location']
            return loc['lat'], loc['lng']
        elif data['status'] == 'ZERO_RESULTS':
            return None, None
        else:
            print(f"  ⚠️ Google API: {data['status']}")
    except Exception as e:
        print(f"  ⚠️ Error: {e}")
    
    return None, None

def geocode_goong(address):
    """Geocode using Goong.io API (Vietnamese map service)"""
    GOONG_API_KEY = os.getenv('GOONG_API_KEY', '')
    if not GOONG_API_KEY:
        return None, None
    
    url = "https://rsapi.goong.io/geocode"
    params = {
        'address': address,
        'api_key': GOONG_API_KEY
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        data = response.json()
        if data.get('status') == 'OK' and data.get('results'):
            loc = data['results'][0]['geometry']['location']
            return loc['lat'], loc['lng']
    except Exception as e:
        print(f"  ⚠️ Goong Error: {e}")
    
    return None, None

def geocode_nominatim_simple(address):
    """Simplified Nominatim geocoding with street name only"""
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        'q': address,
        'format': 'json',
        'limit': 1,
        'countrycodes': 'vn'
    }
    headers = {'User-Agent': 'SABOHUB-Geocoder/1.0'}
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        data = response.json()
        if data:
            return float(data[0]['lat']), float(data[0]['lon'])
    except:
        pass
    return None, None

def extract_street_name(address):
    """Extract main street name from address"""
    if not address:
        return None
    
    # Common street prefixes in Vietnamese addresses
    street_keywords = ['Đường', 'đường', 'Hẻm', 'hẻm', 'Lộ', 'lộ']
    
    # Try to find street name
    import re
    
    # Match patterns like "123 Nguyễn Văn Abc" or "123/45 Tên Đường"
    match = re.search(r'(\d+[/\d]*\s+)?([A-ZÀ-Ỹ][a-zà-ỹ]+(?:\s+[A-ZÀ-Ỹa-zà-ỹ]+)*)', address)
    if match:
        street = match.group(0).strip()
        if len(street) > 5:  # Minimum meaningful street name
            return street
    
    return None

def main():
    print("🔍 Đang lấy danh sách khách hàng còn thiếu tọa độ...")
    
    # Get customers still missing coordinates
    result = supabase.table('customers').select('id, name, address, ward, district, city').or_('lat.is.null,lng.is.null,lat.eq.0,lng.eq.0').execute()
    
    customers = result.data
    total = len(customers)
    print(f"📋 Còn {total} khách hàng cần geocode\n")
    
    if total == 0:
        print("✅ Tất cả khách hàng đã có tọa độ!")
        return
    
    # Check available APIs
    has_google = bool(GOOGLE_API_KEY)
    has_goong = bool(os.getenv('GOONG_API_KEY', ''))
    
    print(f"📡 APIs: Google={'✅' if has_google else '❌'}, Goong={'✅' if has_goong else '❌'}, Nominatim=✅")
    print()
    
    success = 0
    failed = 0
    
    for i, c in enumerate(customers, 1):
        name = c['name']
        full_address = clean_address(c.get('address'), c.get('ward'), c.get('district'), c.get('city'))
        
        print(f"[{i}/{total}] {name}")
        print(f"  📍 {full_address}")
        
        lat, lng = None, None
        
        # Try Google first (best for Vietnam)
        if has_google and not lat:
            lat, lng = geocode_google(full_address)
            if lat:
                print(f"  🔷 Google Maps")
        
        # Try Goong (Vietnamese local service)
        if has_goong and not lat:
            lat, lng = geocode_goong(full_address)
            if lat:
                print(f"  🔶 Goong.io")
        
        # Try Nominatim with simplified address
        if not lat:
            # Try with just district + city
            district = c.get('district', '')
            if district:
                simple_addr = f"{district}, TP Hồ Chí Minh, Vietnam"
                lat, lng = geocode_nominatim_simple(simple_addr)
                if lat:
                    print(f"  🔵 Nominatim (district center)")
            time.sleep(1.1)  # Rate limit
        
        if lat and lng:
            # Validate coordinates are in Vietnam
            if 8 < lat < 24 and 102 < lng < 110:
                supabase.table('customers').update({
                    'lat': lat,
                    'lng': lng
                }).eq('id', c['id']).execute()
                print(f"  ✅ {lat:.6f}, {lng:.6f}")
                success += 1
            else:
                print(f"  ❌ Tọa độ ngoài VN: {lat}, {lng}")
                failed += 1
        else:
            print(f"  ❌ Không tìm thấy")
            failed += 1
        
        time.sleep(0.3)  # Small delay between requests
    
    print(f"\n{'='*50}")
    print(f"📊 KẾT QUẢ:")
    print(f"  ✅ Thành công: {success}/{total}")
    print(f"  ❌ Thất bại: {failed}/{total}")
    
    if failed > 0:
        print(f"\n💡 Để geocode chính xác hơn, thêm API key vào .env.local:")
        print(f"   GOOGLE_MAPS_API_KEY=your_key_here")
        print(f"   GOONG_API_KEY=your_key_here")

if __name__ == '__main__':
    main()
