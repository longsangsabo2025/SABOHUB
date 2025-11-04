import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

cursor.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename")
tables = cursor.fetchall()

print('\n📋 Tables in database:')
for t in tables:
    print(f'   - {t[0]}')

cursor.close()
conn.close()
