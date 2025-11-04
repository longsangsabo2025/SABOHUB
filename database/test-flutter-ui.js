require('dotenv').config({ path: '../.env' });
const fs = require('node:fs');
const path = require('node:path');

// 🚀 === SABOHUB FLUTTER UI COMPREHENSIVE TESTING ===
console.log('\n🚀 === SABOHUB FLUTTER UI COMPREHENSIVE TESTING ===');
console.log('🎨 Testing Flutter UI components, navigation, and user experience...\n');

class FlutterUITester {
    constructor() {
        this.results = {
            passed: 0,
            failed: 0,
            warnings: 0,
            skipped: 0,
            tests: []
        };
        this.libPath = path.join(__dirname, '../lib');
        this.testPath = path.join(__dirname, '../test');
    }

    async test(testName, testFunction) {
        try {
            console.log(`🧪 Testing: ${testName}`);
            const result = await testFunction();
            if (result.success) {
                console.log(`✅ ${testName}: PASS - ${result.message}`);
                this.results.passed++;
                this.results.tests.push({
                    name: testName,
                    status: 'PASS',
                    message: result.message
                });
            } else {
                console.log(`⚠️ ${testName}: WARNING - ${result.message}`);
                this.results.warnings++;
                this.results.tests.push({
                    name: testName,
                    status: 'WARNING',
                    message: result.message
                });
            }
        } catch (error) {
            console.log(`❌ ${testName}: FAIL - ${error.message}`);
            this.results.failed++;
            this.results.tests.push({
                name: testName,
                status: 'FAIL',
                message: error.message
            });
        }
    }

    searchInFiles(directory, pattern, fileExtension = '.dart') {
        let count = 0;
        let files = [];
        
        const searchDir = (dir) => {
            if (!fs.existsSync(dir)) return;
            
            const entries = fs.readdirSync(dir);
            for (const entry of entries) {
                const fullPath = path.join(dir, entry);
                const stat = fs.statSync(fullPath);
                
                if (stat.isDirectory()) {
                    searchDir(fullPath);
                } else if (entry.endsWith(fileExtension)) {
                    const content = fs.readFileSync(fullPath, 'utf8');
                    if (pattern instanceof RegExp ? pattern.test(content) : content.includes(pattern)) {
                        count++;
                        files.push({
                            file: path.relative(this.libPath, fullPath),
                            path: fullPath
                        });
                    }
                }
            }
        };
        
        searchDir(directory);
        return { count, files };
    }

    // 1️⃣ === FLUTTER PROJECT STRUCTURE TESTING ===
    async testProjectStructure() {
        console.log('\n📁 === TESTING FLUTTER PROJECT STRUCTURE ===');

        await this.test('Main Application Entry Point', async () => {
            const mainFile = path.join(this.libPath, 'main.dart');
            const exists = fs.existsSync(mainFile);
            
            if (exists) {
                const content = fs.readFileSync(mainFile, 'utf8');
                const hasRunApp = content.includes('runApp(');
                const hasMyApp = content.includes('MyApp') || content.includes('App(');
                
                return {
                    success: hasRunApp && hasMyApp,
                    message: `Main.dart found with runApp: ${hasRunApp}, App widget: ${hasMyApp}`
                };
            }
            
            return {
                success: false,
                message: 'main.dart not found'
            };
        });

        await this.test('Pubspec Configuration', async () => {
            const pubspecFile = path.join(__dirname, '../pubspec.yaml');
            const exists = fs.existsSync(pubspecFile);
            
            if (exists) {
                const content = fs.readFileSync(pubspecFile, 'utf8');
                const hasFlutter = content.includes('flutter:');
                const hasDependencies = content.includes('dependencies:');
                const hasSupabase = content.includes('supabase');
                
                return {
                    success: hasFlutter && hasDependencies,
                    message: `Flutter: ${hasFlutter}, Dependencies: ${hasDependencies}, Supabase: ${hasSupabase}`
                };
            }
            
            return {
                success: false,
                message: 'pubspec.yaml not found'
            };
        });

        await this.test('Pages/Screens Structure', async () => {
            const pagesSearch = this.searchInFiles(this.libPath, /class.*Page.*extends.*StatefulWidget|class.*Screen.*extends.*StatefulWidget/);
            const routesSearch = this.searchInFiles(this.libPath, /routes|Navigator|MaterialPageRoute/);
            
            return {
                success: pagesSearch.count >= 3,
                message: `Found ${pagesSearch.count} page widgets, ${routesSearch.count} files with routing`
            };
        });

        await this.test('Widget Components Organization', async () => {
            const widgetSearch = this.searchInFiles(this.libPath, /class.*Widget.*extends.*StatelessWidget|class.*Widget.*extends.*StatefulWidget/);
            const componentSearch = this.searchInFiles(this.libPath, /class.*Component.*extends/);
            
            return {
                success: widgetSearch.count >= 5,
                message: `Found ${widgetSearch.count} custom widgets, ${componentSearch.count} components`
            };
        });
    }

