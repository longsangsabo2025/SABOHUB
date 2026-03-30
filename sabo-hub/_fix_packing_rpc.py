import psycopg2

conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com',
    port=6543,
    dbname='postgres',
    user='postgres.dqddxowyikefqcdiioyh',
    password='Acookingoil123',
    sslmode='require'
)
cur = conn.cursor()

# Create SECURITY DEFINER RPC to bypass RLS for warehouse staff
sql = """
CREATE OR REPLACE FUNCTION mark_order_ready_for_delivery(
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order RECORD;
    v_rows_updated INT;
BEGIN
    -- Verify the order exists and is in the right state
    SELECT id, order_number, status, delivery_status, company_id
    INTO v_order
    FROM sales_orders
    WHERE id = p_order_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Không tìm thấy đơn hàng'
        );
    END IF;

    -- Validate status transition
    IF v_order.status NOT IN ('ready', 'processing', 'confirmed') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Đơn hàng không ở trạng thái phù hợp (status: ' || v_order.status || ')'
        );
    END IF;

    IF v_order.delivery_status != 'pending' THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Delivery status không hợp lệ (delivery_status: ' || v_order.delivery_status || ')'
        );
    END IF;

    -- Perform the update - only update delivery_status, keep status as-is
    -- (we set delivery_status to awaiting_pickup so it moves to "Sẵn sàng" tab)
    UPDATE sales_orders
    SET 
        delivery_status = 'awaiting_pickup',
        updated_at = NOW()
    WHERE id = p_order_id;

    GET DIAGNOSTICS v_rows_updated = ROW_COUNT;

    IF v_rows_updated = 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Cập nhật thất bại'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'order_number', v_order.order_number,
        'message', 'Đơn hàng sẵn sàng để giao cho tài xế'
    );
END;
$$;
"""

cur.execute(sql)
conn.commit()
print('RPC mark_order_ready_for_delivery created successfully')

# Verify it was created
cur.execute("SELECT proname, prosecdef FROM pg_proc WHERE proname = 'mark_order_ready_for_delivery'")
row = cur.fetchone()
print(f'Verified: proname={row[0]}, security_definer={row[1]}')

cur.close()
conn.close()
print('Done')
