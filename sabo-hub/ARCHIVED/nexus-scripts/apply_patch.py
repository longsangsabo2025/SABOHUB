#!/usr/bin/env python3
"""Execute missing tables patch"""

import sys
from pathlib import Path

try:
    import psycopg2
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
PATCH_FILE = Path(__file__).parent / "database" / "migrations" / "038_missing_tables_patch.sql"

print("=" * 80)
print("🔧 APPLYING MISSING TABLES PATCH")
print("=" * 80)
print()

# Read SQL
sql_content = PATCH_FILE.read_text(encoding='utf-8')
print(f"📄 Patch file: {PATCH_FILE.name}")
print(f"   Size: {len(sql_content):,} characters")
print()

# Execute
print("⚡ Executing patch...")
conn = psycopg2.connect(POOLER_URL)
conn.autocommit = False
cursor = conn.cursor()

try:
    cursor.execute(sql_content)
    conn.commit()
    print("✅ Patch applied successfully!")
    print()
    
    # Verify
    print("🔍 Verifying tables...")
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN (
            'visit_checklist_items',
            'store_visit_checklist_responses',
            'store_visit_photos',
            'financial_statement_lines'
        )
        ORDER BY table_name;
    """)
    
    tables = cursor.fetchall()
    for i, (table_name,) in enumerate(tables, 1):
        print(f"   ✅ {table_name}")
    
    print()
    
    if len(tables) == 4:
        print("🎉 All 4 missing tables created successfully!")
    else:
        print(f"⚠️  Expected 4 tables, found {len(tables)}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    conn.rollback()
    sys.exit(1)
finally:
    cursor.close()
    conn.close()

print()
print("=" * 80)
print("✅ PATCH COMPLETE")
print("=" * 80)
