import psycopg2

conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("🔍 Checking foreign keys between users and companies")
print("="*60)

try:
    conn = psycopg2.connect(conn_string)
    cur = conn.cursor()
    
    # Check foreign keys from users to companies
    print("\n📋 Foreign keys from USERS to COMPANIES:")
    cur.execute("""
        SELECT
            conname AS constraint_name,
            a.attname AS column_name,
            confrelid::regclass AS referenced_table
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
        WHERE c.conrelid = 'users'::regclass
        AND c.confrelid = 'companies'::regclass
        AND c.contype = 'f'
    """)
    
    user_fks = cur.fetchall()
    for fk in user_fks:
        print(f"  - {fk[0]}: users.{fk[1]} → {fk[2]}")
    
    # Check foreign keys from companies to users
    print("\n📋 Foreign keys from COMPANIES to USERS:")
    cur.execute("""
        SELECT
            conname AS constraint_name,
            a.attname AS column_name,
            confrelid::regclass AS referenced_table
        FROM pg_constraint c
        JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
        WHERE c.conrelid = 'companies'::regclass
        AND c.confrelid = 'users'::regclass
        AND c.contype = 'f'
    """)
    
    company_fks = cur.fetchall()
    for fk in company_fks:
        print(f"  - {fk[0]}: companies.{fk[1]} → {fk[2]}")
    
    print("\n" + "="*60)
    print(f"Total: {len(user_fks)} FK from users to companies")
    print(f"Total: {len(company_fks)} FK from companies to users")
    
    cur.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
