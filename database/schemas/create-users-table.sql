-- ========================================
-- SABOHUB - CREATE USERS TABLE
-- ========================================
-- Chạy script này trong Supabase SQL Editor để tạo bảng users
-- Dashboard > SQL Editor > New Query > Paste & Run

-- 1. Tạo bảng users
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'STAFF' CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF', 'TECHNICAL')),
  phone TEXT,
  avatar_url TEXT,
  store_id UUID REFERENCES public.stores(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id)
);

-- 2. Tạo indexes để tăng performance
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_store_id ON public.users(store_id);

-- 3. Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. Tạo RLS Policies

-- Policy: Users có thể đọc profile của mình
CREATE POLICY "Users can read their own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Users có thể update profile của mình
CREATE POLICY "Users can update their own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Policy: CEO và MANAGER có thể xem tất cả users
CREATE POLICY "CEO and MANAGER can view all users"
  ON public.users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
      AND role IN ('CEO', 'MANAGER')
    )
  );

-- Policy: CEO có thể update bất kỳ user nào
CREATE POLICY "CEO can update any user"
  ON public.users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
      AND role = 'CEO'
    )
  );

-- Policy: Cho phép insert user mới (cần cho signup)
CREATE POLICY "Allow user creation during signup"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 5. Tạo function để tự động tạo user profile khi signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'STAFF')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Tạo trigger để tự động chạy function trên
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. Tạo function để update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Tạo trigger cho updated_at
DROP TRIGGER IF EXISTS set_updated_at ON public.users;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ========================================
-- VERIFICATION QUERIES
-- ========================================
-- Chạy các query này để verify table đã tạo thành công:

-- Check table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'users'
ORDER BY ordinal_position;

-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'users';

-- Check RLS status
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'users';

-- Check policies
SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users';

-- ========================================
-- SUCCESS!
-- ========================================
-- Nếu không có lỗi, bảng users đã được tạo thành công!
-- Bây giờ bạn có thể:
-- 1. Tạo users trong Authentication > Users
-- 2. User profile sẽ tự động được tạo trong bảng users
-- 3. App có thể query và update user data