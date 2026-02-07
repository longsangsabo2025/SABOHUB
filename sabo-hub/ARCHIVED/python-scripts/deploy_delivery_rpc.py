import psycopg2

# Connect via transaction pooler
conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

print("Creating RPC functions for safe delivery updates...")

# Function 1: complete_delivery
sql1 = """
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
        SET delivery_status = 'delivered', 
            payment_status = p_payment_status, 
            payment_method = p_payment_method,
            payment_collected_at = CASE WHEN p_payment_status = 'paid' THEN NOW() ELSE payment_collected_at END,
            updated_at = NOW()
        WHERE id = p_order_id;
    ELSE
        UPDATE sales_orders 
        SET delivery_status = 'delivered', updated_at = NOW() 
        WHERE id = p_order_id;
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
"""

# Function 2: start_delivery
sql2 = """
CREATE OR REPLACE FUNCTION start_delivery(
    p_delivery_id UUID,
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE deliveries 
    SET status = 'in_progress', started_at = NOW(), updated_at = NOW() 
    WHERE id = p_delivery_id;
    
    IF NOT FOUND THEN 
        RETURN jsonb_build_object('success', false, 'error', 'Delivery not found'); 
    END IF;
    
    UPDATE sales_orders 
    SET delivery_status = 'delivering', updated_at = NOW() 
    WHERE id = p_order_id;
    
    IF NOT FOUND THEN 
        RAISE EXCEPTION 'Order not found'; 
    END IF;
    
    RETURN jsonb_build_object('success', true, 'message', 'Delivery started');
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;
"""

try:
    print("Creating complete_delivery function...")
    cur.execute(sql1)
    print("✅ complete_delivery created!")
    
    print("Creating start_delivery function...")
    cur.execute(sql2)
    print("✅ start_delivery created!")
    
    # Grant permissions
    print("Granting permissions...")
    cur.execute("GRANT EXECUTE ON FUNCTION complete_delivery(UUID, UUID, TEXT, TEXT) TO authenticated;")
    cur.execute("GRANT EXECUTE ON FUNCTION complete_delivery(UUID, UUID, TEXT, TEXT) TO anon;")
    cur.execute("GRANT EXECUTE ON FUNCTION start_delivery(UUID, UUID) TO authenticated;")
    cur.execute("GRANT EXECUTE ON FUNCTION start_delivery(UUID, UUID) TO anon;")
    print("✅ Permissions granted!")
    
    print("\n🎉 All RPC functions created successfully!")
    
except Exception as e:
    print(f"❌ Error: {e}")

finally:
    cur.close()
    conn.close()
