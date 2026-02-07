import os
from supabase import create_client

supabase = create_client(
    'https://dqddxowyikefqcdiioyh.supabase.co', 
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxZGR4b3d5aWtlZnFjZGlpb3loIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTc5NzEzNiwiZXhwIjoyMDc3MzczMTM2fQ.zLzk5cWJqYcM0zFhJzTxCx3K3Q-ZvFN7X5JKzV-vQps'
)

# Create RPC function for safe delivery completion
sql = """
-- Function to complete delivery with transaction safety
CREATE OR REPLACE FUNCTION complete_delivery(
    p_delivery_id UUID,
    p_order_id UUID,
    p_payment_status TEXT DEFAULT NULL,
    p_payment_method TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Update deliveries table
    UPDATE deliveries 
    SET 
        status = 'completed',
        completed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_delivery_id;
    
    -- Check if delivery update was successful
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Delivery not found');
    END IF;
    
    -- Update sales_orders table
    IF p_payment_status IS NOT NULL AND p_payment_method IS NOT NULL THEN
        UPDATE sales_orders 
        SET 
            delivery_status = 'delivered',
            payment_status = p_payment_status,
            payment_method = p_payment_method,
            payment_collected_at = CASE WHEN p_payment_status = 'paid' THEN NOW() ELSE payment_collected_at END,
            updated_at = NOW()
        WHERE id = p_order_id;
    ELSE
        UPDATE sales_orders 
        SET 
            delivery_status = 'delivered',
            updated_at = NOW()
        WHERE id = p_order_id;
    END IF;
    
    -- Check if order update was successful
    IF NOT FOUND THEN
        -- Rollback by raising exception
        RAISE EXCEPTION 'Order not found, rolling back delivery update';
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Delivery completed successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Function to start delivery (pickup)
CREATE OR REPLACE FUNCTION start_delivery(
    p_delivery_id UUID,
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update deliveries table
    UPDATE deliveries 
    SET 
        status = 'in_progress',
        started_at = NOW(),
        updated_at = NOW()
    WHERE id = p_delivery_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Delivery not found');
    END IF;
    
    -- Update sales_orders table
    UPDATE sales_orders 
    SET 
        delivery_status = 'delivering',
        updated_at = NOW()
    WHERE id = p_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found, rolling back';
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Delivery started successfully');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION complete_delivery(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_delivery(UUID, UUID, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION start_delivery(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION start_delivery(UUID, UUID) TO anon;
"""

print("Creating RPC functions for safe delivery updates...")
try:
    result = supabase.rpc('exec_sql', {'sql': sql}).execute()
    print("✅ RPC functions created successfully!")
except Exception as e:
    # Try direct SQL execution
    print(f"Note: {e}")
    print("\nTrying alternative method...")
    
    # Split and execute each function separately
    functions = [
        # complete_delivery function
        """
        CREATE OR REPLACE FUNCTION complete_delivery(
            p_delivery_id UUID,
            p_order_id UUID,
            p_payment_status TEXT DEFAULT NULL,
            p_payment_method TEXT DEFAULT NULL
        )
        RETURNS JSONB
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        DECLARE
            v_result JSONB;
        BEGIN
            UPDATE deliveries 
            SET status = 'completed', completed_at = NOW(), updated_at = NOW()
            WHERE id = p_delivery_id;
            
            IF NOT FOUND THEN
                RETURN jsonb_build_object('success', false, 'error', 'Delivery not found');
            END IF;
            
            IF p_payment_status IS NOT NULL AND p_payment_method IS NOT NULL THEN
                UPDATE sales_orders 
                SET delivery_status = 'delivered', payment_status = p_payment_status, payment_method = p_payment_method,
                    payment_collected_at = CASE WHEN p_payment_status = 'paid' THEN NOW() ELSE payment_collected_at END,
                    updated_at = NOW()
                WHERE id = p_order_id;
            ELSE
                UPDATE sales_orders SET delivery_status = 'delivered', updated_at = NOW() WHERE id = p_order_id;
            END IF;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Order not found';
            END IF;
            
            RETURN jsonb_build_object('success', true, 'message', 'Delivery completed');
        EXCEPTION
            WHEN OTHERS THEN
                RETURN jsonb_build_object('success', false, 'error', SQLERRM);
        END;
        $$;
        """,
        # start_delivery function
        """
        CREATE OR REPLACE FUNCTION start_delivery(
            p_delivery_id UUID,
            p_order_id UUID
        )
        RETURNS JSONB
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        BEGIN
            UPDATE deliveries SET status = 'in_progress', started_at = NOW(), updated_at = NOW() WHERE id = p_delivery_id;
            IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'Delivery not found'); END IF;
            
            UPDATE sales_orders SET delivery_status = 'delivering', updated_at = NOW() WHERE id = p_order_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'Order not found'; END IF;
            
            RETURN jsonb_build_object('success', true, 'message', 'Delivery started');
        EXCEPTION
            WHEN OTHERS THEN
                RETURN jsonb_build_object('success', false, 'error', SQLERRM);
        END;
        $$;
        """
    ]
    
    print("\n⚠️ Cannot create functions via Python SDK.")
    print("Please run this SQL in Supabase SQL Editor:\n")
    print("=" * 60)
    print(sql)
    print("=" * 60)
    print("\nSaving SQL to file: create_delivery_rpc.sql")
    
    with open('create_delivery_rpc.sql', 'w') as f:
        f.write(sql)
    
    print("✅ SQL saved to create_delivery_rpc.sql")
    print("\n📋 Next steps:")
    print("1. Go to Supabase Dashboard > SQL Editor")
    print("2. Copy and run the SQL from create_delivery_rpc.sql")
    print("3. Then I'll update Flutter code to use these RPC functions")
