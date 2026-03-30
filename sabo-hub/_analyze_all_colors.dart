import 'dart:io';

void main() {
  final hexMap = {
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
    '0xFFF8FAFC': 'AppColors.surface',
    '0xFFF1F5F9': 'AppColors.surfaceVariant',
    '0xFFFFFFFF': 'AppColors.background',
    '0xFF0F172A': 'AppColors.backgroundDark',
    '0xFFE2E8F0': 'AppColors.border',
    '0xFFCBD5E1': 'AppColors.borderDark',
    '0xFF1E293B': 'AppColors.textPrimary',
    '0xFF64748B': 'AppColors.textSecondary',
    '0xFF94A3B8': 'AppColors.textTertiary',
    '0xFFCD7F32': 'AppColors.tierBronze',
    '0xFF8B5CF6': 'AppColors.paymentRefunded',
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
    '0xFF9CA3AF': 'AppColors.neutral400',
    '0xFF6B7280': 'AppColors.neutral500',
    '0xFF4B5563': 'AppColors.neutral600',
  };
  
  final rootDir = Directory('D:/0.PROJECTS/02-SABO-ECOSYSTEM/sabo-hub/sabohub-app/SABOHUB/lib');
  final colorRegex = RegExp(r'Color\((0x[a-fA-F0-9]{8})\)');
  
  Set<String> allColors = {};
  Set<String> matchedColors = {};
  Set<String> unmatchedColors = {};
  
  for (final entity in rootDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart') && 
        !entity.path.contains('app_colors.dart') && 
        !entity.path.contains('app_theme.dart')) {
      final content = entity.readAsStringSync();
      final matches = colorRegex.allMatches(content);
      
      for (final match in matches) {
        String hex = match.group(1)!;
        String normalizedHex = '0xFF${hex.substring(4).toUpperCase()}';
        allColors.add(normalizedHex);
        
        if (hexMap.containsKey(normalizedHex)) {
          matchedColors.add(normalizedHex);
        } else {
          unmatchedColors.add(normalizedHex);
        }
      }
    }
  }
  
  print('ANALYSIS RESULTS:');
  print('Total unique colors found: ${allColors.length}');
  print('Colors that can be replaced: ${matchedColors.length}');
  print('Colors with no AppColors equivalent: ${unmatchedColors.length}');
  print('\nUnmatched colors:');
  for (final color in unmatchedColors.toList()..sort()) {
    print('  $color');
  }
  
  print('\nMatched colors:');
  for (final color in matchedColors.toList()..sort()) {
    print('  $color -> ${hexMap[color]}');
  }
}
