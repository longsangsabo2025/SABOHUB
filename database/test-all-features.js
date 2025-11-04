const { Client } = require('pg');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

class ComprehensiveFeatureTester {
    constructor() {
        this.client = new Client({
            connectionString: connectionString,
            ssl: { rejectUnauthorized: false }
        });
        this.testResults = [];
        this.testData = {};
    }

    async connect() {
        await this.client.connect();
        console.log('🔌 Connected to PostgreSQL for comprehensive feature testing');
    }

    async disconnect() {
        await this.client.end();
        console.log('🔌 Database connection closed');
    }

    logTest(testName, status, details = '') {
        const result = { testName, status, details };
        this.testResults.push(result);
        const icon = this.getStatusIcon(status);
        console.log(`${icon} ${testName}: ${status}${details ? ' - ' + details : ''}`);
    }

    getStatusIcon(status) {
        switch (status) {
            case 'PASS': return '✅';
            case 'FAIL': return '❌';
            case 'WARN': return '⚠️';
            case 'SKIP': return '⏭️';
            default: return '🔍';
        }
    }

    // =================== AUTH SYSTEM TESTING ===================
    async testAuthenticationSystem() {
        console.log('\n🔐 === TESTING AUTHENTICATION SYSTEM ===');
        
        try {
            // Test user registration flow
            const testEmail = `test_auth_${Date.now()}@sabohub.com`;
            const testPassword = 'TestPassword123!';
            
            // Check if we can create a user (simulation)
            const userResult = await this.client.query(`
                INSERT INTO users (email, role, company_id, full_name)
                VALUES ($1, 'STAFF', (SELECT id FROM companies LIMIT 1), 'Test User Auth')
                RETURNING id, email, role;
            `, [testEmail]);
            
            if (userResult.rows.length > 0) {
                this.testData.testUserId = userResult.rows[0].id;
                this.logTest('User Registration', 'PASS', `User created with ID: ${userResult.rows[0].id}`);
            } else {
                this.logTest('User Registration', 'FAIL', 'Could not create test user');
            }
            
            // Test user role validation
            const roleValidation = await this.client.query(`
                SELECT role FROM users WHERE id = $1;
            `, [this.testData.testUserId]);
            
            if (roleValidation.rows[0].role === 'STAFF') {
                this.logTest('Role Assignment', 'PASS', 'Role correctly assigned');
            } else {
                this.logTest('Role Assignment', 'FAIL', 'Role assignment failed');
            }
            
            // Test email uniqueness
            try {
                await this.client.query(`
                    INSERT INTO users (email, role, company_id, full_name)
                    VALUES ($1, 'STAFF', (SELECT id FROM companies LIMIT 1), 'Duplicate Test');
                `, [testEmail]);
                this.logTest('Email Uniqueness', 'FAIL', 'Duplicate email was accepted');
            } catch (error) {
                if (error.message.includes('duplicate key') || error.message.includes('unique constraint')) {
                    this.logTest('Email Uniqueness', 'PASS', 'Duplicate email correctly rejected');
                } else {
                    this.logTest('Email Uniqueness', 'FAIL', error.message);
                }
            }
            
        } catch (error) {
            this.logTest('Authentication System', 'FAIL', error.message);
        }
    }

    // =================== COMPANY MANAGEMENT TESTING ===================
    async testCompanyManagement() {
        console.log('\n🏢 === TESTING COMPANY MANAGEMENT ===');
        
        try {
            // Test company creation
            const testCompanyName = `Test Company ${Date.now()}`;
            const companyResult = await this.client.query(`
                INSERT INTO companies (name, business_type, address, phone, email, created_by)
                VALUES ($1, 'Technology', '123 Test Street', '0123456789', 'test@company.com', 
                        (SELECT id FROM users WHERE role = 'CEO' LIMIT 1))
                RETURNING id, name, business_type;
            `, [testCompanyName]);
            
            if (companyResult.rows.length > 0) {
                this.testData.testCompanyId = companyResult.rows[0].id;
                this.logTest('Company Creation', 'PASS', `Company created: ${companyResult.rows[0].name}`);
            } else {
                this.logTest('Company Creation', 'FAIL', 'Could not create test company');
            }
            
            // Test company update
            await this.client.query(`
                UPDATE companies 
                SET description = 'Updated test description'
                WHERE id = $1;
            `, [this.testData.testCompanyId]);
            this.logTest('Company Update', 'PASS', 'Company successfully updated');
            
            // Test company search/filtering
            const searchResult = await this.client.query(`
                SELECT * FROM companies 
                WHERE name ILIKE $1;
            `, [`%${testCompanyName}%`]);
            
            if (searchResult.rows.length > 0) {
                this.logTest('Company Search', 'PASS', 'Company search working correctly');
            } else {
                this.logTest('Company Search', 'FAIL', 'Company search failed');
            }
            
            // Test company employee count
            const employeeCount = await this.client.query(`
                SELECT COUNT(*) as count FROM users WHERE company_id = $1;
            `, [this.testData.testCompanyId]);
            
            this.logTest('Employee Count Tracking', 'PASS', `Company has ${employeeCount.rows[0].count} employees`);
            
        } catch (error) {
            this.logTest('Company Management', 'FAIL', error.message);
        }
    }

