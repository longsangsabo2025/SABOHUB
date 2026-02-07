#!/usr/bin/env python3
"""Full DMS Tables Verification"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

EXPECTED_TABLES = [
    # Distributor Portal (7 tables)
    'distributor_portals',
    'distributor_portal_users',
    'distributor_inventory',
    'distributor_price_lists',
    'distributor_price_list_items',
    'distributor_promotions',
    'distributor_loyalty_transactions',
    'distributor_loyalty_points',
    
    # Sell-In/Out (4 tables)
    'sell_in_transactions',
    'sell_out_transactions',
    'sell_through_analytics',
    
    # Sales Routes (4 tables)
    'sales_routes',
    'route_customers',
    'journey_plans',
    'sales_rep_locations',
    'sales_rep_locations_2026_01',
    'route_optimization_logs',
    
    # Store Visits (7 tables)  
    'visit_checklists',
    'visit_checklist_items',
    'store_visits',
    'store_visit_checklist_responses',
    'store_visit_photos',
    'store_inventory_checks',
    'customer_visits',
    
    # Accounting (5 tables)
    'chart_of_accounts',
    'journal_entries',
    'journal_entry_lines',
    'financial_statements',
    'financial_statement_lines'
]

print("=" * 80)
print("🔍 DMS TABLES VERIFICATION")
print("=" * 80)
print()

conn = psycopg2.connect(POOLER_URL)
cursor = conn.cursor()

# Check each expected table
existing = []
missing = []

for table in EXPECTED_TABLES:
    cursor.execute("""
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = %s
        );
    """, (table,))
    
    exists = cursor.fetchone()[0]
    if exists:
        existing.append(table)
        
        # Get row count
        cursor.execute(f"SELECT COUNT(*) FROM public.{table};")
        count = cursor.fetchone()[0]
        print(f"✅ {table:40s} ({count} rows)")
    else:
        missing.append(table)
        print(f"❌ {table:40s} (MISSING)")

print()
print("=" * 80)
print(f"SUMMARY: {len(existing)}/{len(EXPECTED_TABLES)} tables exist")
print("=" * 80)
print()

if len(existing) == len(EXPECTED_TABLES):
    print("🎉 SUCCESS! All DMS tables are ready!")
    print()
    print("✅ 100% DEPLOYMENT COMPLETE!")
    print()
    print("Next steps:")
    print("  1. Visit: https://hub.saboarena.com")
    print("  2. Test DMS functionality")
    print("  3. Seed standard COA if needed")
elif missing:
    print(f"⚠️  Missing {len(missing)} tables:")
    for table in missing:
        print(f"   - {table}")
else:
    print("✅ All expected tables exist!")

cursor.close()
conn.close()
