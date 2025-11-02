import psycopg2

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

try:
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    
    cursor = conn.cursor()
    
    # Check companies
    cursor.execute("SELECT id, name FROM companies ORDER BY created_at")
    companies = cursor.fetchall()
    print("\n🏢 Companies:")
    for company in companies:
        print(f"  - {company[0]}: {company[1]}")
    
    # Check tasks per company
    for company_id, company_name in companies:
        cursor.execute("""
            SELECT 
                status,
                COUNT(*) as count
            FROM tasks
            WHERE company_id = %s
            GROUP BY status
        """, (company_id,))
        
        print(f"\n📊 Tasks for {company_name}:")
        results = cursor.fetchall()
        if results:
            total = sum(r[1] for r in results)
            print(f"  Total: {total}")
            for status, count in results:
                print(f"  - {status}: {count}")
        else:
            print("  No tasks found")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")
