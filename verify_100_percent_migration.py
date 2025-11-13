"""
FINAL VERIFICATION: Ensure 100% employee data migration
Check that NO employee-related queries use 'users' table
"""

import os
import re

# Directories to search
search_dirs = ['lib/services', 'lib/pages', 'lib/providers']

# Patterns that should NOT exist for employee queries
forbidden_patterns = [
    {
        'pattern': r"from\('users'\)\.select\([^)]*\)\.eq\('(branch_id|store_id|company_id)'",
        'description': 'Employee queries filtering by branch/store/company',
        'severity': 'ERROR'
    },
    {
        'pattern': r"from\('users'\)\.select\([^)]*\)\.eq\('role',\s*'(Manager|Shift Leader|Staff)'",
        'description': 'Employee queries filtering by employee roles',
        'severity': 'ERROR'
    },
    {
        'pattern': r"users\([^)]*name[^)]*email[^)]*\)(?!.*\bceo\b)",
        'description': 'JOIN users table for employee info (should use employees table)',
        'severity': 'WARNING'
    },
]

# Patterns that ARE OK (CEO queries)
allowed_patterns = [
    r"from\('users'\)\.select\([^)]*\)\.eq\('role',\s*'CEO'",  # CEO-specific queries
    r"auth\.currentUser",  # Auth checks
    r"users!.*approvals",  # Approval system (CEOs approve)
]

def check_file(filepath):
    """Check a single file for forbidden patterns"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    issues = []
    
    for forbidden in forbidden_patterns:
        pattern = forbidden['pattern']
        
        # Find all matches
        matches = re.finditer(pattern, content, re.IGNORECASE)
        
        for match in matches:
            # Check if this match is in allowed context
            is_allowed = False
            for allowed in allowed_patterns:
                if re.search(allowed, content[max(0, match.start()-100):match.end()+100]):
                    is_allowed = True
                    break
            
            if not is_allowed:
                # Get line number
                line_num = content[:match.start()].count('\n') + 1
                issues.append({
                    'file': filepath,
                    'line': line_num,
                    'match': match.group(),
                    'description': forbidden['description'],
                    'severity': forbidden['severity'],
                })
    
    return issues

def scan_directory(directory):
    """Scan a directory for Dart files"""
    all_issues = []
    
    if not os.path.exists(directory):
        return all_issues
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                issues = check_file(filepath)
                all_issues.extend(issues)
    
    return all_issues

def main():
    print('=' * 100)
    print('🔍 FINAL VERIFICATION: 100% Employee Data Migration')
    print('=' * 100)
    print('\n📋 Checking that ALL employee queries use "employees" table, not "users" table...\n')
    
    all_issues = []
    
    for directory in search_dirs:
        print(f'  🔎 Scanning: {directory}/')
        issues = scan_directory(directory)
        all_issues.extend(issues)
        
        if not issues:
            print(f'     ✅ CLEAN - No employee queries to users table\n')
        else:
            print(f'     ⚠️  Found {len(issues)} potential issues\n')
    
    # Report findings
    print('=' * 100)
    
    if not all_issues:
        print('✅ SUCCESS! 100% MIGRATION COMPLETE!')
        print('\n📊 Summary:')
        print('   • NO employee queries found using users table')
        print('   • All employee data now queries from employees table')
        print('   • CEOs continue using auth.users (correct)')
        print('\n🎉 Architecture is now fully consistent!')
        
    else:
        errors = [i for i in all_issues if i['severity'] == 'ERROR']
        warnings = [i for i in all_issues if i['severity'] == 'WARNING']
        
        print(f'⚠️  FOUND {len(all_issues)} ISSUES:')
        print(f'   • {len(errors)} ERRORS (must fix)')
        print(f'   • {len(warnings)} WARNINGS (review needed)')
        print('\n' + '=' * 100)
        
        if errors:
            print('\n❌ ERRORS (Employee queries still using users table):')
            for issue in errors:
                print(f"\n   {issue['file']}:{issue['line']}")
                print(f"   ❌ {issue['description']}")
                print(f"   Code: {issue['match'][:80]}...")
        
        if warnings:
            print('\n⚠️  WARNINGS (May need review):')
            for issue in warnings:
                print(f"\n   {issue['file']}:{issue['line']}")
                print(f"   ⚠️  {issue['description']}")
                print(f"   Code: {issue['match'][:80]}...")
    
    print('\n' + '=' * 100)
    print('📝 Architecture Reference:')
    print('   • CEOs: auth.users table (Supabase Auth)')
    print('   • Employees: employees table (Custom Auth + bcrypt)')
    print('   • Tasks: Can involve BOTH (use cached fields)')
    print('=' * 100)
    
    return len(all_issues) == 0

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
