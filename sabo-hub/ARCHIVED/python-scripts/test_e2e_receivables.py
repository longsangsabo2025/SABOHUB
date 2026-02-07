"""
E2E TEST: Full Công nợ (Receivables) flow
Tests: Order delivery → auto-receivable → Payment → auto-allocation → Status update
"""
import psycopg2
from datetime import datetime, timedelta
import uuid

DB = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(DB)
conn.autocommit = True
cur = conn.cursor()

PASS = "✅"
FAIL = "❌"
results = []

def test(name, condition, detail=""):
    status = PASS if condition else FAIL
    results.append((name, condition))
    print(f"  {status} {name}" + (f" ({detail})" if detail else ""))

print("=" * 60)
print("E2E TEST: CÔNG NỢ (RECEIVABLES) SYSTEM")
print("=" * 60)

# Get a company and customer for testing
cur.execute("SELECT id FROM companies LIMIT 1")
company_id = cur.fetchone()[0]
cur.execute("SELECT id, name FROM customers WHERE company_id = %s LIMIT 1", (company_id,))
cust = cur.fetchone()
customer_id, customer_name = cust[0], cust[1]
print(f"\nTest company: {company_id}")
print(f"Test customer: {customer_name} ({customer_id})")

# Get a warehouse
cur.execute("SELECT id FROM warehouses WHERE company_id = %s LIMIT 1", (company_id,))
warehouse_row = cur.fetchone()
warehouse_id = warehouse_row[0] if warehouse_row else None
print(f"Test warehouse: {warehouse_id}")

# Get a sale user
cur.execute("SELECT id FROM employees WHERE company_id = %s LIMIT 1", (company_id,))
emp_row = cur.fetchone()
sale_id = emp_row[0] if emp_row else None

# =========================================================
# TEST 1: Trigger — complete_delivery_debt() creates receivable
# =========================================================
print(f"\n--- TEST 1: Auto-create receivable on delivery ---")

# Create a test order
test_order_id = str(uuid.uuid4())
test_order_num = f"TEST-E2E-{datetime.now().strftime('%H%M%S')}"
cur.execute("""
    INSERT INTO sales_orders (
        id, company_id, customer_id, order_number, order_date,
        total, subtotal, status, delivery_status, payment_status,
        warehouse_id, sale_id
    ) VALUES (%s, %s, %s, %s, CURRENT_DATE, 500000, 500000, 
              'confirmed', 'pending', 'unpaid', %s, %s)
""", (test_order_id, company_id, customer_id, test_order_num, warehouse_id, sale_id))
test("Created test order", True, test_order_num)

# Now call complete_delivery_debt to simulate delivery completion
# Function signature: (p_delivery_id uuid, p_order_id uuid, p_customer_id uuid, p_amount numeric)
try:
    test_delivery_id = str(uuid.uuid4())
    cur.execute("SELECT complete_delivery_debt(%s::uuid, %s::uuid, %s::uuid, %s::numeric)", 
                (test_delivery_id, test_order_id, customer_id, 500000))
    result = cur.fetchone()
    test("complete_delivery_debt() executed", True, str(result))
except Exception as e:
    test("complete_delivery_debt() executed", False, str(e))

# Check if receivable was created
cur.execute("""
    SELECT id, original_amount, paid_amount, status, due_date
    FROM receivables 
    WHERE reference_id = %s
""", (test_order_id,))
rec = cur.fetchone()
test("Receivable auto-created", rec is not None)
if rec:
    rec_id = rec[0]
    test("Receivable amount = 500000", float(rec[1]) == 500000, f"got {rec[1]}")
    test("Receivable paid_amount = 0", float(rec[2]) == 0)
    test("Receivable status = 'open'", rec[3] == 'open', f"got '{rec[3]}'")
    test("Receivable has due_date", rec[4] is not None, str(rec[4]))
else:
    rec_id = None
    test("Receivable amount check", False, "no receivable found")

# =========================================================
# TEST 2: Payment trigger — sync_payment_to_receivables
# =========================================================
print(f"\n--- TEST 2: Auto-allocate payment to receivables ---")

