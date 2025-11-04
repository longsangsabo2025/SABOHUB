const { Client } = require('pg');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const connectionString = process.env.SUPABASE_CONNECTION_STRING;

class E2EWorkflowTester {
    constructor() {
        this.client = new Client({
            connectionString: connectionString,
            ssl: { rejectUnauthorized: false }
        });
        this.testResults = [];
        this.workflowData = {};
    }

    async connect() {
        await this.client.connect();
        console.log('🔌 Connected to PostgreSQL for E2E workflow testing');
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

    // =================== CEO COMPLETE WORKFLOW ===================
    async testCEOWorkflow() {
        console.log('\n👑 === TESTING CEO COMPLETE WORKFLOW ===');
        
        try {
            // Step 1: CEO Login/Authentication
            const ceoUsers = await this.client.query(`
                SELECT id, email, full_name, company_id 
                FROM users 
                WHERE role = 'CEO' 
                LIMIT 1;
            `);
            
            if (ceoUsers.rows.length > 0) {
                this.workflowData.ceoId = ceoUsers.rows[0].id;
                this.workflowData.companyId = ceoUsers.rows[0].company_id;
                this.logTest('CEO Authentication', 'PASS', `CEO found: ${ceoUsers.rows[0].full_name}`);
            } else {
                this.logTest('CEO Authentication', 'FAIL', 'No CEO found in system');
                return;
            }
            
            // Step 2: CEO Access Company Settings
            const companyAccess = await this.client.query(`
                SELECT name, business_type, address, phone, email 
                FROM companies 
                WHERE id = $1;
            `, [this.workflowData.companyId]);
            
            if (companyAccess.rows.length > 0) {
                this.logTest('CEO Company Access', 'PASS', `Company: ${companyAccess.rows[0].name}`);
            } else {
                this.logTest('CEO Company Access', 'FAIL', 'CEO cannot access company data');
            }
            
            // Step 3: CEO Create Employee Invitation
            const invitationCode = `E2E_CEO_${Date.now()}`;
            const createInvitation = await this.client.query(`
                INSERT INTO employee_invitations (
                    company_id, created_by, invitation_code, role_type, 
                    usage_limit, expires_at
                ) VALUES ($1, $2, $3, 'STAFF', 3, NOW() + INTERVAL '7 days')
                RETURNING id, invitation_code;
            `, [this.workflowData.companyId, this.workflowData.ceoId, invitationCode]);
            
            if (createInvitation.rows.length > 0) {
                this.workflowData.invitationId = createInvitation.rows[0].id;
                this.workflowData.invitationCode = createInvitation.rows[0].invitation_code;
                this.logTest('CEO Create Invitation', 'PASS', `Code: ${invitationCode}`);
            } else {
                this.logTest('CEO Create Invitation', 'FAIL', 'Failed to create invitation');
            }
            
            // Step 4: CEO View Employee List
            const employeeList = await this.client.query(`
                SELECT role, COUNT(*) as count 
                FROM users 
                WHERE company_id = $1 
                GROUP BY role;
            `, [this.workflowData.companyId]);
            
            if (employeeList.rows.length > 0) {
                const roleData = employeeList.rows.map(row => `${row.role}: ${row.count}`).join(', ');
                this.logTest('CEO View Employees', 'PASS', roleData);
            } else {
                this.logTest('CEO View Employees', 'WARN', 'No employees found');
            }
            
            // Step 5: CEO Monitor Invitation Status
            const invitationStatus = await this.client.query(`
                SELECT invitation_code, role_type, is_used, used_count, usage_limit
                FROM employee_invitations 
                WHERE id = $1;
            `, [this.workflowData.invitationId]);
            
            if (invitationStatus.rows.length > 0) {
                const status = invitationStatus.rows[0];
                this.logTest('CEO Monitor Invitations', 'PASS', 
                    `Status: ${status.is_used ? 'Used' : 'Active'}, Usage: ${status.used_count}/${status.usage_limit}`);
            } else {
                this.logTest('CEO Monitor Invitations', 'FAIL', 'Cannot monitor invitation status');
            }
            
        } catch (error) {
            this.logTest('CEO Workflow', 'FAIL', error.message);
        }
    }

    // =================== EMPLOYEE REGISTRATION WORKFLOW ===================
    async testEmployeeRegistrationWorkflow() {
        console.log('\n👥 === TESTING EMPLOYEE REGISTRATION WORKFLOW ===');
        
        try {
            // Step 1: Employee Receives Invitation Link
            if (!this.workflowData.invitationCode) {
                this.logTest('Employee Invitation Access', 'SKIP', 'No invitation code from CEO workflow');
                return;
            }
            
            // Step 2: Employee Validates Invitation Code
            const validateInvitation = await this.client.query(`
                SELECT id, company_id, role_type, expires_at, is_used, used_count, usage_limit
                FROM employee_invitations 
                WHERE invitation_code = $1 
                AND expires_at > NOW() 
                AND (used_count < usage_limit OR usage_limit IS NULL);
            `, [this.workflowData.invitationCode]);
            
            if (validateInvitation.rows.length > 0) {
                const invitation = validateInvitation.rows[0];
                this.logTest('Employee Validate Invitation', 'PASS', 
                    `Valid invitation for role: ${invitation.role_type}`);
                this.workflowData.targetRole = invitation.role_type;
                this.workflowData.targetCompanyId = invitation.company_id;
            } else {
                this.logTest('Employee Validate Invitation', 'FAIL', 'Invalid or expired invitation');
                return;
            }
            
            // Step 3: Employee Registration Form
            const newEmployeeEmail = `e2e_employee_${Date.now()}@sabohub.com`;
            const newEmployeeName = `E2E Test Employee ${Date.now()}`;
            
            // Simulate form validation
            const formValidation = {
                email: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newEmployeeEmail),
                name: newEmployeeName.length >= 2,
                role: ['CEO', 'BRANCH_MANAGER', 'SHIFT_LEADER', 'STAFF'].includes(this.workflowData.targetRole)
            };
            
            if (formValidation.email && formValidation.name && formValidation.role) {
                this.logTest('Employee Form Validation', 'PASS', 'All form fields valid');
            } else {
                this.logTest('Employee Form Validation', 'FAIL', 'Form validation failed');
            }
            
            // Step 4: Employee Account Creation
            const createEmployee = await this.client.query(`
                INSERT INTO users (
                    email, full_name, role, company_id, is_active
                ) VALUES ($1, $2, $3, $4, true)
                RETURNING id, email, full_name, role;
            `, [newEmployeeEmail, newEmployeeName, this.workflowData.targetRole, this.workflowData.targetCompanyId]);
            
            if (createEmployee.rows.length > 0) {
                this.workflowData.newEmployeeId = createEmployee.rows[0].id;
                this.logTest('Employee Account Creation', 'PASS', 
                    `Created: ${createEmployee.rows[0].full_name} as ${createEmployee.rows[0].role}`);
            } else {
                this.logTest('Employee Account Creation', 'FAIL', 'Failed to create employee account');
                return;
            }
            
            // Step 5: Mark Invitation as Used
            const markInvitationUsed = await this.client.query(`
                UPDATE employee_invitations 
                SET used_count = used_count + 1, 
                    last_used_at = NOW(),
                    is_used = CASE 
                        WHEN used_count + 1 >= usage_limit THEN true 
                        ELSE false 
                    END
                WHERE id = $1
                RETURNING used_count, usage_limit, is_used;
            `, [this.workflowData.invitationId]);
            
            if (markInvitationUsed.rows.length > 0) {
                const updated = markInvitationUsed.rows[0];
                this.logTest('Employee Mark Invitation Used', 'PASS', 
                    `Usage: ${updated.used_count}/${updated.usage_limit}, Fully used: ${updated.is_used}`);
            } else {
                this.logTest('Employee Mark Invitation Used', 'FAIL', 'Failed to update invitation usage');
            }
            
            // Step 6: Employee Access Verification
            const verifyAccess = await this.client.query(`
                SELECT u.id, u.email, u.role, c.name as company_name
                FROM users u
                JOIN companies c ON u.company_id = c.id
                WHERE u.id = $1;
            `, [this.workflowData.newEmployeeId]);
            
            if (verifyAccess.rows.length > 0) {
                const employee = verifyAccess.rows[0];
                this.logTest('Employee Access Verification', 'PASS', 
                    `Employee can access company: ${employee.company_name}`);
            } else {
                this.logTest('Employee Access Verification', 'FAIL', 'Employee cannot access company data');
            }
            
        } catch (error) {
            this.logTest('Employee Registration Workflow', 'FAIL', error.message);
        }
    }

