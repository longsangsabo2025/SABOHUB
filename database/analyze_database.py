#!/usr/bin/env python3
"""
Database Analysis Script for Supabase
Connects to PostgreSQL and analyzes current schema structure
"""

import os
import json
from urllib.parse import urlparse
import psycopg2
from psycopg2.extras import RealDictCursor

# Parse connection string from .env
CONNECTION_STRING = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def get_connection():
    """Create database connection"""
    return psycopg2.connect(CONNECTION_STRING)

def get_all_tables(conn):
    """Get all tables in public schema"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("""
            SELECT 
                schemaname,
                tablename,
                tableowner
            FROM pg_tables 
            WHERE schemaname = 'public'
            ORDER BY tablename;
        """)
        return cur.fetchall()

def get_table_columns(conn, table_name):
    """Get all columns for a table"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("""
            SELECT 
                column_name,
                data_type,
                character_maximum_length,
                is_nullable,
                column_default
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = %s
            ORDER BY ordinal_position;
        """, (table_name,))
        return cur.fetchall()

def get_foreign_keys(conn, table_name):
    """Get foreign key constraints for a table"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("""
            SELECT
                tc.constraint_name,
                kcu.column_name,
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
            AND tc.table_name = %s;
        """, (table_name,))
        return cur.fetchall()

def get_indexes(conn, table_name):
    """Get indexes for a table"""
    with conn.cursor(cursor_factory=RealDictCursor) as cur:
        cur.execute("""
            SELECT
                indexname,
                indexdef
            FROM pg_indexes
            WHERE schemaname = 'public'
            AND tablename = %s;
        """, (table_name,))
        return cur.fetchall()

def get_row_count(conn, table_name):
    """Get approximate row count for a table"""
    with conn.cursor() as cur:
        try:
            cur.execute(f"SELECT COUNT(*) FROM public.{table_name};")
            return cur.fetchone()[0]
        except Exception as e:
            return f"Error: {str(e)}"

def analyze_database():
    """Main analysis function"""
    print("🔍 Analyzing Supabase Database...")
    print("=" * 80)
    
    try:
        conn = get_connection()
        print("✅ Connected to database successfully!\n")
        
        # Get all tables
        tables = get_all_tables(conn)
        print(f"📊 Found {len(tables)} tables in public schema:\n")
        
        analysis = {
            "total_tables": len(tables),
            "tables": []
        }
        
        for table in tables:
            table_name = table['tablename']
            print(f"\n{'='*80}")
            print(f"📋 Table: {table_name}")
            print(f"{'='*80}")
            
            # Get row count
            row_count = get_row_count(conn, table_name)
            print(f"  📊 Rows: {row_count}")
            
            # Get columns
            columns = get_table_columns(conn, table_name)
            print(f"\n  📝 Columns ({len(columns)}):")
            for col in columns:
                nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
                print(f"    - {col['column_name']}: {col['data_type']} {nullable}{default}")
            
            # Get foreign keys
            fkeys = get_foreign_keys(conn, table_name)
            if fkeys:
                print(f"\n  🔗 Foreign Keys ({len(fkeys)}):")
                for fk in fkeys:
                    print(f"    - {fk['column_name']} → {fk['foreign_table_name']}.{fk['foreign_column_name']}")
            
            # Get indexes
            indexes = get_indexes(conn, table_name)
            if indexes:
                print(f"\n  🔍 Indexes ({len(indexes)}):")
                for idx in indexes:
                    print(f"    - {idx['indexname']}")
            
            # Store in analysis
            analysis["tables"].append({
                "name": table_name,
                "row_count": row_count,
                "columns": [dict(c) for c in columns],
                "foreign_keys": [dict(fk) for fk in fkeys],
                "indexes": [dict(idx) for idx in indexes]
            })
        
        # Save to JSON file
        output_file = "database_analysis.json"
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(analysis, f, indent=2, default=str)
        
        print(f"\n{'='*80}")
        print(f"✅ Analysis complete! Saved to: {output_file}")
        print(f"{'='*80}")
        
        # Print summary
        print("\n📊 SUMMARY:")
        print(f"  Total Tables: {len(tables)}")
        print(f"  Tables with data: {sum(1 for t in analysis['tables'] if isinstance(t['row_count'], int) and t['row_count'] > 0)}")
        print(f"  Empty tables: {sum(1 for t in analysis['tables'] if t['row_count'] == 0)}")
        
        conn.close()
        
        return analysis
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    analyze_database()
