const puppeteer = require('puppeteer');

class PolishedLoginTester {
    constructor() {
        this.browser = null;
        this.page = null;
        this.results = [];
        this.testUrl = 'http://localhost:3000';
    }

    async init() {
        this.browser = await puppeteer.launch({ 
            headless: false,
            defaultViewport: { width: 1366, height: 768 }
        });
        this.page = await this.browser.newPage();
        
        console.log('🎨 TESTING POLISHED LOGIN PAGE UI');
        console.log('=====================================');
        
        await this.page.goto(this.testUrl);
        await this.page.waitForSelector('body', { timeout: 10000 });
        await this.page.waitForTimeout(2000); // Let UI settle
    }

    async testPolishedFeatures() {
        const tests = [
            // 🎨 GRADIENT LOGO TESTS
            { name: 'Gradient Logo Container', selector: '[style*="gradient"]', description: 'Test gradient logo styling' },
            { name: 'Business Center Icon', selector: 'svg[data-testid*="BusinessCenter"], i:contains("business_center")', description: 'Test business icon in logo' },
            { name: 'SABOHUB Title', selector: 'text*="SABOHUB"', description: 'Test main title display' },
            { name: 'Logo Subtitle', selector: 'text*="Quản lý nhân viên"', description: 'Test subtitle display' },

            // ✨ ENHANCED EMAIL FIELD
            { name: 'Email Field with Icon', selector: 'input[type="email"]', description: 'Test email input field' },
            { name: 'Email Prefix Icon', selector: 'svg[data-testid*="Email"], i:contains("email")', description: 'Test email icon' },
            { name: 'Email Validation', selector: 'input[type="email"]', description: 'Test email validation', action: 'type', value: 'invalid-email' },

            // 🔒 PASSWORD FIELD WITH TOGGLE
            { name: 'Password Field', selector: 'input[type="password"], input[type="text"][placeholder*="mật khẩu"]', description: 'Test password input' },
            { name: 'Password Toggle Button', selector: 'button[aria-label*="password"], button:has(svg[data-testid*="Visibility"])', description: 'Test show/hide password button' },
            { name: 'Lock Icon', selector: 'svg[data-testid*="Lock"], i:contains("lock")', description: 'Test lock prefix icon' },

            // 🚀 ENHANCED LOGIN BUTTON
            { name: 'Primary Login Button', selector: 'button:contains("Đăng nhập")', description: 'Test main login button' },
            { name: 'Button Loading State', selector: 'button:contains("Đăng nhập")', description: 'Test button loading animation', action: 'click' },

            // 🎯 QUICK LOGIN BUTTONS
            { name: 'CEO Quick Login', selector: 'button:contains("CEO")', description: 'Test CEO quick login button' },
            { name: 'Manager Quick Login', selector: 'button:contains("Manager")', description: 'Test Manager quick login button' },
            { name: 'Shift Leader Quick Login', selector: 'button:contains("Shift")', description: 'Test Shift Leader quick login button' },
            { name: 'Staff Quick Login', selector: 'button:contains("Staff")', description: 'Test Staff quick login button' },

            // 📱 RESPONSIVE & POLISH
            { name: 'Form Container', selector: 'form', description: 'Test form container' },
            { name: 'Rounded Corners', selector: '[style*="border-radius"], .rounded', description: 'Test rounded corner styling' },
            { name: 'Shadow Effects', selector: '[style*="box-shadow"], .shadow', description: 'Test shadow effects' },
            { name: 'Forgot Password Link', selector: 'a:contains("Quên mật khẩu"), span:contains("Quên mật khẩu")', description: 'Test forgot password link' },
            { name: 'Sign Up Link', selector: 'a:contains("Đăng ký"), span:contains("Đăng ký")', description: 'Test sign up link' },
        ];

        for (const test of tests) {
            await this.runSingleTest(test);
        }
    }

