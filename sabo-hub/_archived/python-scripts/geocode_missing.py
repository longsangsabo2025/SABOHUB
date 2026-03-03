"""
Geocode 26 KH co dia chi nhung chua co toa do
Su dung Nominatim (free, no API key)
"""
import psycopg2
import requests
import time

conn = psycopg2.connect(
    host="aws-1-ap-southeast-2.pooler.supabase.com",
    port=6543,
    dbname="postgres",
    user="postgres.dqddxowyikefqcdiioyh",
    password="Acookingoil123"
)
cur = conn.cursor()
CID = '9f8921df-3760-44b5-9a7f-20f8484b0300'

def geocode_nominatim(address):
    """Geocode using Nominatim (free, rate limited 1 req/sec)"""
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        'q': address,
        'format': 'json',
        'limit': 1,
        'countrycodes': 'vn'
    }
    headers = {'User-Agent': 'SABOHUB-Geocoder/2.0'}
    try:
        resp = requests.get(url, params=params, headers=headers, timeout=10)
        data = resp.json()
        if data:
            return float(data[0]['lat']), float(data[0]['lon'])
    except Exception as e:
        print(f"    ERR: {e}")
    return None, None

def build_address(row):
    """Build geocodable address from structured fields"""
    street_number, street, ward, district, city = row[2], row[3], row[4], row[5], row[6]
    
    parts = []
    if street_number and street_number.strip():
        parts.append(street_number.strip())
    if street and street.strip():
        parts.append(street.strip())
    
    if ward and ward.strip():
        w = ward.strip()
        # Add Phường prefix for numbered wards
        if w.isdigit():
            w = f"Phường {w}"
        elif not w.startswith('Phường') and not w.startswith('Xã'):
            w = f"Phường {w}"
        parts.append(w)
    
    if district and district.strip():
        d = district.strip()
        if d.isdigit():
            d = f"Quận {d}"
        elif not d.startswith('Quận') and not d.startswith('Huyện'):
            d = f"Quận {d}"
        parts.append(d)
    
    if city and city.strip():
        c = city.strip()
        if not c.startswith('Thành phố') and not c.startswith('Tỉnh'):
            c = f"Thành phố {c}"
        parts.append(c)
    else:
        parts.append("Thành phố Hồ Chí Minh")
    
    parts.append("Vietnam")
    return ', '.join(parts)

# Get customers with address but no coordinates
cur.execute('''
    SELECT id, name, street_number, street, ward, district, city
    FROM customers 
    WHERE company_id = %s 
    AND (ward IS NOT NULL AND ward != '' OR district IS NOT NULL AND district != '')
    AND (lat IS NULL OR lng IS NULL OR lat = 0 OR lng = 0)
''', (CID,))

customers = cur.fetchall()
total = len(customers)
print(f"Can geocode: {total} KH\n")

success = 0
failed = 0

for i, c in enumerate(customers, 1):
    cid, name = c[0], c[1]
    full_addr = build_address(c)
    
    print(f"[{i}/{total}] {name}")
    print(f"  Dia chi: {full_addr}")
    
    lat, lng = geocode_nominatim(full_addr)
    
    # If full address fails, try with just district + city
    if not lat:
        district = c[5] or ''
        city = c[6] or 'Hồ Chí Minh'
        if district:
            d = district.strip()
            if d.isdigit():
                d = f"Quận {d}"
            simple = f"{d}, Thành phố {city}, Vietnam"
            print(f"  Retry: {simple}")
            time.sleep(1.1)
            lat, lng = geocode_nominatim(simple)
    
    if lat and lng:
        # Validate in Vietnam
        if 8 < lat < 24 and 102 < lng < 110:
            cur.execute("UPDATE customers SET lat = %s, lng = %s WHERE id = %s", (lat, lng, cid))
            print(f"  OK: {lat:.6f}, {lng:.6f}")
            success += 1
        else:
            print(f"  SKIP: toa do ngoai VN ({lat}, {lng})")
            failed += 1
    else:
        print(f"  FAIL: khong tim duoc")
        failed += 1
    
    time.sleep(1.1)  # Rate limit

conn.commit()
print(f"\nKET QUA: {success} thanh cong, {failed} that bai / {total} tong")
conn.close()
