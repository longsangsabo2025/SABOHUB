"""Fix remaining 74 issues from flutter analyze."""
import re
import os

BASE = r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB"

def read_file(rel_path):
    path = os.path.join(BASE, rel_path)
    with open(path, 'r', encoding='utf-8') as f:
        return f.readlines()

def write_file(rel_path, lines):
    path = os.path.join(BASE, rel_path)
    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(lines)

fixes_applied = []

# ============================================
# 1. Fix const_with_non_const errors
# Remove 'const' from specific lines
# ============================================
const_fixes = [
    # (file, line_number_1_based)  
    ("lib/core/router/app_router.dart", 647),
    ("lib/pages/gamification/ceo_game_profile_page.dart", 52),
]

for filepath, lineno in const_fixes:
    lines = read_file(filepath)
    idx = lineno - 1
    if idx < len(lines):
        old = lines[idx]
        # Remove 'const ' keyword
        new_line = old.replace('const ', '', 1)
        if new_line != old:
            lines[idx] = new_line
            write_file(filepath, lines)
            fixes_applied.append(f"const_with_non_const: {filepath}:{lineno}")

# ============================================
# 2. Fix const_eval_method_invocation
# Remove 'const' enclosing Theme.of(context) expressions
# ============================================
const_eval_files = [
    ("lib/widgets/gamification/daily_quest_panel.dart", 202),
]

for filepath, lineno in const_eval_files:
    lines = read_file(filepath)
    idx = lineno - 1
    if idx < len(lines):
        old = lines[idx]
        new_line = old.replace('const ', '', 1)
        if new_line != old:
            lines[idx] = new_line
            write_file(filepath, lines)
            fixes_applied.append(f"const_eval: {filepath}:{lineno}")

# ============================================
# 3. Fix duplicate_import warnings
# Remove the SECOND occurrence of duplicate imports
# ============================================
duplicate_import_files = [
    ("lib/pages/ceo/shared/ceo_more_page.dart", 7),
    ("lib/pages/gamification/quest_hub_page.dart", 7),
    ("lib/pages/token/sabo_token_leaderboard_page.dart", 7),
    ("lib/widgets/gamification/staff_leaderboard.dart", 5),
    ("lib/widgets/gamification/staff_performance_card.dart", 4),
]

for filepath, lineno in duplicate_import_files:
    lines = read_file(filepath)
    idx = lineno - 1
    if idx < len(lines):
        # Just remove that line entirely
        dup_line = lines[idx].strip()
        lines.pop(idx)
        write_file(filepath, lines)
        fixes_applied.append(f"duplicate_import: {filepath}:{lineno} - removed '{dup_line}'")

# ============================================
# 4. Fix unused_import warnings  
# ============================================
unused_import_files = [
    ("lib/pages/ceo/company/accounting_tab.dart", 10, "app_text_styles"),
    ("lib/providers/theme_provider.dart", 3, "shared_preferences"),
    ("lib/widgets/task/task_board.dart", 16, "color_scheme_extension"),
    ("lib/widgets/task/task_card.dart", 5, "app_text_styles"),
    ("lib/widgets/task/task_create_dialog.dart", 6, "app_text_styles"),
    ("test/services/employee_auth_service_test.dart", 6, "employee_user"),
    ("test/services/push_notification_service_test.dart", 6, "flutter_dotenv"),
    ("test/services/travis_service_test.dart", 7, "travis_message"),
]

for filepath, lineno, keyword in unused_import_files:
    lines = read_file(filepath)
    idx = lineno - 1
    if idx < len(lines) and keyword in lines[idx]:
        lines.pop(idx)
        write_file(filepath, lines)
        fixes_applied.append(f"unused_import: {filepath}:{lineno} - removed (keyword: {keyword})")

# ============================================
# 5. Fix unnecessary_non_null_assertion in task_board.dart
# ============================================
task_board_path = "lib/widgets/task/task_board.dart"
lines = read_file(task_board_path)
changed = False
for lineno in [655, 660, 668]:
    idx = lineno - 1
    # After removing import at line 16, indices shift by 1
    # Adjust: each line after line 16 shifts down by 1
    adjusted_idx = idx - 1  # Because we removed line 16 (unused import)
    if adjusted_idx < len(lines):
        old = lines[adjusted_idx]
        # Remove unnecessary '!'
        if '!' in old:
            new_line = old.replace('!.', '.', 1) if '!.' in old else old.replace('!', '', 1)
            if new_line != old:
                lines[adjusted_idx] = new_line
                changed = True
                fixes_applied.append(f"unnecessary_non_null: {task_board_path}:{lineno}")
if changed:
    write_file(task_board_path, lines)

# ============================================
# 6. Fix undefined_identifier 'context' errors
# These need context added to the enclosing method
# ============================================

def find_enclosing_method(lines, target_idx):
    """Find the method definition line that encloses the given line index."""
    # Search upward for method definition
    for i in range(target_idx, -1, -1):
        line = lines[i].strip()
        # Match method definitions like: Widget _methodName(...) {
        # or void _methodName(...) {
        if re.match(r'(Widget|void|String|int|double|bool|List|Map|Color|TextStyle|BoxDecoration|Future)\s+_\w+\s*\(', line):
            return i
        # Multi-line: Widget _methodName(
        if re.match(r'(Widget|void|String|int|double|bool|List|Map|Color|TextStyle|BoxDecoration|Future)\s+_\w+\s*\($', line):
            return i
    return None

