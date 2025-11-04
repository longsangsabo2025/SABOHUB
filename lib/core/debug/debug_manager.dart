import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Enhanced Debug Manager for Flutter Web with Chrome Console Integration
class DebugManager {
  static const String _version = '1.0.0';
  static bool _isInitialized = false;
  static final List<DebugLog> _logs = [];
  static final Map<String, dynamic> _context = {};

  // Debug levels
  static const int LEVEL_VERBOSE = 0;
  static const int LEVEL_DEBUG = 1;
  static const int LEVEL_INFO = 2;
  static const int LEVEL_WARNING = 3;
  static const int LEVEL_ERROR = 4;
  static const int LEVEL_CRITICAL = 5;

  static int _currentLevel = kDebugMode ? LEVEL_DEBUG : LEVEL_WARNING;

  /// Initialize the debug manager
  static void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;
    _setupConsoleStyles();
    _printWelcomeMessage();
    _setupGlobalErrorHandling();
    _setupPerformanceMonitoring();

    info('🔧 Debug Manager initialized successfully');
  }

  /// Set debug level
  static void setLevel(int level) {
    _currentLevel = level;
    info('📊 Debug level set to: ${_getLevelName(level)}');
  }

  /// Add context information
  static void setContext(String key, dynamic value) {
    _context[key] = value;
    debug('📝 Context updated: $key = $value');
  }

  /// Get current context
  static Map<String, dynamic> getContext() => Map.from(_context);

  // ==================== LOGGING METHODS ====================

  /// Verbose logging (most detailed)
  static void verbose(String message,
      {String? tag, Map<String, dynamic>? data}) {
    _log(LEVEL_VERBOSE, message, tag: tag, data: data);
  }

  /// Debug logging
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LEVEL_DEBUG, message, tag: tag, data: data);
  }

  /// Info logging
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LEVEL_INFO, message, tag: tag, data: data);
  }

  /// Warning logging
  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    _log(LEVEL_WARNING, message, tag: tag, data: data);
  }

  /// Error logging
  static void error(String message,
      {String? tag,
      Map<String, dynamic>? data,
      dynamic error,
      StackTrace? stackTrace}) {
    _log(LEVEL_ERROR, message,
        tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  /// Critical error logging
  static void critical(String message,
      {String? tag,
      Map<String, dynamic>? data,
      dynamic error,
      StackTrace? stackTrace}) {
    _log(LEVEL_CRITICAL, message,
        tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  // ==================== SPECIALIZED LOGGING ====================

  /// Log API calls
  static void api(String method, String url,
      {Map<String, dynamic>? request,
      Map<String, dynamic>? response,
      int? statusCode,
      Duration? duration}) {
    final data = <String, dynamic>{
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'duration': duration?.inMilliseconds,
    };

    if (request != null) data['request'] = request;
    if (response != null) data['response'] = response;

    info('🌐 API Call: $method $url', tag: 'API', data: data);
  }

  /// Log user actions
  static void userAction(String action, {Map<String, dynamic>? details}) {
    info('👤 User Action: $action', tag: 'USER', data: details);
  }

  /// Log navigation
  static void navigation(String from, String to,
      {Map<String, dynamic>? params}) {
    info('🧭 Navigation: $from → $to', tag: 'NAV', data: params);
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration,
      {Map<String, dynamic>? metrics}) {
    final data = <String, dynamic>{
      'duration': duration.inMilliseconds,
      'operation': operation,
    };

    if (metrics != null) data.addAll(metrics);

    info('⚡ Performance: $operation (${duration.inMilliseconds}ms)',
        tag: 'PERF', data: data);
  }

  /// Log state changes
  static void stateChange(String state, dynamic from, dynamic to,
      {String? widget}) {
    final data = <String, dynamic>{
      'state': state,
      'from': from?.toString(),
      'to': to?.toString(),
      'widget': widget,
    };

    debug('🔄 State Change: $state', tag: 'STATE', data: data);
  }

  // ==================== INTERNAL METHODS ====================

  static void _log(int level, String message,
      {String? tag,
      Map<String, dynamic>? data,
      dynamic error,
      StackTrace? stackTrace}) {
    if (level < _currentLevel) return;

    final timestamp = DateTime.now();
    final logEntry = DebugLog(
      level: level,
      message: message,
      tag: tag ?? 'APP',
      timestamp: timestamp,
      data: data,
      error: error,
      stackTrace: stackTrace,
      context: Map.from(_context),
    );

    _logs.add(logEntry);
    _printToConsole(logEntry);

    // Keep only last 1000 logs
    if (_logs.length > 1000) {
      _logs.removeAt(0);
    }
  }

  static void _printToConsole(DebugLog log) {
    if (!kIsWeb) return;

    final levelName = _getLevelName(log.level);
    final icon = _getLevelIcon(log.level);
    final timestamp = log.timestamp.toIso8601String().substring(11, 23);

    // Create main message
    final mainMessage =
        '$icon [$timestamp] [${log.tag}] $levelName: ${log.message}';

    // Choose console method based on level
    switch (log.level) {
      case LEVEL_VERBOSE:
      case LEVEL_DEBUG:
        html.window.console.debug(mainMessage);
        break;
      case LEVEL_INFO:
        html.window.console.info(mainMessage);
        break;
      case LEVEL_WARNING:
        html.window.console.warn(mainMessage);
        break;
      case LEVEL_ERROR:
      case LEVEL_CRITICAL:
        html.window.console.error(mainMessage);
        break;
    }

    // Print additional data
    if (log.data != null && log.data!.isNotEmpty) {
      html.window.console.groupCollapsed('📊 Data:');
      html.window.console.table(log.data);
      html.window.console.groupEnd();
    }

    // Print context if available
    if (log.context.isNotEmpty) {
      html.window.console.groupCollapsed('🔍 Context:');
      html.window.console.table(log.context);
      html.window.console.groupEnd();
    }

    // Print error details
    if (log.error != null) {
      html.window.console.groupCollapsed('❌ Error Details:');
      html.window.console.error(log.error.toString());
      if (log.stackTrace != null) {
        html.window.console.error('Stack Trace:');
        html.window.console.error(log.stackTrace.toString());
      }
      html.window.console.groupEnd();
    }
  }

  static void _setupConsoleStyles() {
    if (!kIsWeb) return;

    // Add custom CSS for better console styling
    html.document.head?.append(html.StyleElement()
      ..text = '''
        .debug-log { font-family: 'Consolas', 'Monaco', monospace; }
        .debug-verbose { color: #9E9E9E; }
        .debug-debug { color: #2196F3; }
        .debug-info { color: #4CAF50; }
        .debug-warning { color: #FF9800; }
        .debug-error { color: #F44336; }
        .debug-critical { color: #E91E63; font-weight: bold; }
      ''');
  }

  static void _printWelcomeMessage() {
    if (!kIsWeb) return;

    html.window.console.clear();
    html.window.console.log('🚀 SABOHUB Debug Console v$_version');
    html.window.console.log('🔧 Debug Manager Active');
    html.window.console.log('📊 Level: ${_getLevelName(_currentLevel)}');
    html.window.console.log('⚡ Performance monitoring enabled');
  }

  static void _setupGlobalErrorHandling() {
    if (!kIsWeb) return;

    // Setup global error handler
    html.window.addEventListener('error', (event) {
      final errorEvent = event as html.ErrorEvent;
      critical('Global Error: ${errorEvent.message}', tag: 'GLOBAL', data: {
        'filename': errorEvent.filename,
        'lineno': errorEvent.lineno,
        'colno': errorEvent.colno,
      });
    });

    // Setup unhandled promise rejection handler
    html.window.addEventListener('unhandledrejection', (event) {
      final rejectionEvent = event as html.PromiseRejectionEvent;
      critical('Unhandled Promise Rejection: ${rejectionEvent.reason}',
          tag: 'PROMISE');
    });
  }

  static void _setupPerformanceMonitoring() {
    if (!kIsWeb) return;

    // Monitor page load performance
    html.window.addEventListener('load', (event) {
      final navigation = html.window.performance.timing;
      final loadTime = navigation.loadEventEnd - navigation.navigationStart;

      performance('Page Load', Duration(milliseconds: loadTime), metrics: {
        'domContentLoaded':
            navigation.domContentLoadedEventEnd - navigation.navigationStart,
        'firstPaint': navigation.responseStart - navigation.navigationStart,
        'domComplete': navigation.domComplete - navigation.navigationStart,
      });
    });
  }

  // ==================== UTILITY METHODS ====================

  static String _getLevelName(int level) {
    switch (level) {
      case LEVEL_VERBOSE:
        return 'VERBOSE';
      case LEVEL_DEBUG:
        return 'DEBUG';
      case LEVEL_INFO:
        return 'INFO';
      case LEVEL_WARNING:
        return 'WARNING';
      case LEVEL_ERROR:
        return 'ERROR';
      case LEVEL_CRITICAL:
        return 'CRITICAL';
      default:
        return 'UNKNOWN';
    }
  }

  static String _getLevelIcon(int level) {
    switch (level) {
      case LEVEL_VERBOSE:
        return '🔍';
      case LEVEL_DEBUG:
        return '🐛';
      case LEVEL_INFO:
        return 'ℹ️';
      case LEVEL_WARNING:
        return '⚠️';
      case LEVEL_ERROR:
        return '❌';
      case LEVEL_CRITICAL:
        return '🚨';
      default:
        return '📝';
    }
  }

  /// Get all logs
  static List<DebugLog> getLogs() => List.from(_logs);

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    if (kIsWeb) html.window.console.clear();
    info('🧹 Logs cleared');
  }

  /// Export logs as JSON
  static String exportLogs() {
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': _version,
      'context': _context,
      'logs': _logs.map((log) => log.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  /// Get debug statistics
  static Map<String, dynamic> getStats() {
    final stats = <String, int>{};
    for (final log in _logs) {
      final levelName = _getLevelName(log.level);
      stats[levelName] = (stats[levelName] ?? 0) + 1;
    }
    return {
      'total': _logs.length,
      'byLevel': stats,
      'context': _context.keys.length,
    };
  }
}

/// Debug log entry model
class DebugLog {
  final int level;
  final String message;
  final String tag;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic> context;

  DebugLog({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
    this.data,
    this.error,
    this.stackTrace,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'levelName': DebugManager._getLevelName(level),
      'message': message,
      'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
    };
  }
}
