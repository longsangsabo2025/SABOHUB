import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

# Check companies table structure
print('\n📋 COMPANIES TABLE STRUCTURE:')
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'companies'
    ORDER BY ordinal_position
""")
columns = cursor.fetchall()
for col in columns:
    print(f'   - {col[0]}: {col[1]} (nullable: {col[2]})')

# Check user_roles table
print('\n📋 USER_ROLES TABLE STRUCTURE:')
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'user_roles'
    ORDER BY ordinal_position
""")
columns = cursor.fetchall()
for col in columns:
    print(f'   - {col[0]}: {col[1]} (nullable: {col[2]})')

# Check users table
print('\n📋 USERS TABLE STRUCTURE:')
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users'
    ORDER BY ordinal_position
""")
columns = cursor.fetchall()
for col in columns:
    print(f'   - {col[0]}: {col[1]} (nullable: {col[2]})')

cursor.close()
conn.close()
