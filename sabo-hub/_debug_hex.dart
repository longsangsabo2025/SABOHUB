import 'dart:io';

void main() {
  final hexMap = {
    '0xFF7C3AED': 'AppColors.primary',
    '0xFF10B981': 'AppColors.success',
    '0xFF3B82F6': 'AppColors.info',
    '0xFFF59E0B': 'AppColors.warning',
    '0xFFEF4444': 'AppColors.error',
  };
  
  // Test hex found in task_board.dart
  String testHex1 = '0xFF0EA5E9';
  String testHex2 = '0xFF6366F1';
  String testHex3 = '0xFF10B981';
  
  print('Testing hex normalization:');
  
  for (final hex in [testHex1, testHex2, testHex3]) {
    String normalized = '0xFF${hex.substring(4).toUpperCase()}';
    print('Original: $hex -> Normalized: $normalized');
    print('Found in map: ${hexMap.containsKey(normalized)}');
    if (hexMap.containsKey(normalized)) {
      print('Maps to: ${hexMap[normalized]!}');
    }
    print('---');
  }
  
  print('All map keys:');
  hexMap.keys.forEach(print);
}
