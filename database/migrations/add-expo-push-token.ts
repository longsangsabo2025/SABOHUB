/**
 * Add expo_push_token field to users table
 * Run this migration to store push tokens for notifications
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY; // Service key for admin access

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing environment variables');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function addExpoPushTokenColumn() {
  console.log('📊 Adding expo_push_token column to users table...\n');

  try {
    // Add column using raw SQL
    const { error } = await supabase.rpc('exec_sql', {
      sql: `
        -- Add expo_push_token column if not exists
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS expo_push_token TEXT;

        -- Add index for faster lookups
        CREATE INDEX IF NOT EXISTS idx_users_expo_push_token 
        ON users(expo_push_token) 
        WHERE expo_push_token IS NOT NULL;

        -- Add comment
        COMMENT ON COLUMN users.expo_push_token IS 'Expo push notification token';
      `,
    });

    if (error) {
      console.error('❌ Migration failed:', error);
      process.exit(1);
    }

    console.log('✅ Migration completed successfully!');
    console.log('\nChanges made:');
    console.log('  • Added expo_push_token column (TEXT, nullable)');
    console.log('  • Added index for faster lookups');
    console.log('  • Added column comment');
    console.log('\n📝 Next steps:');
    console.log('  1. Update app to save push token on login');
    console.log('  2. Test notification test screen');
    console.log('  3. Update daily-summary.ts to fetch token');
  } catch (error: any) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addExpoPushTokenColumn();