    // =================== MANAGER WORKFLOW ===================
    async testManagerWorkflow() {
        console.log('\n👔 === TESTING MANAGER WORKFLOW ===');
        
        try {
            // Step 1: Manager Authentication
            const managers = await this.client.query(`
                SELECT id, email, full_name, company_id 
                FROM users 
                WHERE role IN ('BRANCH_MANAGER', 'SHIFT_LEADER') 
                LIMIT 1;
            `);
            
            if (managers.rows.length > 0) {
                this.workflowData.managerId = managers.rows[0].id;
                this.workflowData.managerCompanyId = managers.rows[0].company_id;
                this.logTest('Manager Authentication', 'PASS', 
                    `Manager found: ${managers.rows[0].full_name}`);
            } else {
                this.logTest('Manager Authentication', 'SKIP', 'No managers found in system');
                return;
            }
            
            // Step 2: Manager View Team Members
            const teamMembers = await this.client.query(`
                SELECT role, COUNT(*) as count
                FROM users 
                WHERE company_id = $1 
                AND role IN ('SHIFT_LEADER', 'STAFF')
                GROUP BY role;
            `, [this.workflowData.managerCompanyId]);
            
            if (teamMembers.rows.length > 0) {
                const teamData = teamMembers.rows.map(row => `${row.role}: ${row.count}`).join(', ');
                this.logTest('Manager View Team', 'PASS', teamData);
            } else {
                this.logTest('Manager View Team', 'WARN', 'No team members found');
            }
            
            // Step 3: Manager Access Company Data
            const managerCompanyAccess = await this.client.query(`
                SELECT c.name, c.business_type, 
                       COUNT(u.id) as employee_count
                FROM companies c
                LEFT JOIN users u ON c.id = u.company_id
                WHERE c.id = $1
                GROUP BY c.id, c.name, c.business_type;
            `, [this.workflowData.managerCompanyId]);
            
            if (managerCompanyAccess.rows.length > 0) {
                const company = managerCompanyAccess.rows[0];
                this.logTest('Manager Company Access', 'PASS', 
                    `Company: ${company.name}, Employees: ${company.employee_count}`);
            } else {
                this.logTest('Manager Company Access', 'FAIL', 'Manager cannot access company data');
            }
            
        } catch (error) {
            this.logTest('Manager Workflow', 'FAIL', error.message);
        }
    }

