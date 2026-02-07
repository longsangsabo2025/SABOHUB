import os
import time
import requests
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('.env.local')

SUPABASE_URL = os.getenv('VITE_SUPABASE_URL')
SUPABASE_KEY = os.getenv('VITE_SUPABASE_ANON_KEY')
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

def normalize_address(address, ward, district, city):
    """Chuẩn hóa địa chỉ để geocode tốt hơn"""
    parts = []
    
    if address:
        # Clean up address
        addr = address.strip()
        # Remove duplicate city/district info that might be in address
        addr = addr.replace('Thành phố Hồ Chí Minh', '').replace('TP.HCM', '').replace('TPHCM', '')
        parts.append(addr)
    
    if ward:
        w = ward.strip()
        if not w.lower().startswith('phường') and not w.lower().startswith('p.'):
            w = f"Phường {w}"
        parts.append(w)
    
    if district:
        d = district.strip()
        # Handle numbered districts
        if d.isdigit():
            d = f"Quận {d}"
        elif not d.lower().startswith('quận') and not d.lower().startswith('q.'):
            if d not in ['Bình Tân', 'Gò Vấp', 'Tân Bình', 'Tân Phú', 'Phú Nhuận', 'Bình Thạnh', 'Thủ Đức']:
                d = f"Quận {d}"
        parts.append(d)
    
    # Default to Ho Chi Minh City if no city specified
    if city:
        parts.append(city)
    else:
        parts.append('Thành phố Hồ Chí Minh')
    
    parts.append('Vietnam')
    
    return ', '.join([p for p in parts if p])

def geocode_nominatim(address):
    """Geocode using Nominatim (free, rate limited)"""
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        'q': address,
        'format': 'json',
        'limit': 1,
        'countrycodes': 'vn'
    }
    headers = {
        'User-Agent': 'SABOHUB-Geocoder/1.0'
    }
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        data = response.json()
        if data:
            return float(data[0]['lat']), float(data[0]['lon'])
    except Exception as e:
        print(f"  ⚠️ Error: {e}")
    
    return None, None

def main():
    print("🔍 Đang lấy danh sách khách hàng chưa có tọa độ...")
    
    # Get customers with missing coordinates
    result = supabase.table('customers').select('id, name, address, ward, district, city').or_('lat.is.null,lng.is.null,lat.eq.0,lng.eq.0').execute()
    
    customers = result.data
    total = len(customers)
    print(f"📋 Tìm thấy {total} khách hàng cần geocode\n")
    
    success = 0
    failed = 0
    skipped = 0
    
    for i, c in enumerate(customers, 1):
        name = c['name']
        address = normalize_address(c.get('address'), c.get('ward'), c.get('district'), c.get('city'))
        
        print(f"[{i}/{total}] {name}")
        print(f"  📍 {address}")
        
        # Skip if no valid address
        if not address or address == 'Vietnam' or len(address) < 20:
            print(f"  ⏭️ Bỏ qua - địa chỉ không đủ thông tin")
            skipped += 1
            continue
        
        # Geocode
        lat, lng = geocode_nominatim(address)
        
        if lat and lng:
            # Validate coordinates are in Vietnam (roughly)
            if 8 < lat < 24 and 102 < lng < 110:
                # Update database
                supabase.table('customers').update({
                    'lat': lat,
                    'lng': lng
                }).eq('id', c['id']).execute()
                
                print(f"  ✅ Đã cập nhật: {lat:.6f}, {lng:.6f}")
                success += 1
            else:
                print(f"  ❌ Tọa độ không hợp lệ: {lat}, {lng}")
                failed += 1
        else:
            print(f"  ❌ Không tìm thấy tọa độ")
            failed += 1
        
        # Rate limit: 1 request per second for Nominatim
        time.sleep(1.1)
    
    print(f"\n{'='*50}")
    print(f"📊 KẾT QUẢ:")
    print(f"  ✅ Thành công: {success}/{total}")
    print(f"  ❌ Thất bại: {failed}/{total}")
    print(f"  ⏭️ Bỏ qua: {skipped}/{total}")

if __name__ == '__main__':
    main()