if rec_id:
    # Create a partial payment
    test_payment_id = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO customer_payments (
            id, company_id, customer_id, amount, payment_date, payment_method
        ) VALUES (%s, %s, %s, 200000, CURRENT_DATE, 'cash')
    """, (test_payment_id, company_id, customer_id))
    test("Created partial payment (200,000)", True)
    
    # Check if trigger allocated the payment
    cur.execute("""
        SELECT id, amount FROM payment_allocations 
        WHERE payment_id = %s
    """, (test_payment_id,))
    allocs = cur.fetchall()
    test("Payment allocation created by trigger", len(allocs) > 0, f"{len(allocs)} allocations")
    
    # Check receivable was updated
    cur.execute("""
        SELECT paid_amount, status 
        FROM receivables WHERE id = %s
    """, (rec_id,))
    rec_updated = cur.fetchone()
    if rec_updated:
        test("Receivable paid_amount updated", float(rec_updated[0]) > 0, f"paid={rec_updated[0]}")
        test("Receivable status = 'partial'", rec_updated[1] == 'partial', f"got '{rec_updated[1]}'")
    
    # Full payment to close it
    test_payment_id2 = str(uuid.uuid4())
    cur.execute("""
        INSERT INTO customer_payments (
            id, company_id, customer_id, amount, payment_date, payment_method
        ) VALUES (%s, %s, %s, 300000, CURRENT_DATE, 'transfer')
    """, (test_payment_id2, company_id, customer_id))
    test("Created remaining payment (300,000)", True)
    
    cur.execute("SELECT paid_amount, status FROM receivables WHERE id = %s", (rec_id,))
    rec_final = cur.fetchone()
    if rec_final:
        test("Receivable fully paid (500,000)", float(rec_final[0]) >= 500000, f"paid={rec_final[0]}")
        test("Receivable status = 'paid'", rec_final[1] == 'paid', f"got '{rec_final[1]}'")

# =========================================================
# TEST 3: Overdue detection
# =========================================================
print(f"\n--- TEST 3: Overdue detection ---")

# Create an order with past due date
test_order_id2 = str(uuid.uuid4())
test_order_num2 = f"TEST-OVERDUE-{datetime.now().strftime('%H%M%S')}"
past_due = (datetime.now() - timedelta(days=35)).date()

cur.execute("""
    INSERT INTO sales_orders (
        id, company_id, customer_id, order_number, order_date,
        total, subtotal, status, delivery_status, payment_status, due_date,
        warehouse_id, sale_id
    ) VALUES (%s, %s, %s, %s, %s, 100000, 100000,
              'completed', 'delivered', 'unpaid', %s, %s, %s)
""", (test_order_id2, company_id, customer_id, test_order_num2, 
      (datetime.now() - timedelta(days=40)).date(), past_due, warehouse_id, sale_id))

# Create receivable with past due date
cur.execute("""
    INSERT INTO receivables (
        company_id, customer_id, reference_type, reference_id,
        reference_number, original_amount, paid_amount, write_off_amount,
        invoice_date, due_date, status, reminder_count
    ) VALUES (%s, %s, 'sales_order', %s, %s, 100000, 0, 0, %s, %s, 'open', 0)
""", (company_id, customer_id, test_order_id2, test_order_num2,
      (datetime.now() - timedelta(days=40)).date(), past_due))

# Run overdue update
cur.execute("SELECT update_overdue_receivables()")

cur.execute("""
    SELECT status FROM receivables WHERE reference_id = %s
""", (test_order_id2,))
overdue_status = cur.fetchone()
test("Past-due receivable marked 'overdue'", 
     overdue_status and overdue_status[0] == 'overdue',
     f"got '{overdue_status[0] if overdue_status else None}'")

# Check aging view
cur.execute("""
    SELECT aging_bucket, days_overdue FROM v_receivables_aging 
    WHERE receivable_id = (SELECT id FROM receivables WHERE reference_id = %s)
""", (test_order_id2,))
aging = cur.fetchone()
if aging:
    test("Aging bucket correct", aging[0] in ('1-30', '31-60'), f"bucket={aging[0]}, days={aging[1]}")
else:
    test("Aging bucket correct", False, "not found in aging view")

# =========================================================
# TEST 4: Sales blocking check (simulated)
# =========================================================
print(f"\n--- TEST 4: Sales blocking query ---")
cur.execute("""
    SELECT id, original_amount - paid_amount as balance, due_date
    FROM receivables 
    WHERE customer_id = %s AND status = 'overdue'
    LIMIT 5
""", (customer_id,))
overdue_recs = cur.fetchall()
test("Overdue query returns results for blocking", len(overdue_recs) > 0, f"{len(overdue_recs)} overdue")

# =========================================================
# CLEANUP: Remove test data
# =========================================================
print(f"\n--- CLEANUP ---")
cur.execute("DELETE FROM payment_allocations WHERE receivable_id IN (SELECT id FROM receivables WHERE reference_id IN (%s, %s))", 
            (test_order_id, test_order_id2))
if rec_id:
    cur.execute("DELETE FROM payment_allocations WHERE payment_id IN (%s, %s)", (test_payment_id, test_payment_id2))
    cur.execute("DELETE FROM customer_payments WHERE id IN (%s, %s)", (test_payment_id, test_payment_id2))
cur.execute("DELETE FROM receivables WHERE reference_id IN (%s, %s)", (test_order_id, test_order_id2))
try:
    cur.execute("DELETE FROM deliveries WHERE id = %s", (test_delivery_id,))
except:
    pass
cur.execute("DELETE FROM sales_orders WHERE id IN (%s, %s)", (test_order_id, test_order_id2))
print("  Test data cleaned up")

# =========================================================
# SUMMARY
# =========================================================
print(f"\n{'=' * 60}")
passed = sum(1 for _, ok in results if ok)
total = len(results)
print(f"RESULTS: {passed}/{total} tests passed")
if passed == total:
    print(f"{PASS} ALL TESTS PASSED!")
else:
    print(f"{FAIL} {total - passed} tests FAILED")
    for name, ok in results:
        if not ok:
            print(f"  {FAIL} {name}")
print("=" * 60)

cur.close()
conn.close()
