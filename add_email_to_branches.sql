-- Add email column to branches table
-- This column was referenced in the code but missing from the database schema

ALTER TABLE public.branches 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.branches.email IS 'Branch contact email address';
