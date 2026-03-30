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

# Step 1: Create the recalculate function
print('=== Creating fn_recalculate_customer_debt function ===')
cur.execute("""
CREATE OR REPLACE FUNCTION public.fn_recalculate_customer_debt(p_customer_id uuid)
RETURNS numeric
LANGUAGE plpgsql
AS $function$
DECLARE
    v_so_debt NUMERIC := 0;
    v_recv_debt NUMERIC := 0;
    v_total NUMERIC := 0;
BEGIN
    -- Sum unpaid sales order balance
    SELECT COALESCE(SUM(total - COALESCE(paid_amount, 0)), 0)
    INTO v_so_debt
    FROM sales_orders
    WHERE customer_id = p_customer_id
      AND payment_status != 'paid'
      AND status != 'cancelled';

    -- Sum unpaid manual receivable balance (exclude sales_order-linked ones to avoid double count)
    SELECT COALESCE(SUM(
        GREATEST(0, original_amount - COALESCE(paid_amount, 0) - COALESCE(write_off_amount, 0))
    ), 0)
    INTO v_recv_debt
    FROM receivables
    WHERE customer_id = p_customer_id
      AND reference_type = 'manual'
      AND status != 'paid';

    v_total := v_so_debt + v_recv_debt;

    -- Update customer record
    UPDATE customers SET
        total_debt = v_total,
        updated_at = NOW()
    WHERE id = p_customer_id;

    RETURN v_total;
END;
$function$;
""")
print('  fn_recalculate_customer_debt created')

# Step 2: Create trigger function for sales_orders
print('=== Creating trigger function for sales_orders ===')
cur.execute("""
CREATE OR REPLACE FUNCTION public.trg_recalculate_debt_on_so_change()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    -- Recalculate for the affected customer
    IF TG_OP = 'DELETE' THEN
        PERFORM fn_recalculate_customer_debt(OLD.customer_id);
        RETURN OLD;
    ELSE
        PERFORM fn_recalculate_customer_debt(NEW.customer_id);
        -- If customer changed, also recalculate old customer
        IF TG_OP = 'UPDATE' AND OLD.customer_id IS DISTINCT FROM NEW.customer_id THEN
            PERFORM fn_recalculate_customer_debt(OLD.customer_id);
        END IF;
        RETURN NEW;
    END IF;
END;
$function$;
""")
print('  trg_recalculate_debt_on_so_change created')

# Step 3: Create trigger function for receivables
print('=== Creating trigger function for receivables ===')
cur.execute("""
CREATE OR REPLACE FUNCTION public.trg_recalculate_debt_on_recv_change()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM fn_recalculate_customer_debt(OLD.customer_id);
        RETURN OLD;
    ELSE
        PERFORM fn_recalculate_customer_debt(NEW.customer_id);
        IF TG_OP = 'UPDATE' AND OLD.customer_id IS DISTINCT FROM NEW.customer_id THEN
            PERFORM fn_recalculate_customer_debt(OLD.customer_id);
        END IF;
        RETURN NEW;
    END IF;
END;
$function$;
""")
print('  trg_recalculate_debt_on_recv_change created')

# Step 4: Create triggers (drop if exists first)
print('=== Creating triggers ===')

# Sales orders trigger
cur.execute("DROP TRIGGER IF EXISTS trg_so_recalculate_debt ON sales_orders")
cur.execute("""
CREATE TRIGGER trg_so_recalculate_debt
    AFTER INSERT OR UPDATE OF total, paid_amount, payment_status, status, customer_id
    OR DELETE ON sales_orders
    FOR EACH ROW
    EXECUTE FUNCTION trg_recalculate_debt_on_so_change()
""")
print('  trg_so_recalculate_debt on sales_orders created')

