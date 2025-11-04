const { Client } = require('pg');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

class TriggerTester {
    constructor() {
        this.client = new Client({
            connectionString: connectionString,
            ssl: { rejectUnauthorized: false }
        });
        this.testResults = [];
    }

    async connect() {
        await this.client.connect();
        console.log('🔌 Connected to PostgreSQL for trigger testing');
    }

    async disconnect() {
        await this.client.end();
        console.log('🔌 Database connection closed');
    }

    logTest(testName, status, details = '') {
        const result = { testName, status, details };
        this.testResults.push(result);
        const icon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⚠️';
        console.log(`${icon} ${testName}: ${status}${details ? ' - ' + details : ''}`);
    }

    async testTriggerExists(triggerName, tableName) {
        try {
            const result = await this.client.query(`
                SELECT trigger_name, event_manipulation, action_timing
                FROM information_schema.triggers 
                WHERE trigger_name = $1 AND event_object_table = $2;
            `, [triggerName, tableName]);

            if (result.rows.length > 0) {
                const trigger = result.rows[0];
                this.logTest(
                    `Trigger ${triggerName} on ${tableName}`, 
                    'PASS',
                    `${trigger.action_timing} ${trigger.event_manipulation}`
                );
                return true;
            } else {
                this.logTest(`Trigger ${triggerName} on ${tableName}`, 'FAIL', 'Trigger not found');
                return false;
            }
        } catch (error) {
            this.logTest(`Trigger ${triggerName} on ${tableName}`, 'FAIL', error.message);
            return false;
        }
    }

    async testUpdatedAtTrigger() {
        console.log('\n🧪 === TESTING UPDATED_AT TRIGGERS ===');
        
        // Test companies table updated_at trigger
        try {
            // Get initial updated_at
            const initialResult = await this.client.query(`
                SELECT id, updated_at FROM companies 
                WHERE name = 'SABO Billiards' LIMIT 1;
            `);
            
            if (initialResult.rows.length === 0) {
                this.logTest('Companies updated_at trigger', 'SKIP', 'No SABO Billiards company found');
                return;
            }

            const companyId = initialResult.rows[0].id;
            const initialUpdatedAt = initialResult.rows[0].updated_at;
            
            // Wait a moment to ensure timestamp difference
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Update company
            await this.client.query(`
                UPDATE companies 
                SET description = 'Test trigger update - ' || NOW()::text
                WHERE id = $1;
            `, [companyId]);
            
            // Check if updated_at changed
            const updatedResult = await this.client.query(`
                SELECT updated_at FROM companies WHERE id = $1;
            `, [companyId]);
            
            const newUpdatedAt = updatedResult.rows[0].updated_at;
            
            if (new Date(newUpdatedAt) > new Date(initialUpdatedAt)) {
                this.logTest('Companies updated_at trigger', 'PASS', 'Timestamp updated correctly');
            } else {
                this.logTest('Companies updated_at trigger', 'FAIL', 'Timestamp not updated');
            }
            
        } catch (error) {
            this.logTest('Companies updated_at trigger', 'FAIL', error.message);
        }
    }

    async testUserRoleTrigger() {
        console.log('\n🧪 === TESTING USER ROLE VALIDATION TRIGGERS ===');
        
        try {
            // Test invalid role insertion
            const testEmail = `test_invalid_role_${Date.now()}@example.com`;
            
            try {
                await this.client.query(`
                    INSERT INTO users (email, role, company_id)
                    VALUES ($1, 'INVALID_ROLE', (SELECT id FROM companies LIMIT 1));
                `, [testEmail]);
                
                this.logTest('User role validation trigger', 'FAIL', 'Invalid role was accepted');
                
                // Cleanup if somehow it was inserted
                await this.client.query('DELETE FROM users WHERE email = $1', [testEmail]);
                
            } catch (error) {
                if (error.message.includes('violates check constraint') || 
                    error.message.includes('invalid input value')) {
                    this.logTest('User role validation trigger', 'PASS', 'Invalid role correctly rejected');
                } else {
                    this.logTest('User role validation trigger', 'FAIL', error.message);
                }
            }
            
        } catch (error) {
            this.logTest('User role validation trigger', 'FAIL', error.message);
        }
    }

    async testInvitationTriggers() {
        console.log('\n🧪 === TESTING INVITATION TRIGGERS ===');
        
        try {
            // Test invitation code uniqueness
            const testCode = `TEST_UNIQUE_${Date.now()}`;
            const companyId = await this.client.query('SELECT id FROM companies LIMIT 1');
            const userId = await this.client.query(`
                SELECT id FROM users WHERE role = 'CEO' LIMIT 1
            `);
            
            if (companyId.rows.length === 0 || userId.rows.length === 0) {
                this.logTest('Invitation triggers', 'SKIP', 'No company or CEO found');
                return;
            }
            
            // Insert first invitation
            const firstResult = await this.client.query(`
                INSERT INTO employee_invitations (
                    company_id, created_by, invitation_code, role_type, expires_at
                ) VALUES ($1, $2, $3, 'STAFF', NOW() + INTERVAL '1 day')
                RETURNING id;
            `, [companyId.rows[0].id, userId.rows[0].id, testCode]);
            
            this.logTest('Invitation creation', 'PASS', 'First invitation created successfully');
            
            // Try to insert duplicate code
            try {
                await this.client.query(`
                    INSERT INTO employee_invitations (
                        company_id, created_by, invitation_code, role_type, expires_at
                    ) VALUES ($1, $2, $3, 'STAFF', NOW() + INTERVAL '1 day');
                `, [companyId.rows[0].id, userId.rows[0].id, testCode]);
                
                this.logTest('Invitation code uniqueness', 'FAIL', 'Duplicate code was accepted');
                
            } catch (error) {
                if (error.message.includes('duplicate key') || 
                    error.message.includes('unique constraint')) {
                    this.logTest('Invitation code uniqueness', 'PASS', 'Duplicate code correctly rejected');
                } else {
                    this.logTest('Invitation code uniqueness', 'FAIL', error.message);
                }
            }
            
            // Cleanup
            await this.client.query('DELETE FROM employee_invitations WHERE id = $1', [firstResult.rows[0].id]);
            
        } catch (error) {
            this.logTest('Invitation triggers', 'FAIL', error.message);
        }
    }

