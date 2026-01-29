/// 🔴 LONGSANG ERROR REPORTER FOR FLUTTER
/// Auto-reports errors to longsang-admin for auto-fix
/// 
/// USAGE:
/// 1. Add to pubspec.yaml: http: ^1.1.0
/// 2. In main.dart, wrap runApp with:
///    LongSangErrorReporter.init(() => runApp(MyApp()));

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String _getPlatformName() {
  if (kIsWeb) return 'web';
  // For non-web, we can't use dart:io on web, so just return 'unknown'
  return 'unknown';
}

class LongSangErrorReporter {
  static const String _adminUrl = 'https://longsang-admin.vercel.app';
  static String _appName = 'flutter-app';
  static final List<Map<String, dynamic>> _errorQueue = [];
  static bool _isProcessing = false;
  static Timer? _timer;

  /// Initialize error reporter
  /// Call this in main.dart:
  /// ```dart
  /// void main() {
  ///   LongSangErrorReporter.init(() => runApp(MyApp()), appName: 'my-app');
  /// }
  /// ```
  static void init(VoidCallback runApp, {String appName = 'flutter-app'}) {
    _appName = appName;
    
    // Start queue processor
    _startQueueProcessor();
    
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _reportError(
        type: details.exception.runtimeType.toString(),
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        file: _extractFileFromStack(details.stack?.toString()),
        line: _extractLineFromStack(details.stack?.toString()),
      );
    };

    // Catch async errors
    runZonedGuarded(
      runApp,
      (error, stackTrace) {
        _reportError(
          type: error.runtimeType.toString(),
          message: error.toString(),
          stack: stackTrace.toString(),
          file: _extractFileFromStack(stackTrace.toString()),
          line: _extractLineFromStack(stackTrace.toString()),
        );
      },
    );
  }

  /// Manual error capture
  static void capture(dynamic error, {StackTrace? stackTrace, Map<String, dynamic>? context}) {
    _reportError(
      type: error.runtimeType.toString(),
      message: error.toString(),
      stack: stackTrace?.toString(),
      file: context?['file'] ?? _extractFileFromStack(stackTrace?.toString()),
      line: context?['line'] ?? _extractLineFromStack(stackTrace?.toString()),
    );
  }

  static void _reportError({
    required String type,
    required String message,
    String? stack,
    String? file,
    int? line,
  }) {
    _errorQueue.add({
      'app': _appName,
      'type': type,
      'message': message,
      'file': file ?? 'unknown',
      'line': line ?? 0,
      'stack': stack,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': _getPlatformName(),
    });
  }

  static void _startQueueProcessor() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _processQueue());
  }

  static Future<void> _processQueue() async {
    if (_isProcessing || _errorQueue.isEmpty) return;
    
    _isProcessing = true;
    final errors = List<Map<String, dynamic>>.from(_errorQueue);
    _errorQueue.clear();

    for (final error in errors) {
      try {
        await http.post(
          Uri.parse('$_adminUrl/api/errors/report'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(error),
        );
        if (kDebugMode) {
          print('📤 Error reported to LongSang Admin: ${error['type']}');
        }
      } catch (e) {
        // Silent fail - don't want error reporting to cause more errors
        if (kDebugMode) {
          print('⚠️ Failed to report error: $e');
        }
      }
    }

    _isProcessing = false;
  }

  static String? _extractFileFromStack(String? stack) {
    if (stack == null) return null;
    // Match patterns like: package:my_app/screens/home.dart
    final regex = RegExp(r'package:[\w_]+/([\w_/]+\.dart)');
    final match = regex.firstMatch(stack);
    return match?.group(0);
  }

  static int? _extractLineFromStack(String? stack) {
    if (stack == null) return null;
    // Match patterns like: :42:15)
    final regex = RegExp(r':(\d+):\d+\)');
    final match = regex.firstMatch(stack);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}
