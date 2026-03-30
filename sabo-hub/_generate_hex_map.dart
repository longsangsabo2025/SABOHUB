import 'dart:io';

void main() {
  final appColorsFile = File('D:/0.PROJECTS/02-SABO-ECOSYSTEM/sabo-hub/sabohub-app/SABOHUB/lib/core/theme/app_colors.dart');
  final content = appColorsFile.readAsStringSync();
  
  final regex = RegExp(r'static const Color (\w+) = Color\((0x[a-fA-F0-9]{8})\);');
  final matches = regex.allMatches(content);
  
  print('final hexMap = {');
  for (final match in matches) {
    final colorName = match.group(1)!;
    final hexValue = match.group(2)!;
    print("  '$hexValue': 'AppColors.$colorName',");
  }
  print('};');
  
  print('\nFound ${matches.length} color mappings');
}
