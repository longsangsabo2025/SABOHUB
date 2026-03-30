import 'dart:io';

void main() {
  final hexMap = {
    '0xFF10B981': 'AppColors.success',
    '0xFF3B82F6': 'AppColors.info',
    '0xFFF59E0B': 'AppColors.warning',
    '0xFFEF4444': 'AppColors.error',
  };
  
  final file = File('D:/0.PROJECTS/02-SABO-ECOSYSTEM/sabo-hub/sabohub-app/SABOHUB/lib/widgets/task/task_board.dart');
  final content = file.readAsStringSync();
  final colorRegex = RegExp(r'Color\((0x[a-fA-F0-9]{8})\)');
  
  print('Checking task_board.dart specifically:');
  print('File exists: ${file.existsSync()}');
  
  final matches = colorRegex.allMatches(content);
  print('Found ${matches.length} Color() matches:');
  
  for (final match in matches) {
    String hex = match.group(1)!;
    String normalizedHex = '0xFF${hex.substring(4).toUpperCase()}';
    bool inMap = hexMap.containsKey(normalizedHex);
    print('Original: $hex -> Normalized: $normalizedHex -> In map: $inMap');
    if (inMap) {
      print('  Would replace with: ${hexMap[normalizedHex]!}');
    }
    print('  Full match: ${match.group(0)!}');
    print('---');
  }
}
