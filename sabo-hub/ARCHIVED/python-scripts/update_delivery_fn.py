"""
Update complete_delivery_debt() to auto-create receivables on delivery
"""
import psycopg2

conn = psycopg2.connect(
    "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
)
conn.autocommit = True
cur = conn.cursor()

cur.execute("DROP FUNCTION IF EXISTS complete_delivery_debt(uuid, uuid, uuid, numeric)")
cur.execute("""
CREATE OR REPLACE FUNCTION complete_delivery_debt(
    p_delivery_id UUID,
    p_order_id UUID,
    p_customer_id UUID,
    p_amount NUMERIC
) RETURNS JSONB AS $$
DECLARE
    v_now TIMESTAMPTZ := NOW();
    v_current_debt NUMERIC;
    v_order_number TEXT;
    v_company_id UUID;
    v_due_date DATE;
    v_payment_terms INT;
BEGIN
    -- Get current customer debt and payment_terms
    SELECT COALESCE(total_debt, 0), COALESCE(payment_terms, 30), company_id
    INTO v_current_debt, v_payment_terms, v_company_id
    FROM customers WHERE id = p_customer_id;

    -- Get order info
    SELECT order_number, COALESCE(due_date, CURRENT_DATE + v_payment_terms)
    INTO v_order_number, v_due_date
    FROM sales_orders WHERE id = p_order_id;

    -- Update deliveries table
    UPDATE deliveries SET
        status = 'completed',
        completed_at = v_now,
        updated_at = v_now
    WHERE id = p_delivery_id;

    -- Update sales_orders table
    UPDATE sales_orders SET
        delivery_status = 'delivered',
        delivery_date = CURRENT_DATE,
        payment_status = 'debt',
        payment_method = 'debt',
        due_date = COALESCE(due_date, v_due_date),
        updated_at = v_now
    WHERE id = p_order_id;

    -- Update customer debt
    UPDATE customers SET
        total_debt = v_current_debt + p_amount,
        updated_at = v_now
    WHERE id = p_customer_id;

    -- Auto-create receivable (skip if already exists)
    INSERT INTO receivables (
        company_id, customer_id, reference_type, reference_id,
        reference_number, original_amount, paid_amount, write_off_amount,
        invoice_date, due_date, status, reminder_count
    )
    SELECT v_company_id, p_customer_id, 'sales_order', p_order_id,
           COALESCE(v_order_number, 'ORD-' || p_order_id::text),
           p_amount, 0, 0,
           CURRENT_DATE, v_due_date, 'open', 0
    WHERE NOT EXISTS (
        SELECT 1 FROM receivables WHERE reference_id = p_order_id
    );

    RETURN jsonb_build_object(
        'success', true,
        'new_debt', v_current_debt + p_amount,
        'receivable_created', true
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;
""")

print("✅ Updated complete_delivery_debt() with auto-receivable creation")

# Verify
cur.execute("""
    SELECT pg_get_function_arguments(oid) FROM pg_proc 
    WHERE proname = 'complete_delivery_debt'
""")
print(f"  Signature: ({cur.fetchone()[0]})")

cur.close()
conn.close()
