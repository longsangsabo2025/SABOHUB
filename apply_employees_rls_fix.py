import psycopg2

# Connection string
conn_string = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

try:
    conn = psycopg2.connect(conn_string)
    cursor = conn.cursor()
    
    print("=" * 80)
    print("FIXING EMPLOYEES TABLE RLS POLICIES")
    print("=" * 80)
    
    # Read SQL file
    with open('fix_employees_table_rls.sql', 'r', encoding='utf-8') as f:
        sql = f.read()
    
    # Execute SQL
    print("\nExecuting SQL commands...")
    cursor.execute(sql)
    conn.commit()
    
    print("✅ RLS policies updated successfully!")
    
    # Test query
    print("\nTesting query...")
    cursor.execute("""
        SELECT id, full_name, role, company_id 
        FROM public.employees 
        WHERE company_id = 'feef10d3-899d-4554-8107-b2256918213a'
        LIMIT 5
    """)
    
    results = cursor.fetchall()
    print(f"\nFound {len(results)} employees:")
    for row in results:
        print(f"  - {row[1]} ({row[2]})")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 80)
    print("COMPLETE")
    print("=" * 80)

except Exception as e:
    print(f"\n❌ Error: {e}")
    if conn:
        conn.rollback()
