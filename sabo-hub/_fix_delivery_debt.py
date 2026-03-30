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

# Update complete_delivery_debt to remove manual total_debt update (trigger handles it)
cur.execute("""
CREATE OR REPLACE FUNCTION public.complete_delivery_debt(p_delivery_id uuid, p_order_id uuid, p_customer_id uuid, p_amount numeric)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
    v_now TIMESTAMPTZ := NOW();
    v_order_number TEXT;
    v_company_id UUID;
    v_due_date DATE;
    v_payment_terms INT;
    v_new_debt NUMERIC;
BEGIN
    SELECT COALESCE(payment_terms, 30), company_id
    INTO v_payment_terms, v_company_id
    FROM customers WHERE id = p_customer_id;

    SELECT order_number, COALESCE(due_date, CURRENT_DATE + v_payment_terms)
    INTO v_order_number, v_due_date
    FROM sales_orders WHERE id = p_order_id;

    UPDATE deliveries SET
        status = 'completed',
        completed_at = v_now,
        updated_at = v_now
    WHERE id = p_delivery_id;

    -- Update sales_orders (trigger trg_so_recalculate_debt will auto-update customer total_debt)
    UPDATE sales_orders SET
        delivery_status = 'delivered',
        delivery_date = CURRENT_DATE,
        payment_status = 'debt',
        payment_method = 'debt',
        due_date = COALESCE(due_date, v_due_date),
        updated_at = v_now
    WHERE id = p_order_id;

    -- NOTE: No manual UPDATE customers SET total_debt = ... needed
    -- The trigger trg_so_recalculate_debt automatically recalculates total_debt

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

    -- Get the recalculated debt (trigger already updated it)
    SELECT total_debt INTO v_new_debt FROM customers WHERE id = p_customer_id;

    RETURN jsonb_build_object(
        'success', true,
        'new_debt', COALESCE(v_new_debt, 0),
        'receivable_created', true
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;
""")
print('complete_delivery_debt updated')

# Re-add 'debt' to finance_dashboard_page filter since it IS a valid payment_status
# (was incorrectly removed in previous session Bug #25)
# Will fix this in the dart file separately

conn.commit()
print('COMMITTED')
conn.close()
