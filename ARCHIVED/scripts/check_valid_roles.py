import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    print("🔍 Checking valid roles...")
    
    # Get constraint definition
    cur.execute("""
        SELECT conname, pg_get_constraintdef(oid) 
        FROM pg_constraint 
        WHERE conrelid = 'users'::regclass AND contype = 'c'
    """)
    
    constraints = cur.fetchall()
    for constraint in constraints:
        if 'role' in constraint[1].lower():
            print(f"\nConstraint: {constraint[0]}")
            print(f"Definition: {constraint[1]}")
    
    # Also check current users' roles
    print("\n" + "="*60)
    print("Current users and their roles:")
    print("="*60)
    cur.execute("SELECT email, role FROM users")
    users = cur.fetchall()
    
    unique_roles = set()
    for user in users:
        print(f"{user[0]}: {user[1]}")
        if user[1]:
            unique_roles.add(user[1])
    
    print("\n" + "="*60)
    print("Unique roles found in database:")
    print("="*60)
    for role in sorted(unique_roles):
        print(f"  - {role}")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
