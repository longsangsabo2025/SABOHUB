# ============================================================================
# 🚀 SABOHUB DATABASE SETUP WITH TRANSACTION POOLER
# ============================================================================

Write-Host "🔄 Setting up SaboHub Database with Transaction Pooler..." -ForegroundColor Cyan

# Load environment variables
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "❌ .env file not found" -ForegroundColor Red
    exit 1
}

$supabaseUrl = $env:SUPABASE_URL
$connectionString = $env:SUPABASE_CONNECTION_STRING

if (-not $supabaseUrl -or -not $connectionString) {
    Write-Host "❌ Missing Supabase configuration in .env" -ForegroundColor Red
    exit 1
}

Write-Host "🏢 Supabase URL: $supabaseUrl" -ForegroundColor Yellow
Write-Host "🔗 Using Transaction Pooler for optimal performance" -ForegroundColor Green

# Create database tables using PostgreSQL
Write-Host "📊 Applying database migration..." -ForegroundColor Cyan

# SQL Script content to apply
$sqlScript = @"
-- ============================================================================
-- 🚀 SABOHUB CORE TABLES MIGRATION
-- ============================================================================

-- 1. COMPANIES TABLE
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  business_type TEXT NOT NULL DEFAULT 'billiards' CHECK (business_type IN (
    'billiards', 'restaurant', 'cafe', 'retail', 'service', 'other'
  )),
  address TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  tax_code TEXT,
  monthly_revenue DECIMAL(15,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. STORES TABLE
CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT,
  address TEXT NOT NULL,
  phone TEXT,
  manager_id UUID,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'MAINTENANCE')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_id, code)
);

-- 3. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  full_name TEXT NOT NULL,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'STAFF' CHECK (role IN ('CEO', 'MANAGER', 'SHIFT_LEADER', 'STAFF')),
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLES TABLE
CREATE TABLE IF NOT EXISTS tables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  table_type TEXT NOT NULL DEFAULT 'standard' CHECK (table_type IN ('standard', 'vip', 'premium')),
  hourly_rate DECIMAL(10,2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'reserved', 'maintenance')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, name)
);

-- 5. TASKS TABLE
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ACTIVITY_LOGS TABLE
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  store_id UUID REFERENCES stores(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  description TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key constraints
ALTER TABLE stores 
ADD CONSTRAINT IF NOT EXISTS fk_stores_manager 
FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_companies_business_type ON companies(business_type);
CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(is_active);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_stores_company ON stores(company_id);
CREATE INDEX IF NOT EXISTS idx_tables_store ON tables(store_id);
CREATE INDEX IF NOT EXISTS idx_tasks_company ON tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created ON activity_logs(created_at DESC);

-- Insert sample data
INSERT INTO companies (name, business_type, address, phone, monthly_revenue) VALUES
  ('Quán Bida Diamond', 'billiards', '123 Nguyễn Huệ, Q1, HCM', '0901234567', 85000000),
  ('Bida Royal', 'billiards', '456 Lê Lợi, Q3, HCM', '0912345678', 92000000),
  ('Golden Billiards', 'billiards', '789 Trần Hưng Đạo, Q5, HCM', '0923456789', 76000000)
ON CONFLICT (name) DO NOTHING;
"@

# Save SQL to file
$sqlScript | Out-File -FilePath "database/temp_migration.sql" -Encoding UTF8

Write-Host "💾 SQL migration saved to database/temp_migration.sql" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Open Supabase Dashboard: $supabaseUrl" -ForegroundColor White
Write-Host "2. Go to SQL Editor" -ForegroundColor White
Write-Host "3. Copy and run the SQL from: database/temp_migration.sql" -ForegroundColor White
Write-Host ""
Write-Host "Or use psql directly:" -ForegroundColor Yellow
Write-Host "psql `"$connectionString`" -f database/temp_migration.sql" -ForegroundColor White
Write-Host ""

# Try to open Supabase dashboard
try {
    Start-Process "$supabaseUrl"
    Write-Host "🌐 Opening Supabase Dashboard..." -ForegroundColor Green
} catch {
    Write-Host "⚠️ Could not open browser automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Database setup script completed!" -ForegroundColor Green
Write-Host "🎯 Ready for high-performance SaboHub Flutter app!" -ForegroundColor Cyan