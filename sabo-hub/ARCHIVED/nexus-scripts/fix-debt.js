import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL, 
  process.env.VITE_SUPABASE_ANON_KEY
);

async function fixDebt() {
  // Tìm các đơn có payment_method = 'debt' và delivery_status = 'delivered'
  const { data: debtOrders, error: ordersError } = await supabase
    .from('sales_orders')
    .select('id, order_number, customer_id, total, customers(name, total_debt)')
    .eq('payment_method', 'debt')
    .eq('delivery_status', 'delivered');

  if (ordersError) {
    console.error('Error fetching orders:', ordersError);
    return;
  }

  console.log(`Found ${debtOrders?.length || 0} debt orders`);

  for (const order of debtOrders || []) {
    const customerId = order.customer_id;
    const orderTotal = order.total || 0;
    const currentDebt = order.customers?.total_debt || 0;
    const newDebt = currentDebt + orderTotal;

    console.log(`\nOrder: ${order.order_number}`);
    console.log(`  Customer: ${order.customers?.name} (${customerId})`);
    console.log(`  Order total: ${orderTotal}`);
    console.log(`  Current debt: ${currentDebt} -> New debt: ${newDebt}`);

    // Update customer total_debt
    const { error: updateError } = await supabase
      .from('customers')
      .update({ 
        total_debt: newDebt,
        updated_at: new Date().toISOString()
      })
      .eq('id', customerId);

    if (updateError) {
      console.log(`  ❌ Error: ${updateError.message}`);
    } else {
      console.log(`  ✅ Updated successfully`);
    }
  }

  // Verify
  console.log('\n--- Verification ---');
  const { data: customers } = await supabase
    .from('customers')
    .select('name, total_debt')
    .gt('total_debt', 0);
  
  console.log(`Customers with debt: ${customers?.length || 0}`);
  customers?.forEach(c => console.log(`  ${c.name}: ${c.total_debt}`));
}

fixDebt();
