import os, re

changes = {
    'Color(0xFF4CAF50)': 'AppColors.success',
    'Color(0xFFF44336)': 'AppColors.error',
    'Color(0xFFFF9800)': 'AppColors.warning',
    'Color(0xFF2196F3)': 'AppColors.info',
    'Color(0xFF7C3AED)': 'AppColors.primary',
    'Color(0xFF06B6D4)': 'AppColors.secondary',
    'Color(0xFFE2E8F0)': 'AppColors.border',
    'Color(0xFFF8FAFC)': 'AppColors.backgroundLight',
    'Color(0xFF1E293B)': 'AppColors.textPrimary',
    'Color(0xFF64748B)': 'AppColors.textSecondary',
    'Color(0xFF10B981)': 'AppColors.success',
    'Color(0xFFEF4444)': 'AppColors.error',
    'Color(0xFFF59E0B)': 'AppColors.warning',
    'Color(0xFF3B82F6)': 'AppColors.info',
}

def process_dir(path):
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith('.dart') and file != 'app_colors.dart' and file != 'app_theme.dart':
                p = os.path.join(root, file)
                with open(p, 'r', encoding='utf-8') as f:
                    content = f.read()
                old_content = content
                for k, v in changes.items():
                    content = content.replace(k, v)
                if content != old_content:
                    if 'import' in content and 'app_colors.dart' not in content:
                        # try to add import
                        pass # too risky to guess relative path
                        # instead skip if import missing? or just let flutter analyze find it
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(content)

process_dir('lib')

