"""
Validation system for warehouse creation
Ensures every new warehouse works perfectly
"""
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def validate_new_warehouse(warehouse_id: str, company_id: str, conn) -> dict:
    """
    Validate that a newly created warehouse has all required setup.
    Returns validation report.
    """
    cur = conn.cursor(cursor_factory=RealDictCursor)
    issues = []
    warnings = []
    
    # 1. Check warehouse record
    cur.execute("""
        SELECT id, name, code, is_primary, is_active, type, created_at
        FROM warehouses
        WHERE id = %s AND company_id = %s
    """, (warehouse_id, company_id))
    
    warehouse = cur.fetchone()
    if not warehouse:
        issues.append("Warehouse record not found in database")
        return {'issues': issues, 'warnings': warnings, 'valid': False}
    
    # 2. Check is_primary flag
    if warehouse['is_primary'] is None:
        warnings.append("is_primary column is NULL (should be TRUE or FALSE)")
    elif warehouse['type'] == 'main' and not warehouse['is_primary']:
        warnings.append("Warehouse type is 'main' but is_primary is FALSE")
    
    # 3. Check is_active flag
    if warehouse['is_active'] is None or not warehouse['is_active']:
        warnings.append("Warehouse is not active (is_active = FALSE or NULL)")
    
    # 4. Check required fields
    if not warehouse['name']:
        issues.append("Warehouse name is empty")
    if not warehouse['code']:
        warnings.append("Warehouse code is empty")
    
    # 5. Check RLS policies
    cur.execute("""
        SELECT EXISTS(
            SELECT 1 FROM pg_policies
            WHERE tablename = 'warehouses'
            AND policyname LIKE '%read%'
        ) as has_read_policy
    """)
    
    if not cur.fetchone()['has_read_policy']:
        warnings.append("No RLS read policy found on warehouses table")
    
    # 6. Check inventory table can access this warehouse
    cur.execute("""
        SELECT COUNT(*) as inventory_count
        FROM inventory
        WHERE warehouse_id = %s
    """, (warehouse_id,))
    
    inv_count = cur.fetchone()['inventory_count']
    
    # 7. Check inventory_movements table for this warehouse
    cur.execute("""
        SELECT COUNT(*) as movement_count
        FROM inventory_movements
        WHERE warehouse_id = %s
    """, (warehouse_id,))
    
    mov_count = cur.fetchone()['movement_count']
    
    if inv_count == 0 and mov_count == 0:
        warnings.append("Warehouse has no inventory and no movement history (brand new)")
    
    # 8. Check for other warehouses in same company
    cur.execute("""
        SELECT COUNT(*) as other_count
        FROM warehouses
        WHERE company_id = %s AND id != %s
    """, (company_id, warehouse_id))
    
    other_count = cur.fetchone()['other_count']
    
    if other_count == 0:
        # This is the first warehouse
        if not warehouse['is_primary']:
            issues.append("This is the FIRST warehouse for company but is_primary != TRUE")
    
    # 9. Check foreign key constraint
    cur.execute("""
        SELECT EXISTS(
            SELECT 1 FROM information_schema.table_constraints
            WHERE table_name = 'warehouses'
            AND constraint_name LIKE '%company_id%'
            AND constraint_type = 'FOREIGN KEY'
        ) as has_fk
    """)
    
    if not cur.fetchone()['has_fk']:
        issues.append("No foreign key constraint on warehouses.company_id")
    
    valid = len(issues) == 0
    
    return {
        'valid': valid,
        'warehouse': warehouse,
        'inventory_count': inv_count,
        'movement_count': mov_count,
        'other_warehouses': other_count,
        'issues': issues,
        'warnings': warnings
    }


print("=" * 70)
print("WAREHOUSE VALIDATION SYSTEM")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    print("✓ Connected\n")
    
    # Get all warehouses and validate
    cur.execute("""
        SELECT DISTINCT
            company_id,
            COUNT(*) as warehouse_count
        FROM warehouses
        GROUP BY company_id
    """)
    
    companies = cur.fetchall()
    
    for company in companies:
        company_id = company['company_id']
        print(f"\nCompany {company_id} ({company['warehouse_count']} warehouses):")
        print("-" * 70)
        
        cur.execute("""
            SELECT id, name, code, is_primary, type
            FROM warehouses
            WHERE company_id = %s
            ORDER BY is_primary DESC, created_at
        """, (company_id,))
        
        warehouses = cur.fetchall()
        
        for wh in warehouses:
            report = validate_new_warehouse(wh['id'], company_id, conn)
            
            status = "✅" if report['valid'] else "❌"
            primary = " [PRIMARY]" if wh['is_primary'] else ""
            print(f"\n{status} {wh['name']}{primary}")
            print(f"   Code: {wh['code']}, Type: {wh['type']}")
            print(f"   Inventory: {report['inventory_count']} items, Movements: {report['movement_count']}")
            
            if report['issues']:
                print(f"   ❌ ISSUES:")
                for issue in report['issues']:
                    print(f"      - {issue}")
            
            if report['warnings']:
                print(f"   ⚠️  WARNINGS:")
                for warning in report['warnings']:
                    print(f"      - {warning}")

    print("\n" + "=" * 70)
    print("RECOMMENDATIONS FOR FUTURE:")
    print("=" * 70)
    print("""
1. When creating a new warehouse via UI:
   ✓ Always set is_primary correctly
   ✓ For first warehouse in company: must set is_primary = TRUE
   ✓ For subsequent warehouses: set is_primary = FALSE
   ✓ Always set is_active = TRUE by default

2. After warehouse creation:
   ✓ Auto-validate in database trigger
   ✓ Create initial inventory_movements if stock exists
   ✓ Run this validation script to catch issues

3. Schema constraints to add:
   ✓ Add CHECK constraint for is_primary per company
   ✓ Add default is_active = TRUE
   ✓ Add default is_primary = FALSE

4. Application logic:
   ✓ On warehouse creation form submit:
      - Check if this is first warehouse
      - If yes: force is_primary = TRUE, hide toggle
      - If no: default is_primary = FALSE
   ✓ After insert: run validation immediately
   ✓ Show warning if any validation issues found
""")

    print("=" * 70)

except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
