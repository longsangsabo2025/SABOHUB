import psycopg2
conn = psycopg2.connect(
    host='aws-1-ap-southeast-2.pooler.supabase.com', 
    port=6543, 
    dbname='postgres', 
    user='postgres.dqddxowyikefqcdiioyh', 
    password='Acookingoil123'
)
cur = conn.cursor()

# Create projects table
print("Creating projects table...")
cur.execute('''
CREATE TABLE IF NOT EXISTS projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    priority VARCHAR(20) DEFAULT 'medium',
    start_date DATE,
    end_date DATE,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    manager_id UUID REFERENCES employees(id) ON DELETE SET NULL,
    created_by UUID REFERENCES employees(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
''')
print("✓ projects table created")

# Create sub_projects table
print("Creating sub_projects table...")
cur.execute('''
CREATE TABLE IF NOT EXISTS sub_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active',
    priority VARCHAR(20) DEFAULT 'medium',
    start_date DATE,
    end_date DATE,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    assigned_to UUID REFERENCES employees(id) ON DELETE SET NULL,
    created_by UUID REFERENCES employees(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
''')
print("✓ sub_projects table created")

# Create indexes
print("Creating indexes...")
cur.execute('CREATE INDEX IF NOT EXISTS idx_projects_company ON projects(company_id);')
cur.execute('CREATE INDEX IF NOT EXISTS idx_projects_manager ON projects(manager_id);')
cur.execute('CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);')
cur.execute('CREATE INDEX IF NOT EXISTS idx_sub_projects_project ON sub_projects(project_id);')
cur.execute('CREATE INDEX IF NOT EXISTS idx_sub_projects_assigned ON sub_projects(assigned_to);')
print("✓ indexes created")

# Insert sample project for Quán bida SABO
print("\nInserting sample project...")
cur.execute('''
INSERT INTO projects (company_id, name, description, status, priority, progress)
SELECT 
    'd6ff05cc-9440-4e8e-985a-eb6219dec3ec',
    'Sản xuất 30 Video YouTube — SABO Billiards',
    'Tạo nội dung video cho kênh YouTube SABO Billiards',
    'active',
    'high',
    35
WHERE NOT EXISTS (
    SELECT 1 FROM projects WHERE name LIKE '%30 Video YouTube%'
)
RETURNING id;
''')
project_result = cur.fetchone()
if project_result:
    project_id = project_result[0]
    print(f"✓ Project created: {project_id}")
    
    # Insert sub-projects
    sub_projects = [
        ('Kịch bản Video 1-10', 'Viết kịch bản cho 10 video đầu tiên', 'completed', 100),
        ('Quay Video 1-10', 'Quay 10 video đầu tiên', 'in_progress', 60),
        ('Edit Video 1-10', 'Dựng video 1-10', 'in_progress', 30),
        ('Kịch bản Video 11-20', 'Viết kịch bản cho video 11-20', 'planned', 0),
        ('Quay Video 11-20', 'Quay video 11-20', 'planned', 0),
    ]
    
    for name, desc, status, progress in sub_projects:
        cur.execute('''
        INSERT INTO sub_projects (project_id, name, description, status, progress)
        VALUES (%s, %s, %s, %s, %s)
        ''', (project_id, name, desc, status, progress))
    print(f"✓ Inserted {len(sub_projects)} sub-projects")
else:
    print("Project already exists, skipping sample data")

conn.commit()

# Verify
print("\n=== VERIFICATION ===")
cur.execute('SELECT id, name, status, progress FROM projects')
for r in cur.fetchall():
    print(f"Project: {r[1]} | Status: {r[2]} | Progress: {r[3]}%")

cur.execute('''
SELECT sp.name, sp.status, sp.progress, p.name as project_name
FROM sub_projects sp
JOIN projects p ON sp.project_id = p.id
''')
print("\nSub-projects:")
for r in cur.fetchall():
    print(f"  - {r[0]} | {r[1]} | {r[2]}%")

conn.close()
print("\n✅ Done!")
