#!/usr/bin/env python3
"""
Simple Revenue Data Seeder - Only adds daily revenue for existing data
"""

import psycopg2
from datetime import datetime, timedelta
import random

DB_CONFIG = {
    'host': 'aws-1-ap-southeast-2.pooler.supabase.com',
    'port': 6543,
    'database': 'postgres',
    'user': 'postgres.dqddxowyikefqcdiioyh',
    'password': 'Acookingoil123',
}

def seed_revenue():
    """Insert 30 days of revenue data for existing companies"""
    conn = None
    try:
        print("🔌 Connecting to database...")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        
        # Get existing companies
        cur.execute("SELECT id, name FROM companies WHERE is_active = true")
        companies = cur.fetchall()
        
        if not companies:
            print("❌ No companies found!")
            return
        
        print(f"✅ Found {len(companies)} companies")
        print("\n📊 Inserting 30 days of revenue data...")
        
        revenue_count = 0
        for company_id, company_name in companies:
            for i in range(30):
                date = (datetime.now() - timedelta(days=i)).date()
                # Random revenue between 3M - 10M per day
                total_revenue = random.randint(3000, 10000) * 1000
                
                cur.execute("""
                    INSERT INTO daily_revenue (date, company_id, total_revenue, created_at)
                    VALUES (%s, %s, %s, NOW());
                """, (date, company_id, total_revenue))
                revenue_count += cur.rowcount
        
        conn.commit()
        
        print(f"\n✨ Successfully inserted/updated {revenue_count} revenue records")
        print(f"   ({len(companies)} companies × 30 days)")
        print("\n🎯 Dashboard should now show revenue data!")
        
    except Exception as e:
        if conn:
            conn.rollback()
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if conn:
            cur.close()
            conn.close()

if __name__ == '__main__':
    seed_revenue()
