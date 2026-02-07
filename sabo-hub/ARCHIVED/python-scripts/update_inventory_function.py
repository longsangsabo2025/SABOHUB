"""
Update process_inventory_movement function to handle transfer-out and transfer-in
"""
import psycopg2

DATABASE_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

print("=" * 70)
print("UPDATING process_inventory_movement FUNCTION")
print("=" * 70)

try:
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor()
    print("✓ Connected\n")

    print("Creating new version of function...")
    
    cur.execute("""
CREATE OR REPLACE FUNCTION public.process_inventory_movement()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
  -- Record before quantity
  SELECT COALESCE(quantity, 0) INTO NEW.before_quantity
  FROM public.inventory
  WHERE warehouse_id = NEW.warehouse_id AND product_id = NEW.product_id;
  
  IF NEW.before_quantity IS NULL THEN
    NEW.before_quantity := 0;
  END IF;

  -- Update inventory based on movement type
  IF NEW.type = 'in' OR NEW.type = 'transfer-in' THEN
    -- Stock IN: Add to warehouse
    INSERT INTO public.inventory (company_id, warehouse_id, product_id, quantity)
    VALUES (NEW.company_id, NEW.warehouse_id, NEW.product_id, NEW.quantity)
    ON CONFLICT (warehouse_id, product_id)
    DO UPDATE SET 
      quantity = inventory.quantity + NEW.quantity,
      updated_at = now();
      
  ELSIF NEW.type = 'out' OR NEW.type = 'transfer-out' THEN
    -- Stock OUT: Subtract from warehouse
    UPDATE public.inventory
    SET 
      quantity = GREATEST(0, quantity - NEW.quantity),
      updated_at = now()
    WHERE warehouse_id = NEW.warehouse_id AND product_id = NEW.product_id;
    
  ELSIF NEW.type = 'adjustment' OR NEW.type = 'count' THEN
    -- Adjustment: Set to exact quantity
    INSERT INTO public.inventory (company_id, warehouse_id, product_id, quantity)
    VALUES (NEW.company_id, NEW.warehouse_id, NEW.product_id, NEW.quantity)
    ON CONFLICT (warehouse_id, product_id)
    DO UPDATE SET 
      quantity = NEW.quantity,
      last_count_date = CURRENT_DATE,
      last_count_quantity = NEW.quantity,
      updated_at = now();
      
  ELSIF NEW.type = 'transfer' AND NEW.destination_warehouse_id IS NOT NULL THEN
    -- Legacy transfer type (for backward compatibility)
    -- Out from source
    UPDATE public.inventory
    SET 
      quantity = GREATEST(0, quantity - NEW.quantity),
      updated_at = now()
    WHERE warehouse_id = NEW.warehouse_id AND product_id = NEW.product_id;
    
    -- In to destination
    INSERT INTO public.inventory (company_id, warehouse_id, product_id, quantity)
    VALUES (NEW.company_id, NEW.destination_warehouse_id, NEW.product_id, NEW.quantity)
    ON CONFLICT (warehouse_id, product_id)
    DO UPDATE SET 
      quantity = inventory.quantity + NEW.quantity,
      updated_at = now();
  END IF;

  -- Record after quantity
  SELECT quantity INTO NEW.after_quantity
  FROM public.inventory
  WHERE warehouse_id = NEW.warehouse_id AND product_id = NEW.product_id;
  
  RETURN NEW;
END;
$function$;
    """)
    
    print("✓ Function created/updated")
    
    conn.commit()
    print("\n" + "=" * 70)
    print("✅ SUCCESS - FUNCTION UPDATED")
    print("=" * 70)
    print("\nChanges:")
    print("  ✓ Now handles 'transfer-in' type (add to destination)")
    print("  ✓ Now handles 'transfer-out' type (subtract from source)")
    print("  ✓ Keeps 'transfer' type for backward compatibility")
    print("  ✓ Uses GREATEST(0, ...) to prevent negative inventory")

except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    if conn:
        conn.rollback()
        print("⚠️  Transaction rolled back")
finally:
    if 'cur' in locals():
        cur.close()
    if 'conn' in locals():
        conn.close()
        print("\n✓ Connection closed")
