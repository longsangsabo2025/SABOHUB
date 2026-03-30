import 'dart:io';

void main() {
  final file = File('D:/0.PROJECTS/02-SABO-ECOSYSTEM/sabo-hub/sabohub-app/SABOHUB/lib/widgets/task/task_board.dart');
  final content = file.readAsStringSync();
  final constRegex = RegExp(r'const\s+Color\((0x[a-fA-F0-9]{8})\)');
  final colorRegex = RegExp(r'Color\((0x[a-fA-F0-9]{8})\)');

  print('Testing on task_board.dart');
  
  for (final match in colorRegex.allMatches(content)) {
    print('Found: ${match.group(0)!} Hex: ${match.group(1)!}');
    String hex = match.group(1)!.toUpperCase();
    print('Transformed hex: $hex');
  }
}
