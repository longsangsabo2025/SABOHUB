-- Add expo_push_token column to users table for push notifications
-- Run this in Supabase SQL Editor

-- Add expo_push_token column if not exists
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS expo_push_token TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_expo_push_token 
ON users(expo_push_token) 
WHERE expo_push_token IS NOT NULL;

-- Add column comment
COMMENT ON COLUMN users.expo_push_token IS 'Expo push notification token for mobile app';

-- Verify the migration
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name = 'expo_push_token';
