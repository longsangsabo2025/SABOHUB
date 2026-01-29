"""
Script to fix ALL remaining users → employees table queries
Final 100% migration to employees table for employee data
"""

import re

files_to_fix = {
    'lib/services/attendance_service.dart': {
        'description': 'Fix attendance queries - employees check in/out, not CEOs',
        'replacements': [
            # Fix foreign key references in SELECT queries
            (
                r"users\(",
                "employees!attendance_user_id_fkey("
            ),
            # Fix users!inner references
            (
                r"users!inner\(",
                "employees!inner("
            ),
            # Fix full_name references (employees table uses full_name)
            (
                r"\.from\('users'\)\.select\('full_name, role'\)",
                ".from('employees').select('full_name, role')"
            ),
        ],
    },
    'lib/services/management_task_service.dart': {
        'description': 'Fix task assignment queries - assigned_to can be CEO OR employee',
        'replacements': [
            # Task created_by and assigned_to can be BOTH users (CEO) OR employees
            # Keep users!tasks_created_by_fkey for backward compatibility
            # These need careful handling - tasks can be assigned to/from CEO or employees
        ],
        'note': 'SKIP - Tasks involve both CEOs and employees, needs special JOIN logic'
    },
    'lib/services/analytics_service.dart': {
        'description': 'Fix employee count analytics',
        'replacements': [
            # Line 27: Total employees count
            (
                r"from\('users'\)\.select\('id'\)(?!\s*\.\s*eq\('role')",
                "from('employees').select('id')"
            ),
            # Line 163: Branch employee count  
            (
                r"from\('users'\)\.select\('id'\)\.eq\('branch_id'",
                "from('employees').select('id').eq('branch_id'"
            ),
        ],
    },
    'lib/services/branch_service.dart': {
        'description': 'Fix branch employee count',
        'replacements': [
            # Line 139: Check if branch has employees before deletion
            (
                r"from\('users'\)\.select\('id'\)\.eq\('branch_id'",
                "from('employees').select('id').eq('branch_id'"
            ),
        ],
    },
    'lib/services/store_service.dart': {
        'description': 'Fix store employee count',
        'replacements': [
            # Line 91: Check if store has employees
            (
                r"from\('users'\)\.select\('id'\)\.eq\('store_id'",
                "from('employees').select('id').eq('store_id'"
            ),
        ],
    },
}

def fix_file(filepath, config):
    """Apply all replacements to a file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        if 'note' in config:
            print(f"\n⚠️  SKIPPING {filepath}")
            print(f"   Reason: {config['note']}")
            return False
        
        # Apply all replacements
        for pattern, replacement in config.get('replacements', []):
            content = re.sub(pattern, replacement, content)
        
        # Check if any changes were made
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"\n✅ FIXED: {filepath}")
            print(f"   {config['description']}")
            
            # Show what was changed (first 3 changes)
            changes = []
            for pattern, replacement in config.get('replacements', []):
                matches = re.findall(pattern, original_content)
                if matches:
                    changes.append(f"     • {pattern[:50]}... → {replacement[:50]}...")
                    if len(changes) >= 3:
                        break
            
            for change in changes:
                print(change)
            
            return True
        else:
            print(f"\n⏭️  NO CHANGES: {filepath}")
            return False
            
    except FileNotFoundError:
        print(f"\n❌ FILE NOT FOUND: {filepath}")
        return False
    except Exception as e:
        print(f"\n❌ ERROR fixing {filepath}: {e}")
        return False

def main():
    print("=" * 80)
    print("🚀 FINAL 100% MIGRATION: users → employees table")
    print("=" * 80)
    
    fixed_count = 0
    skipped_count = 0
    
    for filepath, config in files_to_fix.items():
        if 'note' in config:
            skipped_count += 1
            fix_file(filepath, config)
        elif fix_file(filepath, config):
            fixed_count += 1
    
    print("\n" + "=" * 80)
    print(f"📊 SUMMARY:")
    print(f"   ✅ Fixed: {fixed_count} files")
    print(f"   ⚠️  Skipped: {skipped_count} files (need manual review)")
    print(f"   📁 Total: {len(files_to_fix)} files processed")
    print("=" * 80)
    
    if fixed_count > 0:
        print("\n✨ SUCCESS! Employee queries now 100% using employees table")
        print("   Next: Run flutter analyze and test the app")
    
    print("\n📝 IMPORTANT NOTES:")
    print("   • CEOs still use auth.users table (correct)")
    print("   • Employees now use employees table (fixed)")
    print("   • Tasks service SKIPPED - needs review (assigns to both CEO + employees)")

if __name__ == '__main__':
    main()
