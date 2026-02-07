import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv('.env.local')
supabase = create_client(os.getenv('VITE_SUPABASE_URL'), os.getenv('VITE_SUPABASE_ANON_KEY'))

# Check total_debt values to understand revenue scale
result = supabase.table('customers').select('id, name, total_debt').not_.is_('total_debt', 'null').order('total_debt', desc=True).limit(20).execute()
print('=== TOP 20 KHÁCH HÀNG THEO DOANH SỐ ===')
for c in result.data:
    debt = c.get('total_debt', 0) or 0
    print(f"{c['name']}: {debt:,.0f} đ")

# Count by range
result = supabase.table('customers').select('id, total_debt').execute()
ranges = {'0-1M': 0, '1M-5M': 0, '5M-20M': 0, '20M+': 0}
for c in result.data:
    debt = c.get('total_debt', 0) or 0
    if debt < 1000000:
        ranges['0-1M'] += 1
    elif debt < 5000000:
        ranges['1M-5M'] += 1
    elif debt < 20000000:
        ranges['5M-20M'] += 1
    else:
        ranges['20M+'] += 1

print('\n=== PHÂN BỐ DOANH SỐ ===')
for k, v in ranges.items():
    print(f"  {k}: {v} khách")
