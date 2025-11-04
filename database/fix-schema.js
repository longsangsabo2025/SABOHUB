const { Client } = require('pg');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

async function checkAndFixDatabaseSchema() {
    const client = new Client({
        connectionString: connectionString,
        ssl: { rejectUnauthorized: false }
    });

    try {
        await client.connect();
        console.log('🔧 === CHECKING AND FIXING DATABASE SCHEMA ===');
        
        // 1. Check companies table structure
        console.log('\n1️⃣ Checking companies table...');
        const companiesColumns = await client.query(`
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'companies' 
            ORDER BY ordinal_position;
        `);
        
        console.log('Companies table columns:');
        companiesColumns.rows.forEach(col => {
            console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
        });
        
        // Add description column if missing
        const hasDescription = companiesColumns.rows.some(col => col.column_name === 'description');
        if (!hasDescription) {
            console.log('➕ Adding description column to companies table...');
            await client.query(`
                ALTER TABLE companies 
                ADD COLUMN description TEXT;
            `);
            console.log('✅ Description column added');
        }
        
        // 2. Check users table structure
        console.log('\n2️⃣ Checking users table...');
        const usersColumns = await client.query(`
            SELECT column_name, data_type, is_nullable 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            ORDER BY ordinal_position;
        `);
        
        console.log('Users table columns:');
        usersColumns.rows.forEach(col => {
            console.log(`  - ${col.column_name}: ${col.data_type} (nullable: ${col.is_nullable})`);
        });
        
        // Add full_name column if missing or make it nullable
        const hasFullName = usersColumns.rows.some(col => col.column_name === 'full_name');
        if (!hasFullName) {
            console.log('➕ Adding full_name column to users table...');
            await client.query(`
                ALTER TABLE users 
                ADD COLUMN full_name TEXT;
            `);
            console.log('✅ Full_name column added');
        } else {
            // Make full_name nullable
            console.log('🔧 Making full_name column nullable...');
            await client.query(`
                ALTER TABLE users 
                ALTER COLUMN full_name DROP NOT NULL;
            `);
            console.log('✅ Full_name column is now nullable');
        }
        
        // 3. Create updated_at triggers
        console.log('\n3️⃣ Creating updated_at triggers...');
        
        // Create trigger function if not exists
        await client.query(`
            CREATE OR REPLACE FUNCTION update_updated_at_column()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = NOW();
                RETURN NEW;
            END;
            $$ language 'plpgsql';
        `);
        console.log('✅ Trigger function created');
        
        // Create triggers for each table
        const tables = ['companies', 'users', 'employee_invitations'];
        for (const table of tables) {
            try {
                await client.query(`
                    DROP TRIGGER IF EXISTS update_updated_at ON ${table};
                `);
                
                await client.query(`
                    CREATE TRIGGER update_updated_at 
                    BEFORE UPDATE ON ${table}
                    FOR EACH ROW 
                    EXECUTE FUNCTION update_updated_at_column();
                `);
                console.log(`✅ Updated_at trigger created for ${table}`);
            } catch (error) {
                console.log(`⚠️ Could not create trigger for ${table}: ${error.message}`);
            }
        }
        
        // 4. Enable RLS on key tables
        console.log('\n4️⃣ Enabling Row Level Security...');
        
        const rlsTables = ['companies', 'users'];
        for (const table of rlsTables) {
            try {
                await client.query(`ALTER TABLE ${table} ENABLE ROW LEVEL SECURITY;`);
                console.log(`✅ RLS enabled on ${table}`);
            } catch (error) {
                console.log(`⚠️ Could not enable RLS on ${table}: ${error.message}`);
            }
        }
        
        // 5. Create basic RLS policies
        console.log('\n5️⃣ Creating RLS policies...');
        
        try {
            // Companies policy - users can see companies they belong to
            await client.query(`
                DROP POLICY IF EXISTS "Users can view their company" ON companies;
            `);
            await client.query(`
                CREATE POLICY "Users can view their company" ON companies
                FOR SELECT USING (
                    id IN (
                        SELECT company_id FROM users 
                        WHERE id = auth.uid()
                    )
                );
            `);
            console.log('✅ Companies RLS policy created');
            
            // Users policy - users can see other users in their company
            await client.query(`
                DROP POLICY IF EXISTS "Users can view company colleagues" ON users;
            `);
            await client.query(`
                CREATE POLICY "Users can view company colleagues" ON users
                FOR SELECT USING (
                    company_id IN (
                        SELECT company_id FROM users 
                        WHERE id = auth.uid()
                    )
                );
            `);
            console.log('✅ Users RLS policy created');
            
        } catch (error) {
            console.log(`⚠️ Could not create RLS policies: ${error.message}`);
        }
        
        console.log('\n🎉 Database schema fix completed!');
        
    } catch (error) {
        console.error('❌ Error fixing schema:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

// Run the fix
checkAndFixDatabaseSchema();