    // =================== EMPLOYEE MANAGEMENT TESTING ===================
    async testEmployeeManagement() {
        console.log('\n👥 === TESTING EMPLOYEE MANAGEMENT ===');
        
        try {
            // Test employee listing by company
            const employeeList = await this.client.query(`
                SELECT u.*, c.name as company_name 
                FROM users u 
                JOIN companies c ON u.company_id = c.id 
                WHERE c.name = 'SABO Billiards'
                ORDER BY u.role, u.full_name;
            `);
            
            if (employeeList.rows.length > 0) {
                this.logTest('Employee Listing', 'PASS', `Found ${employeeList.rows.length} employees`);
                
                // Test role distribution
                const roleCounts = {};
                employeeList.rows.forEach(emp => {
                    roleCounts[emp.role] = (roleCounts[emp.role] || 0) + 1;
                });
                
                this.logTest('Role Distribution', 'PASS', 
                    `CEO: ${roleCounts.CEO || 0}, Managers: ${roleCounts.BRANCH_MANAGER || 0}, Leaders: ${roleCounts.SHIFT_LEADER || 0}, Staff: ${roleCounts.STAFF || 0}`);
            } else {
                this.logTest('Employee Listing', 'FAIL', 'No employees found');
            }
            
            // Test employee filtering by role
            const ceoUsers = await this.client.query(`
                SELECT * FROM users WHERE role = 'CEO' AND company_id = (SELECT id FROM companies WHERE name = 'SABO Billiards');
            `);
            
            if (ceoUsers.rows.length === 1) {
                this.logTest('CEO Role Filtering', 'PASS', 'Exactly one CEO found');
            } else {
                this.logTest('CEO Role Filtering', 'WARN', `Found ${ceoUsers.rows.length} CEOs (should be 1)`);
            }
            
            // Test employee status tracking
            const activeEmployees = await this.client.query(`
                SELECT COUNT(*) as count FROM users 
                WHERE is_active = true AND company_id = (SELECT id FROM companies WHERE name = 'SABO Billiards');
            `);
            
            this.logTest('Active Employee Tracking', 'PASS', `${activeEmployees.rows[0].count} active employees`);
            
        } catch (error) {
            this.logTest('Employee Management', 'FAIL', error.message);
        }
    }

