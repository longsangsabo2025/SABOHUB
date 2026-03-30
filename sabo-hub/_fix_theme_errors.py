"""
Fix mass Theme.of(context) refactoring errors across SABOHUB codebase.
Fixes:
1. const_eval_method_invocation — remove 'const' from expressions containing Theme.of(context)
2. undefined_getter — create ColorScheme extension for onSurface87, surface70, etc.
3. undefined_identifier 'context' — add BuildContext context param to helper methods
"""

import os
import re
import sys
from pathlib import Path

LIB_DIR = Path(r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\lib")
TEST_DIR = Path(r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\test")

stats = {"files_modified": 0, "const_removed": 0, "context_fixed": 0}


def fix_const_same_line(content: str) -> str:
    """Remove 'const' from same-line expressions containing Theme.of(context)."""
    # Pattern: const SomeConstructor(... Theme.of(context) ...)
    pattern = r'\bconst\s+((?:TextStyle|BoxDecoration|Icon|Text|EdgeInsets|SizedBox|CircularProgressIndicator|Padding|Divider|RealtimeNotificationBell|InputDecoration|OutlineInputBorder|UnderlineInputBorder|BorderSide|BoxShadow|ShapeBorder|RoundedRectangleBorder|Border)\s*(?:\.\w+)?\s*\()'
    
    lines = content.split('\n')
    new_lines = []
    changed = False
    
    for line in lines:
        if 'Theme.of(context)' in line and 'const ' in line:
            # Remove 'const' before any constructor that contains Theme.of(context) on the same line
            new_line = re.sub(r'\bconst\s+(?=[A-Z]\w*[\.(])', '', line)
            if new_line != line:
                new_lines.append(new_line)
                stats["const_removed"] += line.count('const') - new_line.count('const')
                changed = True
                continue
        new_lines.append(line)
    
    if changed:
        return '\n'.join(new_lines)
    return content


def fix_const_parent_child(content: str) -> str:
    """Fix const on parent widgets where Theme.of(context) is in child lines.
    
    Handles patterns like:
      const Column(children: [
        Text('...', style: TextStyle(color: Theme.of(context)...)),
      ])
    """
    lines = content.split('\n')
    
    # Find all lines with Theme.of(context)
    theme_lines = set()
    for i, line in enumerate(lines):
        if 'Theme.of(context)' in line:
            theme_lines.add(i)
    
    if not theme_lines:
        return content
    
    # For each Theme.of(context) line, walk backwards to find enclosing 'const' 
    # by tracking bracket depth
    const_lines_to_fix = set()
    
    for theme_line_idx in theme_lines:
        depth = 0
        for i in range(theme_line_idx, -1, -1):
            line = lines[i]
            # Count brackets on this line (from right to left for backward tracking)
            for ch in reversed(line):
                if ch == ')' or ch == ']' or ch == '}':
                    depth += 1
                elif ch == '(' or ch == '[' or ch == '{':
                    depth -= 1
            
            # If we've closed more brackets than opened, we're inside a parent expression
            # Check if this line has 'const' before a constructor
            if depth <= 0 and re.search(r'\bconst\s+[A-Z]', line):
                const_lines_to_fix.add(i)
                break
            if depth < -2:  # Safety: don't go too far up
                break
    
    if not const_lines_to_fix:
        return content
    
    changed = False
    new_lines = list(lines)
    for idx in const_lines_to_fix:
        old_line = new_lines[idx]
        # Only remove 'const' before constructor names (capitalized)
        new_line = re.sub(r'\bconst\s+(?=[A-Z]\w*[\.(])', '', old_line, count=1)
        if new_line != old_line:
            new_lines[idx] = new_line
            stats["const_removed"] += 1
            changed = True
    
    if changed:
        return '\n'.join(new_lines)
    return content


def fix_context_in_widget_methods(content: str) -> str:
    """Fix 'context' undefined in ConsumerWidget/StatelessWidget helper methods.
    
    For methods that use Theme.of(context) but don't have context as a parameter,
    add BuildContext context parameter.
    """
    if 'Theme.of(context)' not in content:
        return content
    
    # Check if this is a ConsumerWidget or StatelessWidget (no context property)
    is_stateless = bool(re.search(r'extends\s+(ConsumerWidget|StatelessWidget)\b', content))
    
    if not is_stateless:
        return content
    
    lines = content.split('\n')
    new_lines = list(lines)
    changed = False
    
    # Find all method definitions that DON'T have 'context' as parameter
    # but DO use Theme.of(context) inside them
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Match method definitions like: Widget _buildSomething(Type arg, ...) {
        # or: Widget _buildSomething({Type arg, ...}) {
        # Match single-line method signature with all params on one line
        method_match = re.match(
            r'(\s*)(Widget|List<Widget>|String|double|int|void|Color|TextStyle|BoxDecoration)\s+'
            r'(_\w+)\s*\(([^)]*)\)\s*\{',
            line
        )
        
        if not method_match:
            i += 1
            continue
        
        if method_match:
            indent = method_match.group(1)
            return_type = method_match.group(2)
            method_name = method_match.group(3)
            params = method_match.group(4)
            
            # Skip if already has context
            if 'context' in params or 'BuildContext' in params:
                i += 1
                continue
            
            # Check if method body uses context
            depth = 0
            uses_context = False
            body_end = i
            for j in range(i, len(lines)):
                for ch in lines[j]:
                    if ch == '{':
                        depth += 1
                    elif ch == '}':
                        depth -= 1
                if j > i and 'context' in lines[j]:
                    uses_context = True
                if depth == 0:
                    body_end = j
                    break
            
            if uses_context:
                # Add BuildContext context as first parameter
                if params.strip():
                    new_params = f"BuildContext context, {params}"
                else:
                    new_params = "BuildContext context"
                
                new_line = f"{indent}{return_type} {method_name}({new_params}) {{"
                new_lines[i] = new_line
                changed = True
                stats["context_fixed"] += 1
                
                # Also fix all call sites of this method within the same file
                # Pattern: _methodName( or _methodName(args
                call_pattern = re.compile(
                    rf'({re.escape(method_name)})\s*\('
                )
                for k in range(len(new_lines)):
                    if k == i:  # Skip the definition itself
                        continue
                    if method_name in new_lines[k]:
                        # Don't modify the method signature again
                        if re.search(rf'(Widget|void|String|double|int|Color|TextStyle|BoxDecoration|List<Widget>)\s+{re.escape(method_name)}\s*\(', new_lines[k]):
                            continue
                        # Add context as first argument to calls
                        old_call = new_lines[k]
                        new_call = re.sub(
                            rf'({re.escape(method_name)})\s*\(',
                            rf'\1(context, ',
                            old_call
                        )
                        # Fix double context: _method(context, ) → _method(context)  
                        new_call = re.sub(r'\(context,\s*\)', '(context)', new_call)
                        if new_call != old_call:
                            new_lines[k] = new_call
        i += 1
    
    if changed:
        return '\n'.join(new_lines)
    return content


def process_file(filepath: Path) -> bool:
    """Process a single Dart file. Returns True if modified."""
    try:
        content = filepath.read_text(encoding='utf-8')
    except Exception as e:
        print(f"  SKIP (read error): {filepath} — {e}")
        return False
    
    original = content
    
    # Phase 1: Fix const on same line as Theme.of(context)
    content = fix_const_same_line(content)
    
    # Phase 2: Fix const on parent widget enclosing Theme.of(context) child
    content = fix_const_parent_child(content)
    
    # Phase 3: Fix context in ConsumerWidget/StatelessWidget methods
    content = fix_context_in_widget_methods(content)
    
    if content != original:
        filepath.write_text(content, encoding='utf-8')
        stats["files_modified"] += 1
        return True
    return False


def main():
    print("=" * 60)
    print("SABOHUB Theme Error Fix Script")
    print("=" * 60)
    
    # Process all .dart files in lib/
    dart_files = list(LIB_DIR.rglob("*.dart"))
    dart_files += list(TEST_DIR.rglob("*.dart"))
    
    print(f"\nFound {len(dart_files)} Dart files")
    print("\nProcessing...")
    
    modified_files = []
    for f in dart_files:
        if process_file(f):
            modified_files.append(f)
            rel = f.relative_to(LIB_DIR.parent)
            print(f"  ✓ {rel}")
    
    print(f"\n{'=' * 60}")
    print(f"RESULTS:")
    print(f"  Files modified: {stats['files_modified']}")
    print(f"  const keywords removed: {stats['const_removed']}")
    print(f"  context params added: {stats['context_fixed']}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
