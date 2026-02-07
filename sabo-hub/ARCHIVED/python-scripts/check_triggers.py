#!/usr/bin/env python3
"""Check database triggers on inventory table"""

import psycopg2
import os
from dotenv import load_dotenv
load_dotenv('sabohub-nexus/.env')

# Use pooler URL
conn = psycopg2.connect(os.getenv('VITE_SUPABASE_POOLER_URL'))
cur = conn.cursor()

print('=== TRIGGERS ON INVENTORY TABLE ===')
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers
    WHERE event_object_table = 'inventory'
""")
triggers = cur.fetchall()
if triggers:
    for t in triggers:
        print(f'Trigger: {t[0]}, Event: {t[1]}')
        print(f'Action: {t[2][:200]}...')
        print('---')
else:
    print('No triggers found on inventory table')

print('\n=== TRIGGERS ON INVENTORY_MOVEMENTS TABLE ===')
cur.execute("""
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers
    WHERE event_object_table = 'inventory_movements'
""")
triggers = cur.fetchall()
if triggers:
    for t in triggers:
        print(f'Trigger: {t[0]}, Event: {t[1]}')
        print(f'Action: {t[2][:200]}...')
        print('---')
else:
    print('No triggers found on inventory_movements table')

cur.close()
conn.close()
