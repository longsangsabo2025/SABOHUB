"""
Add DB trigger: khi manager reject đơn hàng (set rejected_at),
tự động cancel delivery liên quan → tránh kẹt đơn cho driver.
"""
import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123'
)
cur = conn.cursor()

# Create trigger function
cur.execute("""
CREATE OR REPLACE FUNCTION auto_cancel_delivery_on_reject()
RETURNS TRIGGER AS $$
BEGIN
    -- Khi sales_order bị reject (rejected_at chuyển từ NULL → có giá trị)
    IF OLD.rejected_at IS NULL AND NEW.rejected_at IS NOT NULL THEN
        -- Cancel tất cả deliveries liên quan chưa completed
        UPDATE deliveries 
        SET status = 'cancelled',
            updated_at = NOW(),
            notes = COALESCE(notes, '') || ' [Auto-cancelled: đơn bị hủy bởi quản lý]'
        WHERE order_id = NEW.id 
          AND status NOT IN ('completed', 'cancelled');
        
        -- Reset delivery_status về pending
        NEW.delivery_status := 'pending';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")

# Drop old trigger if exists, then create
cur.execute("""
DROP TRIGGER IF EXISTS trg_auto_cancel_delivery_on_reject ON sales_orders;
""")

cur.execute("""
CREATE TRIGGER trg_auto_cancel_delivery_on_reject
    BEFORE UPDATE ON sales_orders
    FOR EACH ROW
    EXECUTE FUNCTION auto_cancel_delivery_on_reject();
""")

conn.commit()
print("✅ Trigger created: auto_cancel_delivery_on_reject")

# Verify
cur.execute("""
SELECT tgname, tgrelid::regclass, tgenabled 
FROM pg_trigger 
WHERE tgname = 'trg_auto_cancel_delivery_on_reject';
""")
for row in cur.fetchall():
    print(f"  trigger: {row[0]}, table: {row[1]}, enabled: {row[2]}")

# Also fix any currently stuck orders (deliveries with rejected sales_orders)
cur.execute("""
UPDATE deliveries d
SET status = 'cancelled',
    updated_at = NOW(),
    notes = COALESCE(d.notes, '') || ' [Auto-fixed: đơn đã bị hủy trước đó]'
FROM sales_orders so
WHERE d.order_id = so.id
  AND so.rejected_at IS NOT NULL
  AND d.status NOT IN ('completed', 'cancelled');
""")
fixed = cur.rowcount
if fixed > 0:
    print(f"🔧 Fixed {fixed} stuck deliveries (orders were already rejected)")
    
    # Also reset delivery_status for those orders
    cur.execute("""
    UPDATE sales_orders so
    SET delivery_status = 'pending',
        updated_at = NOW()
    WHERE so.rejected_at IS NOT NULL
      AND so.delivery_status NOT IN ('pending', 'delivered');
    """)
    reset = cur.rowcount
    print(f"🔧 Reset delivery_status for {reset} rejected orders")
else:
    print("✅ No stuck deliveries found")

conn.commit()
cur.close()
conn.close()
print("\n🎉 Done! Future rejected orders will auto-cancel deliveries.")
