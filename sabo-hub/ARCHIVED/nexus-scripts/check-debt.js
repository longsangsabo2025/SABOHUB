import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env.local' });

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function check() {
  // Check customers with debt
  console.log('=== CUSTOMERS WITH DEBT ===');
  const { data: debtCustomers, error: e1 } = await supabase.from('customers').select('id, name, total_debt, company_id').gt('total_debt', 0);
  if (e1) console.log('Error:', e1.message);
  if (debtCustomers?.length) {
    debtCustomers.forEach(c => console.log('  ' + c.name + ': ' + c.total_debt + 'đ'));
  } else {
    console.log('  No customers with debt > 0');
  }
  
  // Check recent sales orders
  console.log('\n=== RECENT SALES ORDERS (last 10) ===');
  const { data: orders, error: e2 } = await supabase.from('sales_orders').select('id, order_number, payment_status, payment_method, delivery_status, customers(name)').order('created_at', { ascending: false }).limit(10);
  if (e2) console.log('Error:', e2.message);
  orders?.forEach(o => {
    console.log('  ' + o.order_number + ' - ' + (o.customers?.name || 'N/A') + ' - delivery: ' + o.delivery_status + ' - payment: ' + o.payment_status + ' - method: ' + o.payment_method);
  });
  
  // Check all customers of Odori
  console.log('\n=== ODORI CUSTOMERS (sample) ===');
  const { data: allCustomers, error: e3 } = await supabase.from('customers').select('id, name, total_debt').eq('company_id', '9f8921df-3760-44b5-9a7f-20f8484b0300').limit(10);
  if (e3) console.log('Error:', e3.message);
  allCustomers?.forEach(c => console.log('  ' + c.name + ': total_debt=' + c.total_debt));
  
  process.exit(0);
}

check();
