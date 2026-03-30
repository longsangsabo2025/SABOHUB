import os, re

rootDir = r'D:\0.PROJECTS\02-SABO-ECOSYSTEM\sabo-hub\sabohub-app\SABOHUB\lib'

hex_map = {
    '0xFF7C3AED': 'AppColors.primary',
    '0xFF9F67FF': 'AppColors.primaryLight',
    '0xFF5B21B6': 'AppColors.primaryDark',
    '0xFF06B6D4': 'AppColors.secondary',
    '0xFF22D3EE': 'AppColors.secondaryLight',
    '0xFF0891B2': 'AppColors.secondaryDark',
    '0xFF10B981': 'AppColors.success',
    '0xFFD1FAE5': 'AppColors.successLight',
    '0xFF059669': 'AppColors.successDark',
    '0xFFF59E0B': 'AppColors.warning',
    '0xFFFEF3C7': 'AppColors.warningLight',
    '0xFFD97706': 'AppColors.warningDark',
    '0xFFEF4444': 'AppColors.error',
    '0xFFFEE2E2': 'AppColors.errorLight',
    '0xFFDC2626': 'AppColors.errorDark',
    '0xFF3B82F6': 'AppColors.info',
    '0xFFDBEAFE': 'AppColors.infoLight',
    '0xFF2563EB': 'AppColors.infoDark',
    
    # Surface and background
    '0xFFF8FAFC': 'AppColors.surface',
    '0xFFF1F5F9': 'AppColors.surfaceVariant',
    '0xFFFFFFFF': 'AppColors.background',
    '0xFF0F172A': 'AppColors.backgroundDark',
    '0xFFE2E8F0': 'AppColors.border',
    '0xFF1E293B': 'AppColors.textPrimary',
    '0xFF64748B': 'AppColors.textSecondary',
    '0xFF9CA3AF': 'AppColors.neutral400',
    '0xFF6B7280': 'AppColors.neutral500',
    '0xFF4B5563': 'AppColors.neutral600',
    
    # Greys
    '0xFFFAFAFA': 'AppColors.grey50',
    '0xFFF5F5F5': 'AppColors.grey100',
    '0xFFEEEEEE': 'AppColors.grey200',
    '0xFFE0E0E0': 'AppColors.grey300',
    '0xFFBDBDBD': 'AppColors.grey400',
    '0xFF9E9E9E': 'AppColors.grey500',
    '0xFF757575': 'AppColors.grey600',
    '0xFF616161': 'AppColors.grey700',
    '0xFF424242': 'AppColors.grey800',
    '0xFF212121': 'AppColors.grey900',
}

changes_made = 0

for dirpath, dirs, files in os.walk(rootDir):
    for filename in files:
        if not filename.endswith('.dart'): continue
        if 'app_colors.dart' in filename or 'app_theme.dart' in filename: continue
        filepath = os.path.join(dirpath, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content
        
        # Replace 'const Color(0xFF...)'
        new_content = re.sub(r'const\s+Color\((0x[A-Fa-f0-9]{8})\)', lambda m: hex_map.get('0xFF' + m.group(1)[4:].upper(), m.group(0)), new_content, flags=re.IGNORECASE)
        
        # Replace normal colors
        new_content = re.sub(r'Color\((0x[A-Fa-f0-9]{8})\)', lambda m: hex_map.get('0xFF' + m.group(1)[4:].upper(), m.group(0)), new_content, flags=re.IGNORECASE)
        
        if new_content != content:
            if 'AppColors.' in new_content and 'import' in new_content and 'app_colors.dart' not in new_content:
                lines = new_content.split('\n')
                for i in range(len(lines)):
                    if lines[i].startswith('import '):
                        lines.insert(i, "import 'package:flutter_sabohub/core/theme/app_colors.dart';")
                        break
                new_content = '\n'.join(lines)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            changes_made += 1

print(f"Total files updated: {changes_made}")
