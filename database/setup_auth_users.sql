-- ================================================================
-- SABOHUB - User Authentication & Profile Setup
-- ================================================================
-- This script sets up the users table, RLS policies, and triggers
-- to automatically create user profiles after signup
-- Run this in Supabase SQL Editor
-- ================================================================

-- 1. Create users table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')),
    phone TEXT DEFAULT '',
    avatar_url TEXT,
    company_id UUID,
    branch_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_branch_id ON public.users(branch_id);

-- 3. Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. Drop existing policies if any
DROP POLICY IF EXISTS "Users can insert their own profile during signup" ON public.users;
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can do anything" ON public.users;

-- 5. RLS Policy: Allow users to insert their own profile during signup
CREATE POLICY "Users can insert their own profile during signup"
    ON public.users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 6. RLS Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);

-- 7. RLS Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 8. RLS Policy: Service role (for admin operations)
CREATE POLICY "Service role can do anything"
    ON public.users
    FOR ALL
    USING (auth.role() = 'service_role');

-- 9. Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert user profile with data from auth.users metadata
    INSERT INTO public.users (
        id, 
        name, 
        email, 
        role, 
        phone
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
        NEW.email,
        UPPER(COALESCE(NEW.raw_user_meta_data->>'role', 'STAFF')),
        COALESCE(NEW.raw_user_meta_data->>'phone', '')
    );
    
    RETURN NEW;
END;
$$;

-- 10. Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 11. Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 12. Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- ================================================================
-- VERIFICATION QUERIES (run these to check setup)
-- ================================================================
-- Check if users table exists:
-- SELECT * FROM information_schema.tables WHERE table_name = 'users';

-- Check RLS policies:
-- SELECT * FROM pg_policies WHERE tablename = 'users';

-- Check triggers:
-- SELECT * FROM information_schema.triggers WHERE event_object_table = 'users';

-- ================================================================
-- SUCCESS! You can now test signup flow
-- ================================================================
