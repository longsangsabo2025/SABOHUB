import os
import re

rootDir = r'D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\lib'

replacements = {
    'Color(0xFF7C3AED)': 'AppColors.primary',
    'Color(0xFF06B6D4)': 'AppColors.secondary',
    'Color(0xFF10B981)': 'AppColors.success',
    'Color(0xFFF59E0B)': 'AppColors.warning',
    'Color(0xFFEF4444)': 'AppColors.error',
    'Color(0xFF3B82F6)': 'AppColors.info',
    'Color(0xFFF8FAFC)': 'Theme.of(context).colorScheme.surface',
    'Color(0xFFFFFFFF)': 'Theme.of(context).colorScheme.surface',
    'Color(0xFFE2E8F0)': 'AppColors.border',
    'Color(0xFF1E293B)': 'AppColors.textPrimary',
    'Color(0xFF64748B)': 'AppColors.textSecondary',
    'Color(0xFF94A3B8)': 'AppColors.textHint',
    'Color(0xFF22C55E)': 'AppColors.success',
    'Colors.white': 'Theme.of(context).colorScheme.surface',
    'Colors.black': 'Theme.of(context).colorScheme.onSurface',
}

changes_made = 0

for dirpath, _, filenames in os.walk(rootDir):
    for filename in filenames:
        if filename.endswith('.dart') and 'app_colors.dart' not in filename and 'app_theme.dart' not in filename:
            filepath = os.path.join(dirpath, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            new_content = content
            for old, new in replacements.items():
                if old in new_content:
                    # check if Theme.of(context) requires material import? usually they have it
                    new_content = new_content.replace(old, new)
            
            if new_content != content:
                # Add import if AppColors used but not imported
                if 'AppColors.' in new_content and 'import' in new_content and 'app_colors.dart' not in new_content:
                    # simplistic import addition
                    if 'import \'package:flutter_sabohub/core/theme/app_colors.dart\';' not in new_content:
                        lines = new_content.split('\n')
                        for i, line in enumerate(lines):
                            if line.startswith('import '):
                                lines.insert(i, "import 'package:flutter_sabohub/core/theme/app_colors.dart';")
                                break
                        new_content = '\n'.join(lines)

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                changes_made += 1
                print(f"Updated {filename}")

print(f"Total files updated: {changes_made}")
