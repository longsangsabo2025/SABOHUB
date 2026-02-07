
import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config();

const connectionString = process.env.VITE_SUPABASE_POOLER_URL;

if (!connectionString) {
  console.error('Error: VITE_SUPABASE_POOLER_URL is not defined in .env');
  process.exit(1);
}

const client = new pg.Client({
  connectionString: connectionString,
  ssl: {
    rejectUnauthorized: false
  }
});

async function deploy() {
  try {
    await client.connect();
    console.log('Connected to database via pooler.');

    const sqlPath = path.join(__dirname, 'get_daily_reports_rpc.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('Executing SQL to deploy get_daily_reports RPC...');
    await client.query(sql);
    
    console.log('RPC deployed successfully!');
  } catch (err) {
    console.error('Error deploying RPC:', err);
  } finally {
    await client.end();
  }
}

deploy();