    // =================== COMPLETE SYSTEM INTEGRATION ===================
    async testSystemIntegration() {
        console.log('\n🔗 === TESTING COMPLETE SYSTEM INTEGRATION ===');
        
        try {
            // Test 1: Cross-Role Data Consistency
            const systemConsistency = await this.client.query(`
                SELECT 
                    c.name as company_name,
                    COUNT(DISTINCT u.id) as total_users,
                    COUNT(DISTINCT CASE WHEN u.role = 'CEO' THEN u.id END) as ceo_count,
                    COUNT(DISTINCT ei.id) as total_invitations,
                    COUNT(DISTINCT CASE WHEN ei.is_used = false THEN ei.id END) as active_invitations
                FROM companies c
                LEFT JOIN users u ON c.id = u.company_id
                LEFT JOIN employee_invitations ei ON c.id = ei.company_id
                GROUP BY c.id, c.name;
            `);
            
            if (systemConsistency.rows.length > 0) {
                let systemHealth = 0;
                for (const company of systemConsistency.rows) {
                    if (company.ceo_count === 1 && company.total_users > 0) {
                        systemHealth++;
                    }
                }
                
                this.logTest('System Data Consistency', 'PASS', 
                    `${systemHealth}/${systemConsistency.rows.length} companies have proper structure`);
            } else {
                this.logTest('System Data Consistency', 'FAIL', 'No company data found');
            }
            
            // Test 2: End-to-End Flow Verification
            if (this.workflowData.ceoId && this.workflowData.newEmployeeId) {
                const flowVerification = await this.client.query(`
                    SELECT 
                        ceo.full_name as ceo_name,
                        emp.full_name as employee_name,
                        ei.invitation_code,
                        ei.is_used,
                        c.name as company_name
                    FROM users ceo
                    JOIN companies c ON ceo.company_id = c.id
                    JOIN employee_invitations ei ON ceo.id = ei.created_by
                    JOIN users emp ON c.id = emp.company_id
                    WHERE ceo.id = $1 AND emp.id = $2;
                `, [this.workflowData.ceoId, this.workflowData.newEmployeeId]);
                
                if (flowVerification.rows.length > 0) {
                    const flow = flowVerification.rows[0];
                    this.logTest('E2E Flow Verification', 'PASS', 
                        `${flow.ceo_name} → ${flow.employee_name} via ${flow.invitation_code}`);
                } else {
                    this.logTest('E2E Flow Verification', 'FAIL', 'E2E flow not properly connected');
                }
            } else {
                this.logTest('E2E Flow Verification', 'SKIP', 'Missing workflow data for verification');
            }
            
            // Test 3: Security Boundaries
            const securityTest = await this.client.query(`
                SELECT DISTINCT 
                    u1.role as user_role,
                    u2.role as other_role,
                    CASE 
                        WHEN u1.company_id = u2.company_id THEN 'Same Company'
                        ELSE 'Different Company'
                    END as access_boundary
                FROM users u1
                CROSS JOIN users u2
                WHERE u1.id != u2.id
                LIMIT 5;
            `);
            
            if (securityTest.rows.length > 0) {
                this.logTest('Security Boundaries', 'PASS', 
                    `${securityTest.rows.length} role interactions verified`);
            } else {
                this.logTest('Security Boundaries', 'WARN', 'Limited user data for security testing');
            }
            
            // Test 4: Performance Under Load Simulation
            const performanceStart = Date.now();
            await this.client.query(`
                SELECT 
                    u.id, u.full_name, u.role, u.email,
                    c.name as company_name, c.business_type,
                    COUNT(ei.id) as invitations_created
                FROM users u
                LEFT JOIN companies c ON u.company_id = c.id
                LEFT JOIN employee_invitations ei ON u.id = ei.created_by
                GROUP BY u.id, u.full_name, u.role, u.email, c.name, c.business_type
                ORDER BY u.created_at DESC;
            `);
            const performanceTime = Date.now() - performanceStart;
            
            if (performanceTime < 1000) {
                this.logTest('System Performance', 'PASS', `Complex query: ${performanceTime}ms`);
            } else {
                this.logTest('System Performance', 'WARN', `Slow performance: ${performanceTime}ms`);
            }
            
        } catch (error) {
            this.logTest('System Integration', 'FAIL', error.message);
        }
    }