# Receivables trigger
cur.execute("DROP TRIGGER IF EXISTS trg_recv_recalculate_debt ON receivables")
cur.execute("""
CREATE TRIGGER trg_recv_recalculate_debt
    AFTER INSERT OR UPDATE OF original_amount, paid_amount, write_off_amount, status, customer_id
    OR DELETE ON receivables
    FOR EACH ROW
    EXECUTE FUNCTION trg_recalculate_debt_on_recv_change()
""")
print('  trg_recv_recalculate_debt on receivables created')

# Step 5: Fix sync_payment_to_receivables to use recalculate instead of simple subtraction
print('=== Updating sync_payment_to_receivables to use recalculate ===')
cur.execute("""
CREATE OR REPLACE FUNCTION public.sync_payment_to_receivables()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    v_remaining NUMERIC;
    v_rec RECORD;
    v_alloc NUMERIC;
    v_balance NUMERIC;
BEGIN
    v_remaining := NEW.amount;

    -- Allocate payment to oldest unpaid receivables for this customer
    FOR v_rec IN
        SELECT id, original_amount, paid_amount, COALESCE(write_off_amount, 0) as write_off_amount,
               (original_amount - paid_amount - COALESCE(write_off_amount, 0)) as outstanding
        FROM receivables
        WHERE customer_id = NEW.customer_id
          AND company_id = NEW.company_id
          AND status IN ('open', 'overdue', 'partial')
          AND (original_amount - paid_amount - COALESCE(write_off_amount, 0)) > 0
        ORDER BY due_date ASC, created_at ASC
    LOOP
        EXIT WHEN v_remaining <= 0;

        v_balance := v_rec.original_amount - v_rec.paid_amount - v_rec.write_off_amount;
        v_alloc := LEAST(v_remaining, v_balance);

        IF v_alloc <= 0 THEN
            CONTINUE;
        END IF;

        BEGIN
            INSERT INTO payment_allocations (payment_id, receivable_id, amount)
            VALUES (NEW.id, v_rec.id, v_alloc);
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        UPDATE receivables SET
            paid_amount = LEAST(original_amount - COALESCE(write_off_amount, 0), paid_amount + v_alloc),
            last_payment_date = CURRENT_DATE,
            status = CASE
                WHEN LEAST(original_amount - COALESCE(write_off_amount, 0), paid_amount + v_alloc)
                     >= original_amount - COALESCE(write_off_amount, 0) THEN 'paid'
                ELSE 'partial'
            END,
            updated_at = NOW()
        WHERE id = v_rec.id;

        v_remaining := v_remaining - v_alloc;
    END LOOP;

    -- Use proper recalculation instead of simple subtraction
    PERFORM fn_recalculate_customer_debt(NEW.customer_id);

    RETURN NEW;
END;
$function$;
""")
print('  sync_payment_to_receivables updated')

# Step 6: Run one-time sync for ALL customers
print()
print('=== SYNCING ALL CUSTOMER DEBTS ===')
cur.execute("""
    SELECT c.id, c.name, c.total_debt as old_debt,
           fn_recalculate_customer_debt(c.id) as new_debt
    FROM customers c
    ORDER BY c.name
""")
synced = 0
changed = 0
for r in cur.fetchall():
    old_debt = r[2] or 0
    new_debt = r[3] or 0
    synced += 1
    if abs(new_debt - old_debt) > 1:
        changed += 1
        print(f'  UPDATED {r[1]}: {old_debt:,.0f} -> {new_debt:,.0f}')

print(f'  Synced {synced} customers, {changed} updated')

# Verify
print()
print('=== VERIFICATION ===')
cur.execute("SELECT SUM(total_debt) FROM customers WHERE total_debt > 0")
total = cur.fetchone()[0]
print(f'  Total customers.total_debt: {total:,.0f}')

cur.execute("SELECT COUNT(*) FROM customers WHERE total_debt > 0")
count = cur.fetchone()[0]
print(f'  Customers with debt > 0: {count}')

conn.commit()
print()
print('=== ALL DONE - COMMITTED ===')
conn.close()