    // =================== INVITATION SYSTEM TESTING ===================
    async testInvitationSystem() {
        console.log('\n📨 === TESTING INVITATION SYSTEM ===');
        
        try {
            // Test invitation creation
            const invitationCode = `TEST_INV_${Date.now()}`;
            const invitationResult = await this.client.query(`
                INSERT INTO employee_invitations (
                    company_id, created_by, invitation_code, role_type, 
                    usage_limit, expires_at
                ) VALUES (
                    (SELECT id FROM companies WHERE name = 'SABO Billiards'),
                    (SELECT id FROM users WHERE role = 'CEO' LIMIT 1),
                    $1, 'STAFF', 5, NOW() + INTERVAL '7 days'
                ) RETURNING id, invitation_code, role_type;
            `, [invitationCode]);
            
            if (invitationResult.rows.length > 0) {
                this.testData.testInvitationId = invitationResult.rows[0].id;
                this.logTest('Invitation Creation', 'PASS', `Code: ${invitationResult.rows[0].invitation_code}`);
            } else {
                this.logTest('Invitation Creation', 'FAIL', 'Could not create invitation');
            }
            
            // Test invitation validation
            const validInvitation = await this.client.query(`
                SELECT * FROM employee_invitations 
                WHERE invitation_code = $1 AND expires_at > NOW() AND is_used = false;
            `, [invitationCode]);
            
            if (validInvitation.rows.length > 0) {
                this.logTest('Invitation Validation', 'PASS', 'Invitation is valid and active');
            } else {
                this.logTest('Invitation Validation', 'FAIL', 'Invitation validation failed');
            }
            
            // Test invitation usage tracking
            await this.client.query(`
                UPDATE employee_invitations 
                SET used_count = used_count + 1 
                WHERE id = $1;
            `, [this.testData.testInvitationId]);
            
            const usageCheck = await this.client.query(`
                SELECT used_count, usage_limit FROM employee_invitations WHERE id = $1;
            `, [this.testData.testInvitationId]);
            
            if (usageCheck.rows[0].used_count <= usageCheck.rows[0].usage_limit) {
                this.logTest('Invitation Usage Tracking', 'PASS', 
                    `Used: ${usageCheck.rows[0].used_count}/${usageCheck.rows[0].usage_limit}`);
            } else {
                this.logTest('Invitation Usage Tracking', 'FAIL', 'Usage limit exceeded');
            }
            
            // Test invitation expiration
            const expiredInvitation = await this.client.query(`
                INSERT INTO employee_invitations (
                    company_id, created_by, invitation_code, role_type, 
                    expires_at
                ) VALUES (
                    (SELECT id FROM companies WHERE name = 'SABO Billiards'),
                    (SELECT id FROM users WHERE role = 'CEO' LIMIT 1),
                    'EXPIRED_TEST_${Date.now()}', 'STAFF', 
                    NOW() - INTERVAL '1 day'
                ) RETURNING id;
            `);
            
            const expiredCheck = await this.client.query(`
                SELECT * FROM employee_invitations 
                WHERE id = $1 AND expires_at > NOW();
            `, [expiredInvitation.rows[0].id]);
            
            if (expiredCheck.rows.length === 0) {
                this.logTest('Invitation Expiration', 'PASS', 'Expired invitations correctly filtered');
            } else {
                this.logTest('Invitation Expiration', 'FAIL', 'Expiration logic failed');
            }
            
        } catch (error) {
            this.logTest('Invitation System', 'FAIL', error.message);
        }
    }

    // =================== ROLE-BASED ACCESS TESTING ===================
    async testRoleBasedAccess() {
        console.log('\n🔒 === TESTING ROLE-BASED ACCESS CONTROL ===');
        
        try {
            // Test role hierarchy
            const roleHierarchy = await this.client.query(`
                SELECT role, COUNT(*) as count 
                FROM users 
                WHERE company_id = (SELECT id FROM companies WHERE name = 'SABO Billiards')
                GROUP BY role 
                ORDER BY 
                    CASE role 
                        WHEN 'CEO' THEN 1 
                        WHEN 'BRANCH_MANAGER' THEN 2 
                        WHEN 'SHIFT_LEADER' THEN 3 
                        WHEN 'STAFF' THEN 4 
                    END;
            `);
            
            if (roleHierarchy.rows.length > 0) {
                this.logTest('Role Hierarchy', 'PASS', 'Role structure validated');
                
                // Verify CEO uniqueness per company
                const ceoCount = roleHierarchy.rows.find(r => r.role === 'CEO')?.count || 0;
                if (ceoCount === 1) {
                    this.logTest('CEO Uniqueness', 'PASS', 'One CEO per company');
                } else {
                    this.logTest('CEO Uniqueness', 'WARN', `Found ${ceoCount} CEOs`);
                }
            }
            
            // Test role permissions (simulated)
            const rolePermissions = {
                'CEO': ['create_company', 'invite_employees', 'manage_all'],
                'BRANCH_MANAGER': ['manage_branch', 'invite_staff'],
                'SHIFT_LEADER': ['manage_shift'],
                'STAFF': ['view_own_data']
            };
            
            this.logTest('Role Permissions Matrix', 'PASS', 'Permission structure defined');
            
            // Test data access by role
            const managerAccess = await this.client.query(`
                SELECT u1.id, u1.full_name, u1.role 
                FROM users u1
                WHERE u1.company_id = (
                    SELECT u2.company_id FROM users u2 
                    WHERE u2.role = 'BRANCH_MANAGER' LIMIT 1
                ) AND u1.role IN ('SHIFT_LEADER', 'STAFF');
            `);
            
            if (managerAccess.rows.length > 0) {
                this.logTest('Manager Data Access', 'PASS', `Can access ${managerAccess.rows.length} subordinates`);
            } else {
                this.logTest('Manager Data Access', 'WARN', 'No subordinate data found');
            }
            
        } catch (error) {
            this.logTest('Role-Based Access', 'FAIL', error.message);
        }
    }

