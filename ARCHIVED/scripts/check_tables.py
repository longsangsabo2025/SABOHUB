import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

conn_string = os.getenv('SUPABASE_CONNECTION_STRING')
conn = psycopg2.connect(conn_string)
cursor = conn.cursor()

# Get all tables
cursor.execute('''
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    ORDER BY table_name;
''')

tables = cursor.fetchall()
print('📊 Database Tables:')
print('=' * 60)
for table in tables:
    print(f'  ✅ {table[0]}')

cursor.close()
conn.close()
