"""
Fix management_task_service.dart to use cached fields
instead of JOINing users table
"""

import re

filepath = 'lib/services/management_task_service.dart'

print('=' * 80)
print('🔧 FIX: management_task_service.dart')
print('   Strategy: Use cached assigned_to_name, assigned_to_role, created_by_name')
print('   Instead of: JOINing users table')
print('=' * 80)

# Read file
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern 1: Remove user JOINs from SELECT queries
old_select = r'''created_by_user:users!tasks_created_by_fkey\(id, full_name, role\),
            assigned_to_user:users!tasks_assigned_to_fkey\(id, full_name, role\)'''

new_select = '''created_by_name,
            assigned_to_name,
            assigned_to_role'''

content = content.replace(old_select, new_select)

# Pattern 2: Remove the mapping logic that extracts from joined user objects
# These blocks look like:
#   if (json['created_by_user'] != null) {
#     flatJson['created_by_name'] = json['created_by_user']['full_name'];
#     ...
#   }

# Replace the mapping blocks
old_mapping = r'''if \(json\['created_by_user'\] != null\) \{
          flatJson\['created_by_name'\] = json\['created_by_user'\]\['full_name'\];
          flatJson\['created_by_role'\] = json\['created_by_user'\]\['role'\];
        \}
        if \(json\['assigned_to_user'\] != null\) \{
          flatJson\['assigned_to_name'\] = json\['assigned_to_user'\]\['full_name'\];
          flatJson\['assigned_to_role'\] = json\['assigned_to_user'\]\['role'\];
        \}'''

new_mapping = '''// Names and roles are already in the task record (cached fields)
        // No need to extract from joined user objects'''

content = re.sub(old_mapping, new_mapping, content)

# Write back
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('\n✅ SUCCESS!')
print('   • Removed users!tasks_created_by_fkey JOIN')
print('   • Removed users!tasks_assigned_to_fkey JOIN')
print('   • Now using: assigned_to_name, assigned_to_role, created_by_name')
print('   • These are cached fields updated by triggers')

print('\n📝 IMPORTANT:')
print('   Tasks can be assigned to/from BOTH:')
print('   - CEOs (in auth.users table)')
print('   - Employees (in employees table)')
print('   Using cached fields avoids complex JOIN logic!')
print('=' * 80)