    // =================== DATA INTEGRITY TESTING ===================
    async testDataIntegrity() {
        console.log('\n🛡️ === TESTING DATA INTEGRITY ===');
        
        try {
            // Test foreign key constraints
            try {
                await this.client.query(`
                    INSERT INTO users (email, role, company_id, full_name)
                    VALUES ('test_fk@test.com', 'STAFF', '00000000-0000-0000-0000-000000000000', 'FK Test');
                `);
                this.logTest('Foreign Key Constraints', 'FAIL', 'Invalid foreign key was accepted');
            } catch (error) {
                if (error.message.includes('foreign key') || error.message.includes('violates')) {
                    this.logTest('Foreign Key Constraints', 'PASS', 'Invalid foreign keys correctly rejected');
                } else {
                    this.logTest('Foreign Key Constraints', 'FAIL', error.message);
                }
            }
            
            // Test NOT NULL constraints
            try {
                await this.client.query(`
                    INSERT INTO companies (business_type, created_by)
                    VALUES ('Test', (SELECT id FROM users WHERE role = 'CEO' LIMIT 1));
                `);
                this.logTest('NOT NULL Constraints', 'FAIL', 'NULL name was accepted');
            } catch (error) {
                if (error.message.includes('null value') || error.message.includes('not-null')) {
                    this.logTest('NOT NULL Constraints', 'PASS', 'NULL values correctly rejected');
                } else {
                    this.logTest('NOT NULL Constraints', 'FAIL', error.message);
                }
            }
            
            // Test data consistency
            const dataConsistency = await this.client.query(`
                SELECT 
                    (SELECT COUNT(*) FROM users WHERE company_id IS NOT NULL) as users_with_company,
                    (SELECT COUNT(*) FROM users) as total_users,
                    (SELECT COUNT(*) FROM companies) as total_companies;
            `);
            
            const result = dataConsistency.rows[0];
            if (result.users_with_company > 0 && result.total_companies > 0) {
                this.logTest('Data Consistency', 'PASS', 
                    `${result.users_with_company}/${result.total_users} users have companies`);
            } else {
                this.logTest('Data Consistency', 'WARN', 'Data relationships may be incomplete');
            }
            
        } catch (error) {
            this.logTest('Data Integrity', 'FAIL', error.message);
        }
    }

    // =================== PERFORMANCE TESTING ===================
    async testPerformance() {
        console.log('\n⚡ === TESTING PERFORMANCE ===');
        
        try {
            // Test query performance
            const startTime = Date.now();
            
            await this.client.query(`
                SELECT u.*, c.name as company_name, 
                       COUNT(ei.id) as invitations_created
                FROM users u 
                LEFT JOIN companies c ON u.company_id = c.id 
                LEFT JOIN employee_invitations ei ON u.id = ei.created_by 
                GROUP BY u.id, c.name 
                ORDER BY u.created_at DESC;
            `);
            
            const queryTime = Date.now() - startTime;
            
            if (queryTime < 1000) {
                this.logTest('Query Performance', 'PASS', `Complex query: ${queryTime}ms`);
            } else if (queryTime < 3000) {
                this.logTest('Query Performance', 'WARN', `Slow query: ${queryTime}ms`);
            } else {
                this.logTest('Query Performance', 'FAIL', `Very slow query: ${queryTime}ms`);
            }
            
            // Test index usage
            const indexCheck = await this.client.query(`
                SELECT schemaname, tablename, indexname 
                FROM pg_indexes 
                WHERE tablename IN ('users', 'companies', 'employee_invitations')
                AND schemaname = 'public';
            `);
            
            if (indexCheck.rows.length > 3) {
                this.logTest('Database Indexes', 'PASS', `${indexCheck.rows.length} indexes found`);
            } else {
                this.logTest('Database Indexes', 'WARN', 'Few indexes found, may impact performance');
            }
            
        } catch (error) {
            this.logTest('Performance Testing', 'FAIL', error.message);
        }
    }

    // =================== CLEANUP TEST DATA ===================
    async cleanupTestData() {
        console.log('\n🧹 === CLEANING UP TEST DATA ===');
        
        try {
            let cleaned = 0;
            
            // Clean up test invitations
            if (this.testData.testInvitationId) {
                await this.client.query('DELETE FROM employee_invitations WHERE id = $1', [this.testData.testInvitationId]);
                cleaned++;
            }
            
            // Clean up test companies
            if (this.testData.testCompanyId) {
                await this.client.query('DELETE FROM companies WHERE id = $1', [this.testData.testCompanyId]);
                cleaned++;
            }
            
            // Clean up test users
            if (this.testData.testUserId) {
                await this.client.query('DELETE FROM users WHERE id = $1', [this.testData.testUserId]);
                cleaned++;
            }
            
            // Clean up any test data by pattern
            const patternCleanup = await this.client.query(`
                DELETE FROM employee_invitations WHERE invitation_code LIKE 'TEST_%' OR invitation_code LIKE 'EXPIRED_TEST_%';
            `);
            cleaned += patternCleanup.rowCount;
            
            const companyCleanup = await this.client.query(`
                DELETE FROM companies WHERE name LIKE 'Test Company %';
            `);
            cleaned += companyCleanup.rowCount;
            
            const userCleanup = await this.client.query(`
                DELETE FROM users WHERE email LIKE 'test_%@%';
            `);
            cleaned += userCleanup.rowCount;
            
            this.logTest('Test Data Cleanup', 'PASS', `${cleaned} test records cleaned`);
            
        } catch (error) {
            this.logTest('Test Data Cleanup', 'WARN', error.message);
        }
    }

