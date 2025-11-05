import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()
conn = psycopg2.connect(os.getenv('SUPABASE_CONNECTION_STRING'))
cursor = conn.cursor()

# Check tasks table structure
print('\n📋 TASKS TABLE STRUCTURE:')
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'tasks'
    ORDER BY ordinal_position
""")
columns = cursor.fetchall()

if columns:
    for col in columns:
        print(f'   - {col[0]}: {col[1]} (nullable: {col[2]})')
else:
    print('   ❌ Table "tasks" not found!')

# Check if there's a task_templates table instead
print('\n🔍 Checking for task_templates table:')
cursor.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'task_templates'
    ORDER BY ordinal_position
""")
templates = cursor.fetchall()

if templates:
    print('   ✅ Found task_templates table:')
    for col in templates:
        print(f'   - {col[0]}: {col[1]} (nullable: {col[2]})')

cursor.close()
conn.close()