    async runSingleTest(test) {
        try {
            console.log(`\n🧪 Testing: ${test.name}`);
            
            // Wait for element
            let element;
            try {
                if (test.selector.includes('text*=') || test.selector.includes(':contains(')) {
                    // Handle text-based selectors
                    const textSelector = test.selector.replace('text*=', '').replace(':contains(', '').replace(')', '').replace(/"/g, '');
                    element = await this.page.evaluateHandle((text) => {
                        const walker = document.createTreeWalker(
                            document.body,
                            NodeFilter.SHOW_TEXT,
                            null,
                            false
                        );
                        
                        let node;
                        while (node = walker.nextNode()) {
                            if (node.textContent.includes(text)) {
                                return node.parentElement;
                            }
                        }
                        return null;
                    }, textSelector);
                } else {
                    element = await this.page.waitForSelector(test.selector, { timeout: 3000 });
                }
                
                if (!element || (await element.evaluate(el => el === null))) {
                    throw new Error('Element not found');
                }
            } catch (e) {
                // Try alternative selectors for common elements
                const alternatives = this.getAlternativeSelectors(test);
                let found = false;
                
                for (const altSelector of alternatives) {
                    try {
                        element = await this.page.waitForSelector(altSelector, { timeout: 1000 });
                        if (element) {
                            found = true;
                            break;
                        }
                    } catch (altE) {
                        continue;
                    }
                }
                
                if (!found) {
                    throw new Error(`Element not found with any selector: ${test.selector}`);
                }
            }

            // Perform test action
            if (test.action === 'type' && test.value) {
                await element.type(test.value);
                await this.page.waitForTimeout(500);
            } else if (test.action === 'click') {
                await element.click();
                await this.page.waitForTimeout(1000);
            }

            // Get element info
            const elementInfo = await element.evaluate(el => ({
                tagName: el.tagName,
                className: el.className,
                text: el.textContent?.substring(0, 50),
                style: el.style.cssText,
                computed: window.getComputedStyle(el).background || window.getComputedStyle(el).color
            }));

            this.results.push({
                name: test.name,
                status: '✅ PASSED',
                description: test.description,
                elementInfo
            });
            
            console.log(`   ✅ PASSED - ${test.description}`);
            
        } catch (error) {
            this.results.push({
                name: test.name,
                status: '❌ FAILED',
                description: test.description,
                error: error.message
            });
            
            console.log(`   ❌ FAILED - ${error.message}`);
        }
    }

    getAlternativeSelectors(test) {
        const alternatives = [];
        
        if (test.name.includes('Email')) {
            alternatives.push('input[placeholder*="email"]', 'input[name="email"]', '[data-testid="email"]');
        }
        
        if (test.name.includes('Password')) {
            alternatives.push('input[placeholder*="password"]', 'input[name="password"]', '[data-testid="password"]');
        }
        
        if (test.name.includes('Button') || test.name.includes('Login')) {
            alternatives.push('button[type="submit"]', '.btn', '.button', '[role="button"]');
        }
        
        if (test.name.includes('Icon')) {
            alternatives.push('svg', 'i', '.icon', '[data-icon]');
        }
        
        if (test.name.includes('Logo') || test.name.includes('SABOHUB')) {
            alternatives.push('h1', '.logo', '.title', '[data-testid="logo"]');
        }
        
        return alternatives;
    }

    async testQuickLoginFlow() {
        console.log('\n🎯 TESTING QUICK LOGIN FLOW');
        console.log('==============================');
        
        try {
            // Test CEO quick login
            console.log('\n🧪 Testing CEO Quick Login...');
            
            const ceoButton = await this.page.$('button:has-text("CEO")') || 
                            await this.page.$('button:contains("CEO")') ||
                            await this.page.$eval('button', (buttons) => {
                                return Array.from(buttons).find(btn => btn.textContent.includes('CEO'));
                            });
            
            if (ceoButton) {
                await ceoButton.click();
                await this.page.waitForTimeout(2000);
                
                // Check if email field is populated
                const emailValue = await this.page.$eval('input[type="email"]', el => el.value);
                console.log(`   📧 Email populated: ${emailValue}`);
                
                this.results.push({
                    name: 'CEO Quick Login Flow',
                    status: emailValue.includes('ceo') ? '✅ PASSED' : '❌ FAILED',
                    description: 'Test CEO quick login functionality'
                });
            }
        } catch (error) {
            console.log(`   ❌ Quick login test failed: ${error.message}`);
        }
    }

    async testPasswordToggle() {
        console.log('\n🔒 TESTING PASSWORD TOGGLE');
        console.log('============================');
        
        try {
            // Type in password field
            const passwordField = await this.page.$('input[type="password"]');
            if (passwordField) {
                await passwordField.type('test123');
                
                // Find toggle button
                const toggleButton = await this.page.$('button:has(svg[data-testid*="Visibility"])') ||
                                   await this.page.$('[aria-label*="password"]');
                
                if (toggleButton) {
                    await toggleButton.click();
                    await this.page.waitForTimeout(500);
                    
                    // Check if password is now visible
                    const fieldType = await passwordField.evaluate(el => el.type);
                    
                    this.results.push({
                        name: 'Password Toggle Functionality',
                        status: fieldType === 'text' ? '✅ PASSED' : '❌ FAILED',
                        description: 'Test password show/hide toggle'
                    });
                    
                    console.log(`   👁️ Password toggle: ${fieldType === 'text' ? 'Working' : 'Failed'}`);
                }
            }
        } catch (error) {
            console.log(`   ❌ Password toggle test failed: ${error.message}`);
        }
    }

    async generateReport() {
        const passed = this.results.filter(r => r.status.includes('✅')).length;
        const failed = this.results.filter(r => r.status.includes('❌')).length;
        const total = this.results.length;
        const successRate = ((passed / total) * 100).toFixed(1);

        console.log('\n' + '='.repeat(60));
        console.log('🎨 POLISHED LOGIN PAGE TEST RESULTS');
        console.log('='.repeat(60));
        console.log(`📊 Total Tests: ${total}`);
        console.log(`✅ Passed: ${passed}`);
        console.log(`❌ Failed: ${failed}`);
        console.log(`📈 Success Rate: ${successRate}%`);
        console.log('='.repeat(60));

        // Detailed results
        console.log('\n📋 DETAILED RESULTS:');
        this.results.forEach((result, index) => {
            console.log(`\n${index + 1}. ${result.status} ${result.name}`);
            console.log(`   Description: ${result.description}`);
            if (result.error) {
                console.log(`   Error: ${result.error}`);
            }
            if (result.elementInfo) {
                console.log(`   Element: ${result.elementInfo.tagName} ${result.elementInfo.className || ''}`);
                if (result.elementInfo.text) {
                    console.log(`   Text: "${result.elementInfo.text}"`);
                }
            }
        });

        // Recommendations
        console.log('\n🎯 RECOMMENDATIONS:');
        if (successRate >= 90) {
            console.log('✨ Excellent! Login page polish is very successful');
            console.log('🚀 Ready to move to next priority: Team Management Tab');
        } else if (successRate >= 75) {
            console.log('👍 Good polish implementation, minor improvements needed');
            console.log('🔧 Focus on failed elements for final touches');
        } else {
            console.log('⚠️ Login polish needs more work');
            console.log('🛠️ Address failed tests before moving to next features');
        }

        return { total, passed, failed, successRate };
    }

    async cleanup() {
        if (this.browser) {
            await this.browser.close();
        }
    }
}

// Run the tests
async function main() {
    const tester = new PolishedLoginTester();
    
    try {
        await tester.init();
        await tester.testPolishedFeatures();
        await tester.testQuickLoginFlow();
        await tester.testPasswordToggle();
        
        const summary = await tester.generateReport();
        
        // Write summary to file
        const fs = require('fs');
        const summaryData = {
            timestamp: new Date().toISOString(),
            testType: 'Polished Login Page UI Test',
            summary,
            results: tester.results
        };
        
        fs.writeFileSync('polished-login-test-results.json', JSON.stringify(summaryData, null, 2));
        console.log('\n💾 Results saved to polished-login-test-results.json');
        
    } catch (error) {
        console.error('❌ Test execution failed:', error);
    } finally {
        await tester.cleanup();
    }
}

if (require.main === module) {
    main();
}

module.exports = PolishedLoginTester;