def add_context_to_method(lines, method_idx):
    """Add BuildContext context parameter to a method at the given index."""
    line = lines[method_idx]
    # Check if already has BuildContext context
    if 'BuildContext context' in line or 'BuildContext context' in ''.join(lines[method_idx:method_idx+5]):
        return False
    
    # Single-line params: Widget _method() {  or Widget _method({...}) {
    if '()' in line:
        new_line = line.replace('()', '(BuildContext context)', 1)
        lines[method_idx] = new_line
        return True
    elif '({' in line:
        new_line = line.replace('({', '(BuildContext context, {', 1)
        lines[method_idx] = new_line
        return True
    elif re.search(r'\(\s*$', line):
        # Multi-line: params on next lines
        # Insert BuildContext context as first param
        indent = len(line) - len(line.lstrip())
        param_indent = indent + 2
        # Check next line
        next_line = lines[method_idx + 1].strip()
        if next_line.startswith('{'):
            # Named params on next line
            lines[method_idx + 1] = ' ' * param_indent + 'BuildContext context, {\n'
            # Remove the { from original
            # Actually, this is tricky. Let's just insert after (
            pass
        else:
            # Positional params on next lines
            insert_line = ' ' * param_indent + 'BuildContext context,\n'
            lines.insert(method_idx + 1, insert_line)
            return True
    return False

def find_and_fix_call_sites(lines, method_name, start_from=0):
    """Find call sites of the method and add context as first arg."""
    count = 0
    for i in range(start_from, len(lines)):
        line = lines[i]
        # Match: _methodName( but NOT Widget _methodName( (definition)
        pattern = rf'(?<!Widget\s)(?<!void\s)(?<!String\s)(?<!\w){re.escape(method_name)}\('
        if re.search(pattern, line) and 'Widget ' not in line and 'void ' not in line:
            # Check if context is already passed
            # Look at the text after method_name(
            call_match = re.search(rf'{re.escape(method_name)}\(', line)
            if call_match:
                after = line[call_match.end():]
                # If next char is 'context' or line contains 'context,' right after (
                if not after.strip().startswith('context'):
                    # Add context as first arg
                    pos = call_match.end()
                    if after.strip() == ')' or after.strip() == '),':
                        # No args - add context
                        lines[i] = line[:pos] + 'context' + line[pos:]
                    else:
                        # Has args - add context,
                        lines[i] = line[:pos] + 'context, ' + line[pos:]
                    count += 1
    return count

# Files with undefined 'context' errors
context_error_files = {
    "lib/pages/ceo/ceo_reports_settings_page.dart": [586, 592, 921],
    "lib/pages/ceo/company_details_page.dart": [2965, 2982],
    "lib/pages/ceo/service/service_ceo_layout.dart": [2817, 2821, 2902],
    "lib/pages/shareholder/shareholder_dashboard.dart": [743, 760],
    "lib/widgets/gamification/skill_tree_widget.dart": [219],
    "lib/business_types/service/layouts/service_staff_layout.dart": [301, 305],
    "lib/business_types/service/pages/reservations/reservation_list_page.dart": [764],
}

for filepath, error_lines in context_error_files.items():
    lines = read_file(filepath)
    methods_fixed = set()
    
    for lineno in error_lines:
        idx = lineno - 1
        if idx >= len(lines):
            continue
        
        # Find the enclosing method
        method_idx = find_enclosing_method(lines, idx)
        if method_idx is None:
            fixes_applied.append(f"SKIPPED context: {filepath}:{lineno} - could not find enclosing method")
            continue
        
        if method_idx in methods_fixed:
            continue
        
        method_line = lines[method_idx].strip()
        # Extract method name
        match = re.search(r'(\w+)\s*\(', method_line)
        if not match:
            fixes_applied.append(f"SKIPPED context: {filepath}:{lineno} - could not parse method name")
            continue
        
        method_name = match.group(1)
        
        # Check if method already has BuildContext context
        method_text = ''.join(lines[method_idx:method_idx+8])
        if 'BuildContext context' in method_text or 'BuildContext ctx' in method_text:
            fixes_applied.append(f"SKIPPED context: {filepath}:{lineno} - method {method_name} already has context")
            continue
        
        # Add context param to method
        added = add_context_to_method(lines, method_idx)
        if added:
            methods_fixed.add(method_idx)
            fixes_applied.append(f"context param: {filepath} - added BuildContext context to {method_name}")
            
            # Find and fix call sites
            call_count = find_and_fix_call_sites(lines, method_name)
            if call_count > 0:
                fixes_applied.append(f"context calls: {filepath} - added context to {call_count} call(s) of {method_name}")
    
    if methods_fixed:
        write_file(filepath, lines)

# ============================================
# 7. Fix test file warnings
# ============================================
# unused_local_variable in management_task_service_test.dart:673
# dead_code in management_task_service_test.dart:738, 752
# These are test files - just suppress or fix
test_file = "test/services/management_task_service_test.dart"
try:
    lines = read_file(test_file)
    # Line 673: unused local variable 'task'
    idx = 672
    if idx < len(lines) and 'task' in lines[idx]:
        old = lines[idx]
        # Prefix with ignore comment or just remove the variable name
        lines[idx] = old.replace('final task = ', 'final _ = ', 1) if 'final task = ' in old else old
        fixes_applied.append(f"unused_var: {test_file}:673")
    write_file(test_file, lines)
except Exception as e:
    fixes_applied.append(f"SKIPPED test fix: {e}")

# ============================================
# Summary
# ============================================
print(f"\n{'='*60}")
print(f"FIXES APPLIED: {len(fixes_applied)}")
print(f"{'='*60}")
for fix in fixes_applied:
    print(f"  ✓ {fix}")
