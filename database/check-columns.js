const { Client } = require('pg');

async function checkColumns() {
  const client = new Client({
    connectionString: process.env.SUPABASE_CONNECTION_STRING,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    const tables = ['users', 'tasks', 'tables', 'orders', 'products', 'inventory_items'];
    
    for (const table of tables) {
      console.log(`\n📊 Table: ${table}`);
      console.log('═══════════════════════════════');
      
      const result = await client.query(`
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' 
        AND table_name = $1
        AND column_name IN ('store_id', 'branch_id', 'company_id')
      `, [table]);
      
      if (result.rows.length > 0) {
        result.rows.forEach(row => console.log('  ✅', row.column_name));
      } else {
        console.log('  ❌ No store_id/branch_id/company_id');
      }
    }
    
  } finally {
    await client.end();
  }
}

checkColumns();
