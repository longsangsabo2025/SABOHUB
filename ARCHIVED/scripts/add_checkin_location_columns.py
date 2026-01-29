#!/usr/bin/env python3
"""
Add check-in location columns to companies table
"""

import os
from dotenv import load_dotenv
import psycopg2

# Load environment variables
load_dotenv()

# Get connection string
db_url = os.environ.get("SUPABASE_CONNECTION_STRING") or os.environ.get("SUPABASE_DB_URL")

if not db_url:
    print("❌ Missing database connection string in .env")
    exit(1)

try:
    print("🚀 Connecting to database...")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()
    
    print("📝 Adding check-in location columns to companies table...")
    
    # Add columns
    cur.execute("""
        -- Add check-in location columns
        ALTER TABLE companies 
        ADD COLUMN IF NOT EXISTS check_in_latitude DOUBLE PRECISION,
        ADD COLUMN IF NOT EXISTS check_in_longitude DOUBLE PRECISION,
        ADD COLUMN IF NOT EXISTS check_in_radius DOUBLE PRECISION DEFAULT 100.0;
        
        -- Add comment
        COMMENT ON COLUMN companies.check_in_latitude IS 'Latitude for employee check-in validation';
        COMMENT ON COLUMN companies.check_in_longitude IS 'Longitude for employee check-in validation';
        COMMENT ON COLUMN companies.check_in_radius IS 'Allowed radius in meters for check-in (default: 100m)';
    """)
    
    conn.commit()
    
    print("✅ Check-in location columns added successfully!")
    print("📊 Columns added:")
    print("   - check_in_latitude (DOUBLE PRECISION)")
    print("   - check_in_longitude (DOUBLE PRECISION)")
    print("   - check_in_radius (DOUBLE PRECISION, default: 100.0)")
    
    # Show current data
    cur.execute("SELECT id, name, check_in_latitude, check_in_longitude, check_in_radius FROM companies LIMIT 5")
    companies = cur.fetchall()
    
    if companies:
        print("\n📍 Current companies:")
        for company in companies:
            print(f"   - {company[1]}: lat={company[2]}, lng={company[3]}, radius={company[4]}m")
    
    cur.close()
    conn.close()
    
    print("\n✅ Migration completed!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)
