const { Client } = require('pg');
require('dotenv').config({ path: '../.env' });

async function fixSystemIssues() {
    const client = new Client({
        connectionString: process.env.SUPABASE_CONNECTION_STRING,
        ssl: { rejectUnauthorized: false }
    });
    
    try {
        await client.connect();
        console.log('🔧 === FIXING SYSTEM ISSUES ===');
        
        // 1. Add missing usage_limit column to employee_invitations
        console.log('\n1️⃣ Adding usage_limit column...');
        try {
            await client.query(`
                ALTER TABLE employee_invitations 
                ADD COLUMN IF NOT EXISTS usage_limit INTEGER DEFAULT 1;
            `);
            console.log('✅ usage_limit column added');
            
            // Set default values for existing invitations
            await client.query(`
                UPDATE employee_invitations 
                SET usage_limit = 1 
                WHERE usage_limit IS NULL;
            `);
            console.log('✅ Default usage_limit values set');
            
        } catch (error) {
            console.log('⚠️ Usage_limit column:', error.message);
        }
        
        // 2. Fix multiple CEOs issue - keep only the first CEO per company
        console.log('\n2️⃣ Fixing multiple CEOs issue...');
        
        // First, find companies with multiple CEOs
        const multipleCEOsResult = await client.query(`
            SELECT company_id, COUNT(*) as ceo_count, 
                   array_agg(id ORDER BY created_at) as ceo_ids
            FROM users 
            WHERE role = 'CEO' 
            GROUP BY company_id 
            HAVING COUNT(*) > 1;
        `);
        
        console.log(`Found ${multipleCEOsResult.rows.length} companies with multiple CEOs`);
        
        for (const company of multipleCEOsResult.rows) {
            // Keep the first CEO, change others to BRANCH_MANAGER
            const keeptCEO = company.ceo_ids[0];
            const changeCEOs = company.ceo_ids.slice(1);
            
            for (const ceoId of changeCEOs) {
                await client.query(`
                    UPDATE users 
                    SET role = 'BRANCH_MANAGER' 
                    WHERE id = $1;
                `, [ceoId]);
                console.log(`✅ Changed CEO ${ceoId} to BRANCH_MANAGER`);
            }
        }
        
        // 3. Add CEO uniqueness constraint
        console.log('\n3️⃣ Adding CEO uniqueness constraint...');
        try {
            await client.query(`
                CREATE UNIQUE INDEX IF NOT EXISTS unique_ceo_per_company 
                ON users (company_id) 
                WHERE role = 'CEO';
            `);
            console.log('✅ CEO uniqueness constraint added');
        } catch (error) {
            console.log('⚠️ CEO constraint:', error.message);
        }
        
        // 4. Add more invitation columns for completeness
        console.log('\n4️⃣ Adding additional invitation columns...');
        try {
            await client.query(`
                ALTER TABLE employee_invitations 
                ADD COLUMN IF NOT EXISTS used_count INTEGER DEFAULT 0,
                ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMP WITH TIME ZONE,
                ADD COLUMN IF NOT EXISTS notes TEXT;
            `);
            console.log('✅ Additional invitation columns added');
        } catch (error) {
            console.log('⚠️ Additional columns:', error.message);
        }
        
        // 5. Update invitation constraints
        console.log('\n5️⃣ Updating invitation constraints...');
        try {
            await client.query(`
                ALTER TABLE employee_invitations 
                ADD CONSTRAINT chk_usage_limit_positive 
                CHECK (usage_limit > 0),
                ADD CONSTRAINT chk_used_count_not_negative 
                CHECK (used_count >= 0),
                ADD CONSTRAINT chk_used_count_within_limit 
                CHECK (used_count <= usage_limit);
            `);
            console.log('✅ Invitation constraints added');
        } catch (error) {
            if (error.message.includes('already exists')) {
                console.log('✅ Invitation constraints already exist');
            } else {
                console.log('⚠️ Invitation constraints:', error.message);
            }
        }
        
        // 6. Create function to prevent multiple CEOs
        console.log('\n6️⃣ Creating CEO validation trigger...');
        try {
            await client.query(`
                CREATE OR REPLACE FUNCTION prevent_multiple_ceos()
                RETURNS TRIGGER AS $$
                BEGIN
                    IF NEW.role = 'CEO' THEN
                        IF EXISTS (
                            SELECT 1 FROM users 
                            WHERE company_id = NEW.company_id 
                            AND role = 'CEO' 
                            AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
                        ) THEN
                            RAISE EXCEPTION 'Company already has a CEO. Only one CEO per company is allowed.';
                        END IF;
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
            `);
            
            await client.query(`
                DROP TRIGGER IF EXISTS trigger_prevent_multiple_ceos ON users;
            `);
            
            await client.query(`
                CREATE TRIGGER trigger_prevent_multiple_ceos
                BEFORE INSERT OR UPDATE ON users
                FOR EACH ROW
                EXECUTE FUNCTION prevent_multiple_ceos();
            `);
            
            console.log('✅ CEO validation trigger created');
        } catch (error) {
            console.log('⚠️ CEO trigger:', error.message);
        }
        
        console.log('\n🎉 System fixes completed!');
        
        // Verify fixes
        console.log('\n🔍 === VERIFYING FIXES ===');
        
        // Check CEO count per company
        const ceoCheck = await client.query(`
            SELECT company_id, COUNT(*) as ceo_count 
            FROM users 
            WHERE role = 'CEO' 
            GROUP BY company_id;
        `);
        
        const badCompanies = ceoCheck.rows.filter(row => row.ceo_count > 1);
        if (badCompanies.length === 0) {
            console.log('✅ All companies have exactly one CEO');
        } else {
            console.log(`⚠️ ${badCompanies.length} companies still have multiple CEOs`);
        }
        
        // Check invitation table structure
        const invitationColumns = await client.query(`
            SELECT column_name FROM information_schema.columns 
            WHERE table_name = 'employee_invitations' 
            AND column_name IN ('usage_limit', 'used_count');
        `);
        
        console.log(`✅ Invitation table has ${invitationColumns.rows.length}/2 required columns`);
        
    } catch (error) {
        console.error('❌ Error fixing system:', error.message);
    } finally {
        await client.end();
        console.log('🔌 Connection closed');
    }
}

fixSystemIssues();