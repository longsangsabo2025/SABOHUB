const { Client } = require('pg');
const path = require('path');

// Load environment variables from parent directory
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

if (!connectionString) {
    console.error('❌ SUPABASE_CONNECTION_STRING not found in .env');
    process.exit(1);
}

async function seedEmployeeData() {
    const client = new Client({
        connectionString: connectionString,
        ssl: {
            rejectUnauthorized: false
        }
    });

    try {
        console.log('🔄 Connecting to seed employee data...');
        await client.connect();
        console.log('✅ Connected to PostgreSQL');
        
        // First, get SABO Billiards company ID
        const companyResult = await client.query(`
            SELECT id, name FROM companies 
            WHERE name ILIKE '%sabo%' OR name ILIKE '%billiards%'
            ORDER BY created_at DESC
            LIMIT 1;
        `);
        
        if (companyResult.rows.length === 0) {
            console.log('⚠️ SABO Billiards company not found. Creating it...');
            
            // Create SABO Billiards company
            const createCompanyResult = await client.query(`
                INSERT INTO companies (name, business_type, address, phone, email, is_active)
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING id, name;
            `, [
                'SABO Billiards',
                'Entertainment',
                '123 Nguyễn Văn Linh, Q7, TP.HCM',
                '0909123456',
                'contact@sabobilliards.com',
                true
            ]);
            
            console.log('✅ Created company:', createCompanyResult.rows[0]);
            var companyId = createCompanyResult.rows[0].id;
        } else {
            var companyId = companyResult.rows[0].id;
            console.log('✅ Found company:', companyResult.rows[0]);
        }
        
        // Sample employees data
        const employees = [
            // CEO
            {
                email: 'ceo@sabobilliards.com',
                full_name: 'Nguyễn Minh CEO',
                role: 'CEO',
                phone: '0901111111'
            },
            // Managers
            {
                email: 'manager1@sabobilliards.com', 
                full_name: 'Trần Văn Manager',
                role: 'BRANCH_MANAGER',
                phone: '0902222222'
            },
            {
                email: 'manager2@sabobilliards.com',
                full_name: 'Lê Thị Manager',
                role: 'BRANCH_MANAGER', 
                phone: '0903333333'
            },
            // Shift Leaders
            {
                email: 'shift1@sabobilliards.com',
                full_name: 'Phạm Văn Shift Leader',
                role: 'SHIFT_LEADER',
                phone: '0904444444'
            },
            {
                email: 'shift2@sabobilliards.com',
                full_name: 'Hoàng Thị Shift Leader',
                role: 'SHIFT_LEADER',
                phone: '0905555555'
            },
            {
                email: 'shift3@sabobilliards.com',
                full_name: 'Vũ Minh Shift Leader',
                role: 'SHIFT_LEADER',
                phone: '0906666666'
            },
            // Staff Members
            {
                email: 'staff1@sabobilliards.com',
                full_name: 'Nguyễn Văn Staff',
                role: 'STAFF',
                phone: '0907777777'
            },
            {
                email: 'staff2@sabobilliards.com',
                full_name: 'Trần Thị Staff',
                role: 'STAFF',
                phone: '0908888888'
            },
            {
                email: 'staff3@sabobilliards.com',
                full_name: 'Lê Văn Staff',
                role: 'STAFF',
                phone: '0909999999'
            },
            {
                email: 'staff4@sabobilliards.com',
                full_name: 'Phạm Thị Staff',
                role: 'STAFF',
                phone: '0901010101'
            },
            {
                email: 'staff5@sabobilliards.com',
                full_name: 'Hoàng Văn Staff',
                role: 'STAFF',
                phone: '0902020202'
            },
            {
                email: 'staff6@sabobilliards.com',
                full_name: 'Vũ Thị Staff',
                role: 'STAFF',
                phone: '0903030303'
            }
        ];
        
        console.log('🚀 Creating employees...');
        
        for (const employee of employees) {
            try {
                // Check if user already exists
                const existingUser = await client.query(`
                    SELECT email FROM users WHERE email = $1;
                `, [employee.email]);
                
                if (existingUser.rows.length > 0) {
                    console.log(`⚠️ User ${employee.email} already exists, skipping...`);
                    continue;
                }
                
                // Insert new user
                const result = await client.query(`
                    INSERT INTO users (email, full_name, role, phone, company_id, is_active)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    RETURNING id, email, full_name, role;
                `, [
                    employee.email,
                    employee.full_name,
                    employee.role,
                    employee.phone,
                    companyId,
                    true
                ]);
                
                console.log(`✅ Created ${employee.role}: ${result.rows[0].full_name} (${result.rows[0].email})`);
                
            } catch (error) {
                console.error(`❌ Failed to create ${employee.email}:`, error.message);
            }
        }
        
        // Summary
        console.log('\n📊 Employee Summary for SABO Billiards:');
        const summary = await client.query(`
            SELECT role, COUNT(*) as count 
            FROM users 
            WHERE company_id = $1 
            GROUP BY role 
            ORDER BY 
                CASE role 
                    WHEN 'ceo' THEN 1 
                    WHEN 'manager' THEN 2 
                    WHEN 'shift_leader' THEN 3 
                    WHEN 'staff' THEN 4 
                    ELSE 5 
                END;
        `, [companyId]);
        
        for (const row of summary.rows) {
            const roleLabel = {
                'CEO': 'CEO',
                'BRANCH_MANAGER': 'Branch Manager', 
                'SHIFT_LEADER': 'Shift Leader',
                'STAFF': 'Staff'
            }[row.role] || row.role;
            
            console.log(`  - ${roleLabel}: ${row.count} người`);
        }
        
        console.log('\n🎯 Test Accounts Created:');
        console.log('  📧 CEO: ceo@sabobilliards.com');
        console.log('  📧 Manager: manager1@sabobilliards.com / manager2@sabobilliards.com');
        console.log('  📧 Shift Leader: shift1@sabobilliards.com / shift2@sabobilliards.com / shift3@sabobilliards.com');
        console.log('  📧 Staff: staff1@sabobilliards.com → staff6@sabobilliards.com');
        console.log('\n💡 Note: These are user records only. For full auth, use Supabase Auth signup or the invitation system!');
        
    } catch (error) {
        console.error('❌ Error seeding employee data:', error.message);
        process.exit(1);
    } finally {
        await client.end();
        console.log('\n🔌 Connection closed');
    }
}

// Run the seeding
seedEmployeeData();