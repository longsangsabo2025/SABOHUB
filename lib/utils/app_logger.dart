import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 🚀 SABOHUB Debug Logger - Elon Musk style: Move fast, break things, but LOG EVERYTHING!
/// 
/// Usage:
/// ```dart
/// AppLogger.auth('Login attempt', {'user': 'test'});
/// AppLogger.api('API Response', response);
/// AppLogger.error('Failed', error, stackTrace);
/// ```
class AppLogger {
  static bool _enabled = true;
  static bool _showTimestamp = true;
  static bool _showEmoji = true;

  // ANSI Colors for terminal (works in Chrome DevTools too)
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _bold = '\x1B[1m';

  /// Enable/disable logging
  static void setEnabled(bool enabled) => _enabled = enabled;

  /// Get current timestamp
  static String get _timestamp {
    if (!_showTimestamp) return '';
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}]';
  }

  /// 🔐 AUTH - Authentication related logs
  static void auth(String message, [dynamic data]) {
    _log('🔐 AUTH', message, data, _cyan);
  }

  /// 🌐 API - API calls and responses
  static void api(String message, [dynamic data]) {
    _log('🌐 API', message, data, _blue);
  }

  /// 📦 DATA - Data parsing and transformation
  static void data(String message, [dynamic data]) {
    _log('📦 DATA', message, data, _magenta);
  }

  /// 🔄 STATE - State changes (Riverpod, etc.)
  static void state(String message, [dynamic data]) {
    _log('🔄 STATE', message, data, _green);
  }

  /// 🧭 NAV - Navigation and routing
  static void nav(String message, [dynamic data]) {
    _log('🧭 NAV', message, data, _yellow);
  }

  /// ℹ️ INFO - General information
  static void info(String message, [dynamic data]) {
    _log('ℹ️ INFO', message, data, _white);
  }

  /// ⚠️ WARN - Warnings
  static void warn(String message, [dynamic data]) {
    _log('⚠️ WARN', message, data, _yellow);
  }

  /// ❌ ERROR - Errors with optional stack trace
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_enabled) return;

    final timestamp = _timestamp;
    final prefix = _showEmoji ? '❌ ERROR' : 'ERROR';
    
    // Print to console with color
    debugPrint('$_red$_bold══════════════════════════════════════════════════════════$_reset');
    debugPrint('$_red$_bold$timestamp $prefix: $message$_reset');
    
    if (error != null) {
      debugPrint('$_red  Error: $error$_reset');
    }
    
    if (stackTrace != null) {
      debugPrint('$_red  StackTrace:$_reset');
      final lines = stackTrace.toString().split('\n').take(10);
      for (final line in lines) {
        debugPrint('$_red    $line$_reset');
      }
    }
    
    debugPrint('$_red$_bold══════════════════════════════════════════════════════════$_reset');

    // Also log to developer console for DevTools
    developer.log(
      message,
      name: 'SABOHUB.ERROR',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  /// ✅ SUCCESS - Success messages
  static void success(String message, [dynamic data]) {
    _log('✅ SUCCESS', message, data, _green);
  }

  /// 🚀 PERF - Performance timing
  static Stopwatch startTimer(String name) {
    final stopwatch = Stopwatch()..start();
    _log('🚀 PERF', 'Started: $name', null, _cyan);
    return stopwatch;
  }

  static void endTimer(Stopwatch stopwatch, String name) {
    stopwatch.stop();
    _log('🚀 PERF', 'Completed: $name in ${stopwatch.elapsedMilliseconds}ms', null, _cyan);
  }

  /// Internal log method
  static void _log(String prefix, String message, dynamic data, String color) {
    if (!_enabled) return;

    final timestamp = _timestamp;
    final emoji = _showEmoji ? prefix : prefix.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    // Format the log line
    final logLine = '$timestamp $emoji: $message';
    
    // Print with color
    debugPrint('$color$logLine$_reset');
    
    // Print data if provided
    if (data != null) {
      if (data is Map) {
        _printMap(data, color);
      } else if (data is List) {
        _printList(data, color);
      } else {
        debugPrint('$color  → $data$_reset');
      }
    }

    // Also log to developer console for Chrome DevTools
    developer.log(
      data != null ? '$message\n$data' : message,
      name: 'SABOHUB.${prefix.replaceAll(RegExp(r'[^\w]'), '')}',
    );
  }

  /// Pretty print a Map
  static void _printMap(Map data, String color) {
    data.forEach((key, value) {
      if (value is Map) {
        debugPrint('$color  $key:$_reset');
        value.forEach((k, v) {
          debugPrint('$color    $k: $v$_reset');
        });
      } else {
        debugPrint('$color  $key: $value$_reset');
      }
    });
  }

  /// Pretty print a List
  static void _printList(List data, String color) {
    for (var i = 0; i < data.length && i < 10; i++) {
      debugPrint('$color  [$i]: ${data[i]}$_reset');
    }
    if (data.length > 10) {
      debugPrint('$color  ... and ${data.length - 10} more items$_reset');
    }
  }

  /// 📊 Debug box - for important information
  static void box(String title, Map<String, dynamic> data) {
    if (!_enabled) return;

    debugPrint('$_cyan╔══════════════════════════════════════════════════════════╗$_reset');
    debugPrint('$_cyan║ $_bold$title$_reset$_cyan${' ' * (56 - title.length)}║$_reset');
    debugPrint('$_cyan╠══════════════════════════════════════════════════════════╣$_reset');
    
    data.forEach((key, value) {
      final line = '  $key: $value';
      final padding = 58 - line.length;
      debugPrint('$_cyan║$line${' ' * (padding > 0 ? padding : 0)}║$_reset');
    });
    
    debugPrint('$_cyan╚══════════════════════════════════════════════════════════╝$_reset');
  }
}

/// Extension for easy timing
extension StopwatchLogger on Stopwatch {
  void logEnd(String name) {
    AppLogger.endTimer(this, name);
  }
}
