import 'dart:io';
import 'dart:convert';

/// Script to replace all print() statements with proper logging
void main() async {
  print('🔧 Starting print statement cleanup...');
  
  final projectRoot = Directory.current;
  final libDir = Directory('${projectRoot.path}/lib');
  
  if (!libDir.existsSync()) {
    print('❌ lib directory not found');
    return;
  }
  
  int filesModified = 0;
  int replacements = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final relativePath = file.path.replaceAll('${projectRoot.path}/', '');
      
      // Skip logger service file (it should have print for internal use)
      if (relativePath.contains('logger_service.dart') ||
          relativePath.contains('error_tracker.dart') ||
          relativePath.contains('performance_monitor.dart')) {
        continue;
      }
      
      final content = await file.readAsString();
      String newContent = content;
      
      // Track if this file was modified
      bool fileModified = false;
      
      // Check if file needs logger import
      bool needsLogger = false;
      
      // Replace print statements with logger calls
      final printRegex = RegExp(r"print\s*\(\s*'([^']*)'\s*\)");
      final printRegex2 = RegExp(r'print\s*\(\s*"([^"]*)"\s*\)');
      final printRegex3 = RegExp(r"print\s*\(\s*'([^']*\$[^']*)'\s*\)");
      final printRegex4 = RegExp(r'print\s*\(\s*"([^"]*\$[^"]*)"\s*\)');
      
      // Replace simple string prints
      newContent = newContent.replaceAllMapped(printRegex, (match) {
        fileModified = true;
        needsLogger = true;
        replacements++;
        return "logger.debug('${match.group(1)}')";
      });
      
      newContent = newContent.replaceAllMapped(printRegex2, (match) {
        fileModified = true;
        needsLogger = true;
        replacements++;
        return 'logger.debug("${match.group(1)}")';
      });
      
      // Replace string interpolation prints
      newContent = newContent.replaceAllMapped(printRegex3, (match) {
        fileModified = true;
        needsLogger = true;
        replacements++;
        return "logger.debug('${match.group(1)}')";
      });
      
      newContent = newContent.replaceAllMapped(printRegex4, (match) {
        fileModified = true;
        needsLogger = true;
        replacements++;
        return 'logger.debug("${match.group(1)}")';
      });
      
      // Add logger import if needed
      if (needsLogger && !newContent.contains("import '../utils/logger_service.dart'") && 
          !newContent.contains("import '../../utils/logger_service.dart'") &&
          !newContent.contains("import '../../../utils/logger_service.dart'")) {
        
        // Find the last import line
        final lines = newContent.split('\n');
        int lastImportIndex = -1;
        
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lastImportIndex = i;
          }
        }
        
        if (lastImportIndex >= 0) {
          // Calculate relative path to logger_service.dart
          final pathParts = relativePath.split('/');
          final depth = pathParts.length - 2; // -1 for file, -1 for lib
          final relativePath2 = '../' * depth + 'utils/logger_service.dart';
          
          lines.insert(lastImportIndex + 1, "import '$relativePath2';");
          newContent = lines.join('\n');
        }
      }
      
      if (fileModified) {
        await file.writeAsString(newContent);
        filesModified++;
        print('✅ Fixed: $relativePath');
      }
    }
  }
  
  print('\n🎉 Cleanup complete!');
  print('📊 Files modified: $filesModified');
  print('🔄 Print statements replaced: $replacements');
}