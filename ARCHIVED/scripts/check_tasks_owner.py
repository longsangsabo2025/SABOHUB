import psycopg2
from dotenv import load_dotenv
import os

load_dotenv()

conn = psycopg2.connect(os.getenv("SUPABASE_CONNECTION_STRING"))
cur = conn.cursor()

print("\n🔍 CHECKING TASKS TABLE\n")
print("=" * 80)

# Get tasks without owner
cur.execute("""
    SELECT id, title, company_id, created_by, created_at
    FROM tasks
    WHERE created_by IS NULL
""")

tasks = cur.fetchall()
print(f"\n❌ Found {len(tasks)} tasks without owner:\n")

for task in tasks:
    print(f"Task ID: {task[0]}")
    print(f"Title: {task[1]}")
    print(f"Company ID: {task[2]}")
    print(f"Created by: {task[3]}")
    print(f"Created at: {task[4]}")
    print()

# Get tasks with owner
cur.execute("""
    SELECT id, title, company_id, created_by, created_at
    FROM tasks
    WHERE created_by IS NOT NULL
    LIMIT 3
""")

tasks = cur.fetchall()
print(f"\n✅ Sample tasks WITH owner:\n")

for task in tasks:
    print(f"Task ID: {task[0]}")
    print(f"Title: {task[1]}")
    print(f"Company ID: {task[2]}")
    print(f"Created by: {task[3]}")
    print(f"Created at: {task[4]}")
    print()

cur.close()
conn.close()
