"""
Script to find and report all risky .single() usage in Dart files
These are queries that might return 0 results and should use .maybeSingle() instead
"""

import os
import re

# Patterns that indicate risky .single() usage
RISKY_PATTERNS = [
    # SELECT with .eq() on user/employee/company lookup
    (r'\.eq\([\'"](?:id|user_id|employee_id|company_id|owner_id)[\'"].*?\.single\(\)', 
     'ID lookup - might not exist'),
    
    # SELECT with multiple conditions
    (r'\.select\(.*?\)\.eq\(.*?\)\.eq\(.*?\.single\(\)',
     'Multiple conditions - might not match'),
]

def find_risky_single_usage(file_path):
    """Find risky .single() usage in a Dart file"""
    risky_lines = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines, 1):
            # Skip if already using maybeSingle
            if 'maybeSingle()' in line:
                continue
                
            # Check if line has .single()
            if '.single()' in line:
                # Skip INSERT/UPDATE operations (these should always return a result)
                if '.insert(' in line or '.update(' in line:
                    # Unless it's a complex case
                    if '.eq(' not in line and '.match(' not in line:
                        continue
                
                # This is potentially risky
                risky_lines.append({
                    'line_num': i,
                    'line': line.strip(),
                    'file': file_path
                })
    
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    
    return risky_lines

def scan_directory(directory):
    """Scan directory for Dart files"""
    all_risky = []
    
    for root, dirs, files in os.walk(directory):
        # Skip test and generated files
        if 'test' in root or '.dart_tool' in root or 'generated' in root:
            continue
            
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                risky = find_risky_single_usage(file_path)
                if risky:
                    all_risky.extend(risky)
    
    return all_risky

if __name__ == '__main__':
    print("🔍 Scanning for risky .single() usage...")
    print("=" * 80)
    
    lib_dir = 'lib'
    risky_usage = scan_directory(lib_dir)
    
    print(f"\n📊 Found {len(risky_usage)} potentially risky .single() usages\n")
    
    # Group by file
    by_file = {}
    for item in risky_usage:
        file = item['file']
        if file not in by_file:
            by_file[file] = []
        by_file[file].append(item)
    
    # Print grouped results
    for file, items in sorted(by_file.items()):
        print(f"\n📄 {file}")
        print("-" * 80)
        for item in items:
            print(f"  Line {item['line_num']:4d}: {item['line'][:100]}")
    
    print("\n" + "=" * 80)
    print(f"Total files with risky usage: {len(by_file)}")
    print(f"Total risky .single() calls: {len(risky_usage)}")
    print("\n⚠️  These should be reviewed and potentially changed to .maybeSingle()")
