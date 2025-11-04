import psycopg2

# Database configuration
DB_HOST = "aws-1-ap-southeast-2.pooler.supabase.com"
DB_PORT = 6543
DB_NAME = "postgres"
DB_USER = "postgres.dqddxowyikefqcdiioyh"
DB_PASSWORD = "Acookingoil123"

# SQL to create auth trigger
AUTH_TRIGGER_SQL = """
-- Auth hook to handle new user registration
-- This will automatically create a user profile in public.users when someone signs up

-- 1. Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    full_name,
    phone,
    role,
    is_active,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'STAFF'),
    true,
    NOW(),
    NOW()
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger on auth.users for INSERT
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
"""

try:
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
    
    cursor = conn.cursor()
    
    print("🔧 Creating auth trigger...")
    cursor.execute(AUTH_TRIGGER_SQL)
    conn.commit()
    
    print("✅ Auth trigger created successfully!")
    
    # Verify trigger was created
    cursor.execute("""
        SELECT trigger_name, event_manipulation, action_timing
        FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    """)
    
    result = cursor.fetchone()
    if result:
        print(f"🔗 Trigger verified: {result[0]} - {result[2]} {result[1]}")
    else:
        print("❌ Trigger not found after creation")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"❌ Error: {e}")