#!/usr/bin/env python3
"""
Deploy RPC function to deduct inventory when picking is completed
"""

import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"

def deploy_deduct_stock_rpc():
    print("🚀 Deploying deduct_stock_for_order RPC...")
    
    conn = psycopg2.connect(POOLER_URL)
    conn.autocommit = True
    cur = conn.cursor()
    
    # RPC to deduct stock when picking is completed
    # This function:
    # 1. Gets all items from the order
    # 2. Gets the warehouse to deduct from (default main warehouse)
    # 3. Creates inventory_movement records (type='out')
    # 4. The existing trigger will auto-update inventory table
    
    deduct_stock_rpc = """
    CREATE OR REPLACE FUNCTION deduct_stock_for_order(
        p_order_id UUID,
        p_warehouse_id UUID DEFAULT NULL
    )
    RETURNS JSONB
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    DECLARE
        v_company_id UUID;
        v_warehouse_id UUID;
        v_item RECORD;
        v_current_stock INT;
        v_deducted_count INT := 0;
        v_errors TEXT[] := ARRAY[]::TEXT[];
    BEGIN
        -- Get company_id from order
        SELECT company_id INTO v_company_id
        FROM sales_orders WHERE id = p_order_id;
        
        IF v_company_id IS NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'Order not found');
        END IF;
        
        -- Get warehouse (use provided or default main warehouse)
        IF p_warehouse_id IS NOT NULL THEN
            v_warehouse_id := p_warehouse_id;
        ELSE
            SELECT id INTO v_warehouse_id
            FROM warehouses
            WHERE company_id = v_company_id AND type = 'main' AND is_active = true
            LIMIT 1;
        END IF;
        
        IF v_warehouse_id IS NULL THEN
            RETURN jsonb_build_object('success', false, 'error', 'No active warehouse found');
        END IF;
        
        -- Loop through order items and create OUT movements
        FOR v_item IN 
            SELECT soi.product_id, soi.quantity, p.name as product_name
            FROM sales_order_items soi
            JOIN products p ON p.id = soi.product_id
            WHERE soi.order_id = p_order_id
        LOOP
            -- Check current stock
            SELECT COALESCE(quantity, 0) INTO v_current_stock
            FROM inventory
            WHERE warehouse_id = v_warehouse_id AND product_id = v_item.product_id;
            
            IF v_current_stock < v_item.quantity THEN
                -- Not enough stock - add to errors but continue
                v_errors := array_append(v_errors, 
                    format('Không đủ %s (cần %s, còn %s)', 
                        v_item.product_name, v_item.quantity, v_current_stock));
            ELSE
                -- Insert OUT movement - trigger will handle inventory update
                INSERT INTO inventory_movements (
                    company_id,
                    warehouse_id,
                    product_id,
                    type,
                    quantity,
                    reason,
                    reference_id,
                    reference_type
                ) VALUES (
                    v_company_id,
                    v_warehouse_id,
                    v_item.product_id,
                    'out',
                    v_item.quantity,
                    'Xuất kho theo đơn hàng',
                    p_order_id,
                    'sales_order'
                );
                
                v_deducted_count := v_deducted_count + 1;
            END IF;
        END LOOP;
        
        -- Mark order as stock deducted
        UPDATE sales_orders SET
            stock_deducted = true,
            stock_deducted_at = NOW(),
            updated_at = NOW()
        WHERE id = p_order_id;
        
        IF array_length(v_errors, 1) > 0 THEN
            RETURN jsonb_build_object(
                'success', true,
                'partial', true,
                'deducted_count', v_deducted_count,
                'errors', to_jsonb(v_errors)
            );
        END IF;
        
        RETURN jsonb_build_object(
            'success', true,
            'deducted_count', v_deducted_count,
            'warehouse_id', v_warehouse_id
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
    END;
    $$;
    """
    
    try:
        print("📦 Creating deduct_stock_for_order RPC...")
        cur.execute(deduct_stock_rpc)
        print("✅ deduct_stock_for_order created!")
        
        # Check if sales_orders has stock_deducted column
        cur.execute("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'sales_orders' AND column_name = 'stock_deducted'
        """)
        if not cur.fetchone():
            print("📦 Adding stock_deducted columns to sales_orders...")
            cur.execute("""
                ALTER TABLE sales_orders 
                ADD COLUMN IF NOT EXISTS stock_deducted BOOLEAN DEFAULT FALSE,
                ADD COLUMN IF NOT EXISTS stock_deducted_at TIMESTAMPTZ
            """)
            print("✅ Columns added!")
        
        # Check if inventory_movements has reference columns
        cur.execute("""
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'inventory_movements' AND column_name = 'reference_id'
        """)
        if not cur.fetchone():
            print("📦 Adding reference columns to inventory_movements...")
            cur.execute("""
                ALTER TABLE inventory_movements 
                ADD COLUMN IF NOT EXISTS reference_id UUID,
                ADD COLUMN IF NOT EXISTS reference_type VARCHAR(50)
            """)
            print("✅ Columns added!")
        
        # Grant permissions
        print("🔐 Granting permissions...")
        cur.execute("GRANT EXECUTE ON FUNCTION deduct_stock_for_order(UUID, UUID) TO authenticated;")
        
        print("\n✨ RPC deployed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        cur.close()
        conn.close()

if __name__ == "__main__":
    deploy_deduct_stock_rpc()