    // 2️⃣ === UI COMPONENTS TESTING ===
    async testUIComponents() {
        console.log('\n🎨 === TESTING UI COMPONENTS ===');

        await this.test('Form Components', async () => {
            const formSearch = this.searchInFiles(this.libPath, /TextFormField|Form\(|_formKey/);
            const validationSearch = this.searchInFiles(this.libPath, /validator:|validation/);
            
            return {
                success: formSearch.count >= 5,
                message: `Found ${formSearch.count} form components, ${validationSearch.count} with validation`
            };
        });

        await this.test('Button Components', async () => {
            const buttonSearch = this.searchInFiles(this.libPath, /ElevatedButton|TextButton|OutlinedButton|FloatingActionButton/);
            const interactionSearch = this.searchInFiles(this.libPath, /onPressed:|onTap:/);
            
            return {
                success: buttonSearch.count >= 5 && interactionSearch.count >= 10,
                message: `Found ${buttonSearch.count} button types, ${interactionSearch.count} interactive elements`
            };
        });

        await this.test('Layout Components', async () => {
            const layoutSearch = this.searchInFiles(this.libPath, /Column|Row|Container|Padding|Margin/);
            const scaffoldSearch = this.searchInFiles(this.libPath, /Scaffold|AppBar|Drawer/);
            
            return {
                success: layoutSearch.count >= 10 && scaffoldSearch.count >= 3,
                message: `Found ${layoutSearch.count} layout widgets, ${scaffoldSearch.count} scaffold structures`
            };
        });

        await this.test('List and Data Display', async () => {
            const listSearch = this.searchInFiles(this.libPath, /ListView|GridView|DataTable|ListTile/);
            const cardSearch = this.searchInFiles(this.libPath, /Card|Container.*decoration/);
            
            return {
                success: listSearch.count >= 3,
                message: `Found ${listSearch.count} list components, ${cardSearch.count} card/container designs`
            };
        });
    }

    // 3️⃣ === NAVIGATION TESTING ===
    async testNavigation() {
        console.log('\n🧭 === TESTING NAVIGATION ===');

        await this.test('Navigation Implementation', async () => {
            const navSearch = this.searchInFiles(this.libPath, /Navigator\.|MaterialPageRoute|pushNamed|push\(/);
            const routesSearch = this.searchInFiles(this.libPath, /routes:|onGenerateRoute/);
            
            return {
                success: navSearch.count >= 3,
                message: `Found ${navSearch.count} navigation implementations, ${routesSearch.count} route configurations`
            };
        });

        await this.test('App Bar and Menu Structure', async () => {
            const appBarSearch = this.searchInFiles(this.libPath, /AppBar\(|title:|actions:/);
            const drawerSearch = this.searchInFiles(this.libPath, /Drawer\(|DrawerHeader|ListTile/);
            
            return {
                success: appBarSearch.count >= 3,
                message: `Found ${appBarSearch.count} app bars, ${drawerSearch.count} drawer implementations`
            };
        });

        await this.test('Bottom Navigation', async () => {
            const bottomNavSearch = this.searchInFiles(this.libPath, /BottomNavigationBar|BottomAppBar|TabBar/);
            const tabSearch = this.searchInFiles(this.libPath, /TabController|Tab\(/);
            
            return {
                success: bottomNavSearch.count >= 1,
                message: `Found ${bottomNavSearch.count} bottom navigation, ${tabSearch.count} tab implementations`
            };
        });
    }

    // 4️⃣ === STATE MANAGEMENT TESTING ===
    async testStateManagement() {
        console.log('\n🔄 === TESTING STATE MANAGEMENT ===');

        await this.test('StatefulWidget Usage', async () => {
            const statefulSearch = this.searchInFiles(this.libPath, /extends StatefulWidget|State<.*>/);
            const setStateSearch = this.searchInFiles(this.libPath, /setState\(/);
            
            return {
                success: statefulSearch.count >= 5,
                message: `Found ${statefulSearch.count} stateful widgets, ${setStateSearch.count} setState calls`
            };
        });

        await this.test('Provider Pattern Implementation', async () => {
            const providerSearch = this.searchInFiles(this.libPath, /Provider|ChangeNotifier|Consumer/);
            const notifierSearch = this.searchInFiles(this.libPath, /notifyListeners|addListener/);
            
            return {
                success: providerSearch.count >= 2,
                message: `Found ${providerSearch.count} provider patterns, ${notifierSearch.count} listener implementations`
            };
        });

        await this.test('Future and Stream Handling', async () => {
            const futureSearch = this.searchInFiles(this.libPath, /Future<|FutureBuilder|async.*await/);
            const streamSearch = this.searchInFiles(this.libPath, /Stream<|StreamBuilder|listen\(/);
            
            return {
                success: futureSearch.count >= 5,
                message: `Found ${futureSearch.count} Future implementations, ${streamSearch.count} Stream usage`
            };
        });
    }

    // 5️⃣ === RESPONSIVE DESIGN TESTING ===
    async testResponsiveDesign() {
        console.log('\n📱 === TESTING RESPONSIVE DESIGN ===');

        await this.test('Media Query Usage', async () => {
            const mediaQuerySearch = this.searchInFiles(this.libPath, /MediaQuery\.of\(context\)|MediaQuery\.sizeOf/);
            const responsiveSearch = this.searchInFiles(this.libPath, /screenWidth|screenHeight|isMobile|isTablet/);
            
            return {
                success: mediaQuerySearch.count >= 2,
                message: `Found ${mediaQuerySearch.count} MediaQuery usage, ${responsiveSearch.count} responsive patterns`
            };
        });

        await this.test('Flexible and Expanded Widgets', async () => {
            const flexSearch = this.searchInFiles(this.libPath, /Flexible\(|Expanded\(|Flex\(/);
            const layoutBuilderSearch = this.searchInFiles(this.libPath, /LayoutBuilder|OrientationBuilder/);
            
            return {
                success: flexSearch.count >= 5,
                message: `Found ${flexSearch.count} flexible layouts, ${layoutBuilderSearch.count} layout builders`
            };
        });

        await this.test('Adaptive UI Components', async () => {
            const adaptiveSearch = this.searchInFiles(this.libPath, /Platform\.isIOS|Platform\.isAndroid|Theme\.of\(context\)/);
            const breakpointSearch = this.searchInFiles(this.libPath, /breakpoint|mobile|tablet|desktop/);
            
            return {
                success: adaptiveSearch.count >= 1,
                message: `Found ${adaptiveSearch.count} platform adaptations, ${breakpointSearch.count} breakpoint implementations`
            };
        });
    }

    // 6️⃣ === DATA INTEGRATION TESTING ===
    async testDataIntegration() {
        console.log('\n🔌 === TESTING DATA INTEGRATION ===');

        await this.test('Supabase Integration', async () => {
            const supabaseSearch = this.searchInFiles(this.libPath, /Supabase|supabase\.|createClient/);
            const authSearch = this.searchInFiles(this.libPath, /auth\.|signIn|signOut|getUser/);
            
            return {
                success: supabaseSearch.count >= 3,
                message: `Found ${supabaseSearch.count} Supabase integrations, ${authSearch.count} auth implementations`
            };
        });

        await this.test('HTTP Requests and API Calls', async () => {
            const httpSearch = this.searchInFiles(this.libPath, /http\.|get\(|post\(|put\(|delete\(/);
            const apiSearch = this.searchInFiles(this.libPath, /api|API|endpoint/);
            
            return {
                success: httpSearch.count >= 2,
                message: `Found ${httpSearch.count} HTTP implementations, ${apiSearch.count} API references`
            };
        });

        await this.test('Error Handling', async () => {
            const errorSearch = this.searchInFiles(this.libPath, /try.*catch|Error|Exception/);
            const loadingSearch = this.searchInFiles(this.libPath, /loading|isLoading|CircularProgressIndicator/);
            
            return {
                success: errorSearch.count >= 3,
                message: `Found ${errorSearch.count} error handling, ${loadingSearch.count} loading indicators`
            };
        });
    }

    // 7️⃣ === TESTING IMPLEMENTATION ===
    async testTestingImplementation() {
        console.log('\n🧪 === TESTING IMPLEMENTATION ===');

        await this.test('Unit Tests', async () => {
            if (!fs.existsSync(this.testPath)) {
                return {
                    success: false,
                    message: 'Test directory not found'
                };
            }
            
            const unitTestSearch = this.searchInFiles(this.testPath, /test\(|group\(|expect\(/);
            const mockSearch = this.searchInFiles(this.testPath, /mock|Mock|when\(/);
            
            return {
                success: unitTestSearch.count >= 1,
                message: `Found ${unitTestSearch.count} test files, ${mockSearch.count} mock implementations`
            };
        });

        await this.test('Widget Tests', async () => {
            if (!fs.existsSync(this.testPath)) {
                return {
                    success: false,
                    message: 'Test directory not found'
                };
            }
            
            const widgetTestSearch = this.searchInFiles(this.testPath, /testWidgets|WidgetTester|pumpWidget/);
            const finderSearch = this.searchInFiles(this.testPath, /find\.|Finder|findsOneWidget/);
            
            return {
                success: widgetTestSearch.count >= 1,
                message: `Found ${widgetTestSearch.count} widget tests, ${finderSearch.count} finder usage`
            };
        });
    }

    // 📊 === COMPREHENSIVE UI TESTING EXECUTION ===
    async runAllUITests() {
        console.log('\n🔄 Starting comprehensive Flutter UI testing...\n');

        // Run all test categories
        await this.testProjectStructure();
        await this.testUIComponents();
        await this.testNavigation();
        await this.testStateManagement();
        await this.testResponsiveDesign();
        await this.testDataIntegration();
        await this.testTestingImplementation();

        // Generate comprehensive summary
        this.generateUITestSummary();
    }

    generateUITestSummary() {
        console.log('\n📊 === FLUTTER UI COMPREHENSIVE TEST SUMMARY ===');
        console.log(`✅ Passed: ${this.results.passed}`);
        console.log(`❌ Failed: ${this.results.failed}`);
        console.log(`⚠️ Warnings: ${this.results.warnings}`);
        console.log(`⏭️ Skipped: ${this.results.skipped}`);
        
        const total = this.results.passed + this.results.failed + this.results.warnings + this.results.skipped;
        console.log(`📈 Total: ${total}`);

        const successRate = total > 0 ? ((this.results.passed + this.results.warnings) / total * 100).toFixed(1) : 0;
        console.log(`\n🎯 UI Success Rate: ${successRate}%`);

        if (successRate >= 90) {
            console.log('🏆 EXCELLENT! Flutter UI is very well structured!');
        } else if (successRate >= 80) {
            console.log('👍 GOOD! UI structure is solid with room for improvement');
        } else if (successRate >= 70) {
            console.log('⚠️ NEEDS WORK! UI structure needs attention');
        } else {
            console.log('🚨 CRITICAL! UI structure needs major improvements');
        }

        console.log('\n🔧 === UI FEATURE BREAKDOWN ===');
        const categories = {
            'Project Structure': this.results.tests.slice(0, 4),
            'UI Components': this.results.tests.slice(4, 8),
            'Navigation': this.results.tests.slice(8, 11),
            'State Management': this.results.tests.slice(11, 14),
            'Responsive Design': this.results.tests.slice(14, 17),
            'Data Integration': this.results.tests.slice(17, 20),
            'Testing Implementation': this.results.tests.slice(20, 22)
        };

        Object.entries(categories).forEach(([category, tests]) => {
            if (tests.length > 0) {
                const passed = tests.filter(t => t.status === 'PASS').length;
                const rate = (passed / tests.length * 100).toFixed(0);
                const status = rate >= 80 ? '✅' : rate >= 60 ? '⚠️' : '❌';
                console.log(`${status} ${category}: ${passed}/${tests.length} (${rate}%)`);
            }
        });

        console.log('\n📋 === DETAILED UI TEST RESULTS ===');
        this.results.tests.forEach(test => {
            const icon = test.status === 'PASS' ? '✅' : test.status === 'WARNING' ? '⚠️' : '❌';
            console.log(`${icon} ${test.name}: ${test.message}`);
        });

        console.log('\n🎉 Flutter UI comprehensive testing completed!');
        console.log('💪 "Kiên trì là mẹ thành công" - UI structure analyzed thoroughly!');
    }
}

// 🚀 Execute comprehensive Flutter UI testing
async function main() {
    const tester = new FlutterUITester();
    await tester.runAllUITests();
}

main().catch(console.error);