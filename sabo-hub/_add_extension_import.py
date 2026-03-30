"""
Add import for color_scheme_extension.dart to all files that use
onSurface87/surface70/etc custom getters.
"""
import re
from pathlib import Path

LIB_DIR = Path(r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\lib")
TEST_DIR = Path(r"d:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\test")

EXTENSION_IMPORT = "import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';"
CUSTOM_GETTERS = re.compile(r'\.colorScheme\.(onSurface87|onSurface54|onSurface26|surface70|surface60|surface54|surface38|surface24)\b')

count = 0

for dart_file in list(LIB_DIR.rglob("*.dart")) + list(TEST_DIR.rglob("*.dart")):
    # Skip the extension file itself
    if dart_file.name == 'color_scheme_extension.dart':
        continue
    if dart_file.name == 'theme.dart' and 'core/theme' in str(dart_file).replace('\\', '/'):
        continue
    
    try:
        content = dart_file.read_text(encoding='utf-8')
    except Exception:
        continue
    
    # Check if file uses any custom getter
    if not CUSTOM_GETTERS.search(content):
        continue
    
    # Check if import already present
    if 'color_scheme_extension.dart' in content:
        continue
    
    # Add import after the last existing import line
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import ') and stripped.endswith(';'):
            last_import_idx = i
    
    if last_import_idx == -1:
        # No imports found, add at top
        lines.insert(0, EXTENSION_IMPORT)
    else:
        lines.insert(last_import_idx + 1, EXTENSION_IMPORT)
    
    dart_file.write_text('\n'.join(lines), encoding='utf-8')
    rel = dart_file.relative_to(LIB_DIR.parent)
    print(f"  + {rel}")
    count += 1

print(f"\nAdded import to {count} files")
