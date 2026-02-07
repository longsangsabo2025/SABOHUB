import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
cur = conn.cursor()

# Migrate data from 'note' column to 'notes' column where notes is empty
print("=== Migrating note → notes in customer_payments ===")
cur.execute("""
    UPDATE customer_payments 
    SET notes = note 
    WHERE note IS NOT NULL AND note != '' 
    AND (notes IS NULL OR notes = '')
""")
migrated = cur.rowcount
print(f"  Migrated {migrated} rows from note to notes")

# Drop the duplicate 'note' column
print("=== Dropping duplicate 'note' column ===")
cur.execute("ALTER TABLE customer_payments DROP COLUMN IF EXISTS note")
print("  Done - dropped 'note' column, keeping 'notes'")

# Also fix payment_method = 'None' (string) → NULL
print("\n=== Fixing payment_method = 'None' → NULL ===")
cur.execute("UPDATE customer_payments SET payment_method = NULL WHERE payment_method = 'None'")
fixed = cur.rowcount
print(f"  Fixed {fixed} rows with 'None' string payment_method")

conn.commit()
cur.close()
conn.close()
print("\n✅ Database cleanup complete!")
