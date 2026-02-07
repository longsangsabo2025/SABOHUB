#!/usr/bin/env python3
import sys, psycopg2
from pathlib import Path

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
SQL_FILE = Path(__file__).parent / "database" / "migrations" / "039_fix_missing_manufacturing_tables.sql"

print("🔧 Creating missing manufacturing tables...")

sql = SQL_FILE.read_text(encoding='utf-8')
conn = psycopg2.connect(POOLER_URL)
conn.autocommit = False
cursor = conn.cursor()

try:
    cursor.execute(sql)
    conn.commit()
    print("✅ Tables created successfully!")
except Exception as e:
    print(f"❌ Error: {e}")
    conn.rollback()
    sys.exit(1)
finally:
    cursor.close()
    conn.close()
