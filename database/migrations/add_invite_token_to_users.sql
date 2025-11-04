-- Add invite token columns to users table for employee onboarding
-- Run this migration on your Supabase database

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS invite_token UUID DEFAULT gen_random_uuid(),
ADD COLUMN IF NOT EXISTS invite_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ;

-- Create index for faster invite token lookups
CREATE INDEX IF NOT EXISTS idx_users_invite_token ON public.users(invite_token) WHERE invite_token IS NOT NULL;

-- Comment
COMMENT ON COLUMN public.users.invite_token IS 'Unique token for employee invitation link';
COMMENT ON COLUMN public.users.invite_expires_at IS 'Expiration time for invite link (typically 7 days)';
COMMENT ON COLUMN public.users.invited_at IS 'When the invitation was created';
COMMENT ON COLUMN public.users.onboarded_at IS 'When the employee completed onboarding';
