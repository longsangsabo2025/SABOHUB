#!/usr/bin/env python3
"""Create missing tables for Sales features"""
import psycopg2

POOLER_URL = "postgresql://postgres.dqddxowyikefqcdiioyh:Acookingoil123@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres"
conn = psycopg2.connect(POOLER_URL)
conn.autocommit = True
cur = conn.cursor()

print("=" * 60)
print("CREATING MISSING TABLES FOR SALES FEATURES")
print("=" * 60)

# 1. Sales Targets
print("\n1. Creating sales_targets table...")
cur.execute("""
CREATE TABLE IF NOT EXISTS sales_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Target period
    period_type VARCHAR(20) NOT NULL DEFAULT 'monthly', -- daily, weekly, monthly, quarterly, yearly
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Target metrics
    target_revenue DECIMAL(18,2) DEFAULT 0,
    target_orders INT DEFAULT 0,
    target_visits INT DEFAULT 0,
    target_new_customers INT DEFAULT 0,
    target_collections DECIMAL(18,2) DEFAULT 0,
    
    -- Actual (denormalized for performance)
    actual_revenue DECIMAL(18,2) DEFAULT 0,
    actual_orders INT DEFAULT 0,
    actual_visits INT DEFAULT 0,
    actual_new_customers INT DEFAULT 0,
    actual_collections DECIMAL(18,2) DEFAULT 0,
    
    -- Status
    status VARCHAR(20) DEFAULT 'active', -- active, completed, cancelled
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES employees(id)
);
""")
print("   ✅ sales_targets created")

# Create index
cur.execute("""
CREATE INDEX IF NOT EXISTS idx_sales_targets_employee ON sales_targets(employee_id);
CREATE INDEX IF NOT EXISTS idx_sales_targets_period ON sales_targets(period_start, period_end);
""")

# 2. Competitor Reports
print("\n2. Creating competitor_reports table...")
cur.execute("""
CREATE TABLE IF NOT EXISTS competitor_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    visit_id UUID REFERENCES customer_visits(id) ON DELETE SET NULL,
    reported_by UUID REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Competitor info
    competitor_name VARCHAR(200) NOT NULL,
    competitor_brand VARCHAR(200),
    
    -- Activity type
    activity_type VARCHAR(50) NOT NULL, -- promotion, new_product, price_change, merchandising, sampling, other
    
    -- Details
    description TEXT,
    observed_price DECIMAL(18,2),
    promotion_details TEXT,
    estimated_impact VARCHAR(20), -- low, medium, high
    
    -- Evidence
    photos TEXT[], -- Array of photo URLs
    
    -- Location
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    location_name VARCHAR(200),
    
    -- Metadata
    observed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
""")
print("   ✅ competitor_reports created")

cur.execute("""
CREATE INDEX IF NOT EXISTS idx_competitor_reports_company ON competitor_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_competitor_reports_customer ON competitor_reports(customer_id);
CREATE INDEX IF NOT EXISTS idx_competitor_reports_date ON competitor_reports(observed_at);
""")

# 3. Surveys
print("\n3. Creating surveys table...")
cur.execute("""
CREATE TABLE IF NOT EXISTS surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    
    -- Survey info
    title VARCHAR(200) NOT NULL,
    description TEXT,
    survey_type VARCHAR(50) DEFAULT 'customer', -- customer, product, market, satisfaction
    
    -- Questions (JSONB array)
    questions JSONB NOT NULL DEFAULT '[]',
    -- Example: [{"id": "q1", "type": "rating", "question": "How satisfied?", "options": [1,2,3,4,5]}]
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    start_date DATE,
    end_date DATE,
    
    -- Targets
    target_responses INT DEFAULT 0,
    current_responses INT DEFAULT 0,
    
    -- Audit
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES employees(id)
);
""")
print("   ✅ surveys created")

# 4. Survey Responses
print("\n4. Creating survey_responses table...")
cur.execute("""
CREATE TABLE IF NOT EXISTS survey_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    visit_id UUID REFERENCES customer_visits(id) ON DELETE SET NULL,
    respondent_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    
    -- Answers (JSONB object)
    answers JSONB NOT NULL DEFAULT '{}',
    -- Example: {"q1": 5, "q2": "Good quality", "q3": ["A", "B"]}
    
    -- Scoring
    total_score DECIMAL(5,2),
    
    -- Location
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    
    -- Metadata
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    duration_seconds INT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
""")
print("   ✅ survey_responses created")

cur.execute("""
CREATE INDEX IF NOT EXISTS idx_survey_responses_survey ON survey_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_responses_customer ON survey_responses(customer_id);
""")

# 5. Enable RLS policies
print("\n5. Setting up RLS policies...")
tables = ['sales_targets', 'competitor_reports', 'surveys', 'survey_responses']
for table in tables:
    cur.execute(f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;")
    
    # Drop existing policy if any
    cur.execute(f"DROP POLICY IF EXISTS {table}_company_policy ON {table};")
    
    # Create simple policy (allow all for now, can be refined later)
    cur.execute(f"""
        CREATE POLICY {table}_company_policy ON {table}
        FOR ALL USING (true);
    """)
    print(f"   ✅ RLS policy for {table}")

print("\n" + "=" * 60)
print("✅ ALL TABLES CREATED SUCCESSFULLY")
print("=" * 60)

conn.close()