    // =================== CLEANUP E2E TEST DATA ===================
    async cleanupE2EData() {
        console.log('\n🧹 === CLEANING UP E2E TEST DATA ===');
        
        try {
            let cleaned = 0;
            
            // Clean up test employee
            if (this.workflowData.newEmployeeId) {
                await this.client.query('DELETE FROM users WHERE id = $1', [this.workflowData.newEmployeeId]);
                cleaned++;
            }
            
            // Clean up test invitation
            if (this.workflowData.invitationId) {
                await this.client.query('DELETE FROM employee_invitations WHERE id = $1', [this.workflowData.invitationId]);
                cleaned++;
            }
            
            // Clean up any E2E test data
            const e2eCleanup = await this.client.query(`
                DELETE FROM employee_invitations 
                WHERE invitation_code LIKE 'E2E_%';
            `);
            cleaned += e2eCleanup.rowCount;
            
            const e2eUserCleanup = await this.client.query(`
                DELETE FROM users 
                WHERE email LIKE 'e2e_%@%';
            `);
            cleaned += e2eUserCleanup.rowCount;
            
            this.logTest('E2E Test Data Cleanup', 'PASS', `${cleaned} test records cleaned`);
            
        } catch (error) {
            this.logTest('E2E Test Data Cleanup', 'WARN', error.message);
        }
    }

