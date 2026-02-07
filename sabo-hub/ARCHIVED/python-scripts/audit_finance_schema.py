"""
Finance Module Schema Audit
Connects to Supabase and retrieves full schema for finance-related tables.
"""
import psycopg2

CONN_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def run_audit():
    conn = psycopg2.connect(CONN_STRING)
    cur = conn.cursor()

    # 1. List ALL tables in public schema
    print("=" * 80)
    print("ALL TABLES IN PUBLIC SCHEMA")
    print("=" * 80)
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name;
    """)
    all_tables = [row[0] for row in cur.fetchall()]
    for t in all_tables:
        print(f"  - {t}")
    print(f"\nTotal: {len(all_tables)} tables\n")

    # 2. Identify finance-related tables
    finance_keywords = ['sales', 'order', 'customer', 'payment', 'debt', 'invoice',
                        'receivable', 'credit', 'finance', 'billing', 'ledger',
                        'transaction', 'collection', 'remittance', 'refund']
    finance_tables = []
    for t in all_tables:
        for kw in finance_keywords:
            if kw in t.lower():
                finance_tables.append(t)
                break

    print("=" * 80)
    print("FINANCE-RELATED TABLES IDENTIFIED")
    print("=" * 80)
    for t in finance_tables:
        print(f"  - {t}")
    print(f"\nTotal: {len(finance_tables)} finance-related tables\n")

    # 3. Core tables to always include
    core_tables = ['sales_orders', 'sales_order_items', 'customers', 'payments',
                   'customer_payments', 'invoices', 'debts']
    
    # Merge: core + finance-related (deduplicated)
    target_tables = list(dict.fromkeys(core_tables + finance_tables))

    # 4. Get full schema for each target table
    for table in target_tables:
        if table not in all_tables:
            print(f"\n{'=' * 80}")
            print(f"TABLE: {table} — DOES NOT EXIST")
            print(f"{'=' * 80}")
            continue

        print(f"\n{'=' * 80}")
        print(f"TABLE: {table}")
        print(f"{'=' * 80}")

        # Column details
        cur.execute("""
            SELECT column_name, data_type, column_default, is_nullable, 
                   character_maximum_length, numeric_precision, numeric_scale,
                   udt_name
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            ORDER BY ordinal_position;
        """, (table,))
        columns = cur.fetchall()

        print(f"{'Column':<35} {'Type':<25} {'Nullable':<10} {'Default'}")
        print("-" * 120)
        for col in columns:
            col_name, data_type, col_default, nullable, max_len, num_prec, num_scale, udt = col
            type_str = data_type
            if max_len:
                type_str += f"({max_len})"
            elif udt and udt != data_type:
                type_str = udt
            default_str = str(col_default) if col_default else ""
            if len(default_str) > 50:
                default_str = default_str[:50] + "..."
            print(f"{col_name:<35} {type_str:<25} {nullable:<10} {default_str}")

        # Primary key
        cur.execute("""
            SELECT kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_schema = 'public' AND tc.table_name = %s 
                AND tc.constraint_type = 'PRIMARY KEY'
            ORDER BY kcu.ordinal_position;
        """, (table,))
        pks = [row[0] for row in cur.fetchall()]
        if pks:
            print(f"\n  PRIMARY KEY: ({', '.join(pks)})")

        # Foreign keys
        cur.execute("""
            SELECT kcu.column_name, ccu.table_name AS ref_table, ccu.column_name AS ref_column
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name
            JOIN information_schema.constraint_column_usage ccu 
                ON tc.constraint_name = ccu.constraint_name
            WHERE tc.table_schema = 'public' AND tc.table_name = %s 
                AND tc.constraint_type = 'FOREIGN KEY';
        """, (table,))
        fks = cur.fetchall()
        if fks:
            print(f"\n  FOREIGN KEYS:")
            for fk in fks:
                print(f"    {fk[0]} -> {fk[1]}.{fk[2]}")

        # Row count
        cur.execute(f'SELECT COUNT(*) FROM public."{table}";')
        count = cur.fetchone()[0]
        print(f"\n  ROW COUNT: {count}")

    # 5. Also check for RPC functions related to finance
    print(f"\n{'=' * 80}")
    print("FINANCE-RELATED RPC FUNCTIONS")
    print("=" * 80)
    cur.execute("""
        SELECT routine_name, data_type as return_type
        FROM information_schema.routines
        WHERE routine_schema = 'public' 
        AND routine_type = 'FUNCTION'
        AND (routine_name ILIKE '%sales%' OR routine_name ILIKE '%payment%' 
             OR routine_name ILIKE '%debt%' OR routine_name ILIKE '%invoice%'
             OR routine_name ILIKE '%customer%' OR routine_name ILIKE '%receivable%'
             OR routine_name ILIKE '%finance%' OR routine_name ILIKE '%order%')
        ORDER BY routine_name;
    """)
    funcs = cur.fetchall()
    for f in funcs:
        print(f"  {f[0]} -> returns {f[1]}")
    print(f"\nTotal: {len(funcs)} functions")

    # 6. Check views
    print(f"\n{'=' * 80}")
    print("FINANCE-RELATED VIEWS")
    print("=" * 80)
    cur.execute("""
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
        AND (table_name ILIKE '%sales%' OR table_name ILIKE '%payment%' 
             OR table_name ILIKE '%debt%' OR table_name ILIKE '%invoice%'
             OR table_name ILIKE '%customer%' OR table_name ILIKE '%receivable%'
             OR table_name ILIKE '%finance%' OR table_name ILIKE '%order%')
        ORDER BY table_name;
    """)
    views = cur.fetchall()
    for v in views:
        print(f"  {v[0]}")
    print(f"\nTotal: {len(views)} views")

    cur.close()
    conn.close()
    print("\n\nAudit complete.")

if __name__ == "__main__":
    run_audit()
