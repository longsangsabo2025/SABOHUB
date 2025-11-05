from supabase import create_client
import os
from dotenv import load_dotenv
import json

load_dotenv()

supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)

# Lấy tất cả users
result = supabase.table('users').select('id, full_name, email, role').order('created_at').execute()

print(f"\n=== TOTAL USERS: {len(result.data)} ===\n")

# Group by role
roles = {}
for user in result.data:
    role = user['role']
    if role not in roles:
        roles[role] = []
    roles[role].append(user)

# Print summary
for role, users in roles.items():
    print(f"\n{role.upper()}: {len(users)} users")
    for user in users:
        print(f"  - {user['full_name']} ({user['email']})")