    async testRLSTriggers() {
        console.log('\n🧪 === TESTING RLS (ROW LEVEL SECURITY) TRIGGERS ===');
        
        try {
            // Check if RLS is enabled on key tables
            const rlsResult = await this.client.query(`
                SELECT schemaname, tablename, rowsecurity 
                FROM pg_tables 
                WHERE tablename IN ('companies', 'users', 'employee_invitations')
                AND schemaname = 'public';
            `);
            
            let rlsCount = 0;
            for (const row of rlsResult.rows) {
                if (row.rowsecurity) {
                    this.logTest(`RLS enabled on ${row.tablename}`, 'PASS', 'Row Level Security active');
                    rlsCount++;
                } else {
                    this.logTest(`RLS enabled on ${row.tablename}`, 'WARN', 'Row Level Security not enabled');
                }
            }
            
            if (rlsCount > 0) {
                this.logTest('RLS Security System', 'PASS', `${rlsCount} tables protected`);
            } else {
                this.logTest('RLS Security System', 'WARN', 'No RLS policies found');
            }
            
        } catch (error) {
            this.logTest('RLS triggers', 'FAIL', error.message);
        }
    }

    async testCompanyConstraintTriggers() {
        console.log('\n🧪 === TESTING COMPANY CONSTRAINT TRIGGERS ===');
        
        try {
            // Test company name uniqueness
            const testName = `Test Company ${Date.now()}`;
            
            // Insert first company
            const firstResult = await this.client.query(`
                INSERT INTO companies (name, description, created_by)
                VALUES ($1, 'Test description', (SELECT id FROM users LIMIT 1))
                RETURNING id;
            `, [testName]);
            
            this.logTest('Company creation', 'PASS', 'Company created successfully');
            
            // Try to insert duplicate name
            try {
                await this.client.query(`
                    INSERT INTO companies (name, description, created_by)
                    VALUES ($1, 'Another description', (SELECT id FROM users LIMIT 1));
                `, [testName]);
                
                this.logTest('Company name uniqueness', 'FAIL', 'Duplicate name was accepted');
                
            } catch (error) {
                if (error.message.includes('duplicate key') || 
                    error.message.includes('unique constraint')) {
                    this.logTest('Company name uniqueness', 'PASS', 'Duplicate name correctly rejected');
                } else {
                    this.logTest('Company name uniqueness', 'FAIL', error.message);
                }
            }
            
            // Cleanup
            await this.client.query('DELETE FROM companies WHERE id = $1', [firstResult.rows[0].id]);
            
        } catch (error) {
            this.logTest('Company constraint triggers', 'FAIL', error.message);
        }
    }

    async runAllTests() {
        console.log('🚀 === SABOHUB DATABASE TRIGGER TESTING STARTED ===');
        console.log('🧪 Testing all database triggers and constraints...\n');
        
        await this.connect();
        
        try {
            // Test trigger existence
            console.log('🧪 === CHECKING TRIGGER EXISTENCE ===');
            await this.testTriggerExists('update_updated_at', 'companies');
            await this.testTriggerExists('update_updated_at', 'users');
            await this.testTriggerExists('update_updated_at', 'employee_invitations');
            
            // Test functional triggers
            await this.testUpdatedAtTrigger();
            await this.testUserRoleTrigger();
            await this.testInvitationTriggers();
            await this.testRLSTriggers();
            await this.testCompanyConstraintTriggers();
            
        } catch (error) {
            console.error('❌ Testing error:', error.message);
        } finally {
            await this.disconnect();
        }
        
        // Summary
        this.printSummary();
    }

    printSummary() {
        console.log('\n📊 === TRIGGER TEST SUMMARY ===');
        
        const passed = this.testResults.filter(r => r.status === 'PASS').length;
        const failed = this.testResults.filter(r => r.status === 'FAIL').length;
        const warned = this.testResults.filter(r => r.status === 'WARN').length;
        const skipped = this.testResults.filter(r => r.status === 'SKIP').length;
        const total = this.testResults.length;
        
        console.log(`✅ Passed: ${passed}`);
        console.log(`❌ Failed: ${failed}`);
        console.log(`⚠️ Warnings: ${warned}`);
        console.log(`⏭️ Skipped: ${skipped}`);
        console.log(`📈 Total: ${total}`);
        
        const successRate = ((passed / total) * 100).toFixed(1);
        console.log(`\n🎯 Success Rate: ${successRate}%`);
        
        if (failed === 0) {
            console.log('🎉 EXCELLENT! All critical triggers working correctly!');
        } else if (failed <= 2) {
            console.log('✅ GOOD! Minor issues found, mostly functional');
        } else {
            console.log('⚠️ ATTENTION! Multiple trigger issues need fixing');
        }
        
        console.log('\n🧪 Trigger testing completed!');
    }
}

// Run the tests
const tester = new TriggerTester();
tester.runAllTests();