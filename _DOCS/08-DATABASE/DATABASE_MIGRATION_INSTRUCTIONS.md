# Employee Onboarding - Database Migration

## 🎯 What This Does
Adds invite token columns to the `users` table to support invite-based employee onboarding.

## 📋 SQL to Run in Supabase SQL Editor

```sql
-- Add invite token columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS invite_token TEXT,
ADD COLUMN IF NOT EXISTS invite_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ;

-- Create index for faster invite token lookups
CREATE INDEX IF NOT EXISTS idx_users_invite_token ON public.users(invite_token) WHERE invite_token IS NOT NULL;

-- Add comments
COMMENT ON COLUMN public.users.invite_token IS 'Unique token for employee invitation link';
COMMENT ON COLUMN public.users.invite_expires_at IS 'Expiration time for invite link (typically 7 days)';
COMMENT ON COLUMN public.users.invited_at IS 'When the invitation was created';
COMMENT ON COLUMN public.users.onboarded_at IS 'When the employee completed onboarding';
```

## ✅ How to Apply

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the SQL above
4. Click **Run** button
5. Done! ✨

## 🔍 Verify Migration

Run this query to check if columns were added:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('invite_token', 'invite_expires_at', 'invited_at', 'onboarded_at');
```

You should see 4 rows returned.
