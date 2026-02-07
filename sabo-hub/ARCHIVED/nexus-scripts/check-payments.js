import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const s = createClient(process.env.VITE_SUPABASE_URL, process.env.VITE_SUPABASE_ANON_KEY);

(async () => {
  // Check customer_payments table
  const { data: payments, error: err1 } = await s.from('customer_payments').select('*').limit(10);
  console.log('=== customer_payments ===');
  console.log('Data:', payments);
  if (err1) console.log('Error:', err1.message);
  
  // Check sales_orders with debt payment method
  const { data: debtOrders, error: err2 } = await s
    .from('sales_orders')
    .select('id, order_number, total, payment_method, customer_id, status, created_at, customers(name)')
    .eq('payment_method', 'debt');
  
  console.log('\n=== sales_orders với payment_method = debt ===');
  console.log(debtOrders);
  if (err2) console.log('Error:', err2.message);
  
  // Check deliveries table
  const { data: deliveries, error: err3 } = await s
    .from('deliveries')
    .select('id, status, payment_method, created_at')
    .limit(10);
  
  console.log('\n=== deliveries (10 records) ===');
  console.log(deliveries);
  if (err3) console.log('Error:', err3.message);
})();