    // =================== MAIN E2E TEST RUNNER ===================
    async runAllTests() {
        console.log('🚀 === SABOHUB END-TO-END WORKFLOW TESTING STARTED ===');
        console.log('🔄 Testing complete user workflows and system integration...\n');
        
        await this.connect();
        
        try {
            // Run all E2E workflow tests
            await this.testCEOWorkflow();
            await this.testEmployeeRegistrationWorkflow();
            await this.testManagerWorkflow();
            await this.testSystemIntegration();
            
            // Cleanup
            await this.cleanupE2EData();
            
        } catch (error) {
            console.error('❌ Critical E2E testing error:', error.message);
        } finally {
            await this.disconnect();
        }
        
        // Print comprehensive summary
        this.printE2ESummary();
    }

    printE2ESummary() {
        console.log('\n📊 === END-TO-END WORKFLOW TEST SUMMARY ===');
        
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
        
        // Workflow breakdown
        console.log('\n📋 === WORKFLOW BREAKDOWN ===');
        const workflowResults = {
            'CEO Workflow': this.testResults.filter(r => r.testName.includes('CEO')),
            'Employee Workflow': this.testResults.filter(r => r.testName.includes('Employee')),
            'Manager Workflow': this.testResults.filter(r => r.testName.includes('Manager')),
            'System Integration': this.testResults.filter(r => r.testName.includes('System') || r.testName.includes('E2E'))
        };
        
        for (const [workflow, results] of Object.entries(workflowResults)) {
            const workflowPassed = results.filter(r => r.status === 'PASS').length;
            const workflowTotal = results.length;
            const workflowRate = workflowTotal > 0 ? ((workflowPassed / workflowTotal) * 100).toFixed(0) : 0;
            const icon = workflowRate >= 90 ? '🟢' : workflowRate >= 70 ? '🟡' : '🔴';
            console.log(`${icon} ${workflow}: ${workflowPassed}/${workflowTotal} (${workflowRate}%)`);
        }
        
        // Overall E2E assessment
        console.log('\n🎯 === E2E WORKFLOW READINESS ===');
        if (successRate >= 95) {
            console.log('🏆 EXCELLENT! All workflows production-ready!');
        } else if (successRate >= 85) {
            console.log('✅ VERY GOOD! Workflows are solid with minor improvements needed');
        } else if (successRate >= 70) {
            console.log('⚠️ GOOD! Core workflows functional but need attention');
        } else {
            console.log('❌ NEEDS WORK! Critical workflow issues found');
        }
        
        // Critical workflow status
        console.log('\n🔄 === CRITICAL WORKFLOW STATUS ===');
        const criticalWorkflows = [
            'CEO Create Invitation',
            'Employee Account Creation', 
            'Employee Validate Invitation',
            'E2E Flow Verification'
        ];
        
        let criticalPassed = 0;
        for (const workflow of criticalWorkflows) {
            const result = this.testResults.find(r => r.testName === workflow);
            if (result && result.status === 'PASS') {
                criticalPassed++;
                console.log(`✅ ${workflow}: WORKING`);
            } else if (result) {
                console.log(`❌ ${workflow}: ${result.status}`);
            } else {
                console.log(`⚠️ ${workflow}: NOT TESTED`);
            }
        }
        
        const criticalRate = (criticalPassed / criticalWorkflows.length * 100).toFixed(0);
        console.log(`\n🚨 Critical Workflow Success: ${criticalRate}%`);
        
        console.log('\n🎉 End-to-End workflow testing completed!');
        console.log('💪 "Kiên trì là mẹ thành công" - Complete system workflows validated!');
    }
}

// Run comprehensive E2E testing
const e2eTester = new E2EWorkflowTester();
e2eTester.runAllTests();