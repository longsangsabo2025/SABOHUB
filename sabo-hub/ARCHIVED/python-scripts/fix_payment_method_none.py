import psycopg2, os
from dotenv import load_dotenv

load_dotenv('sabohub-automation/.env')
url = os.getenv('DATABASE_URL')

conn = psycopg2.connect(url)
cur = conn.cursor()

# 1. Fix sales_orders.payment_method 'None' string -> NULL
cur.execute("UPDATE sales_orders SET payment_method = NULL WHERE payment_method = 'None'")
print(f"sales_orders.payment_method: {cur.rowcount} rows fixed (None -> NULL)")

# 2. Fix customer_payments.payment_method 'None' string -> NULL
cur.execute("UPDATE customer_payments SET payment_method = NULL WHERE payment_method = 'None'")
print(f"customer_payments.payment_method: {cur.rowcount} rows fixed (None -> NULL)")

conn.commit()

# Verify
print("\n--- Verification ---")
cur.execute("SELECT payment_method, count(*) FROM sales_orders GROUP BY payment_method ORDER BY count(*) DESC")
print("sales_orders.payment_method:", cur.fetchall())

cur.execute("SELECT payment_method, count(*) FROM customer_payments GROUP BY payment_method ORDER BY count(*) DESC")
print("customer_payments.payment_method:", cur.fetchall())

conn.close()
print("\nDone!")