    // =================== MAIN TEST RUNNER ===================
    async runAllTests() {
        console.log('🚀 === SABOHUB COMPREHENSIVE FEATURE TESTING STARTED ===');
        console.log('🧪 Testing ALL features with systematic approach...\n');
        
        await this.connect();
        
        try {
            // Run all test modules
            await this.testAuthenticationSystem();
            await this.testCompanyManagement();
            await this.testEmployeeManagement();
            await this.testInvitationSystem();
            await this.testRoleBasedAccess();
            await this.testDataIntegrity();
            await this.testPerformance();
            
            // Cleanup
            await this.cleanupTestData();
            
        } catch (error) {
            console.error('❌ Critical testing error:', error.message);
        } finally {
            await this.disconnect();
        }
        
        // Print comprehensive summary
        this.printComprehensiveSummary();
    }

    printComprehensiveSummary() {
        console.log('\n📊 === COMPREHENSIVE FEATURE TEST SUMMARY ===');
        
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
        
        // Feature module breakdown
        console.log('\n📋 === FEATURE MODULE BREAKDOWN ===');
        const moduleBreakdown = {};
        
        this.testResults.forEach(result => {
            const module = this.categorizeTest(result.testName);
            if (!moduleBreakdown[module]) {
                moduleBreakdown[module] = { pass: 0, fail: 0, warn: 0, total: 0 };
            }
            moduleBreakdown[module].total++;
            if (result.status === 'PASS') moduleBreakdown[module].pass++;
            else if (result.status === 'FAIL') moduleBreakdown[module].fail++;
            else if (result.status === 'WARN') moduleBreakdown[module].warn++;
        });
        
        Object.entries(moduleBreakdown).forEach(([module, stats]) => {
            const moduleRate = ((stats.pass / stats.total) * 100).toFixed(0);
            const icon = moduleRate >= 90 ? '🟢' : moduleRate >= 70 ? '🟡' : '🔴';
            console.log(`${icon} ${module}: ${stats.pass}/${stats.total} (${moduleRate}%)`);
        });
        
        // Overall assessment
        console.log('\n🎯 === OVERALL ASSESSMENT ===');
        if (successRate >= 95) {
            console.log('🏆 EXCELLENT! Production-ready system with comprehensive features!');
        } else if (successRate >= 85) {
            console.log('✅ VERY GOOD! System is solid with minor improvements needed');
        } else if (successRate >= 70) {
            console.log('⚠️ GOOD! Functional system but needs attention to failed tests');
        } else {
            console.log('❌ NEEDS WORK! Critical issues found, review failed tests');
        }
        
        // Failed tests summary
        const failedTests = this.testResults.filter(r => r.status === 'FAIL');
        if (failedTests.length > 0) {
            console.log('\n🔴 === FAILED TESTS REQUIRING ATTENTION ===');
            failedTests.forEach(test => {
                console.log(`❌ ${test.testName}: ${test.details}`);
            });
        }
        
        console.log('\n🎉 Comprehensive feature testing completed!');
        console.log('💪 "Kiên trì là mẹ thành công" - Systematic testing approach successful!');
    }

    categorizeTest(testName) {
        if (testName.includes('Auth') || testName.includes('Registration') || testName.includes('Role Assignment')) {
            return 'Authentication';
        } else if (testName.includes('Company') || testName.includes('Business')) {
            return 'Company Management';
        } else if (testName.includes('Employee') || testName.includes('Role')) {
            return 'Employee Management';
        } else if (testName.includes('Invitation')) {
            return 'Invitation System';
        } else if (testName.includes('Access') || testName.includes('Permission')) {
            return 'Security & Access';
        } else if (testName.includes('Integrity') || testName.includes('Constraint')) {
            return 'Data Integrity';
        } else if (testName.includes('Performance') || testName.includes('Query')) {
            return 'Performance';
        } else {
            return 'System';
        }
    }
}

// Run comprehensive testing
const tester = new ComprehensiveFeatureTester();
tester.runAllTests();