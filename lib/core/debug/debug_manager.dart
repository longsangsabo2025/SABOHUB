import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enhanced Debug Manager - Cross-platform (Web, iOS, Android)
class DebugManager {
  static const String _version = '1.0.0';
  static bool _isInitialized = false;
  static final List<DebugLog> _logs = [];
  static final Map<String, dynamic> _context = {};

  // Debug levels
  static const int levelVerbose = 0;
  static const int levelDebug = 1;
  static const int levelInfo = 2;
  static const int levelWarning = 3;
  static const int levelError = 4;
  static const int levelCritical = 5;

  static int _currentLevel = kDebugMode ? levelDebug : levelWarning;

  /// Initialize the debug manager
  static void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;

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
    _log(levelVerbose, message, tag: tag, data: data);
  }

  /// Debug logging
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(levelDebug, message, tag: tag, data: data);
  }

  /// Info logging
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(levelInfo, message, tag: tag, data: data);
  }

  /// Warning logging
  static void warning(String message,
      {String? tag, Map<String, dynamic>? data}) {
    _log(levelWarning, message, tag: tag, data: data);
  }

  /// Error logging
  static void error(String message,
      {String? tag,
      Map<String, dynamic>? data,
      dynamic error,
      StackTrace? stackTrace}) {
    _log(levelError, message,
        tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  /// Critical error logging
  static void critical(String message,
      {String? tag,
      Map<String, dynamic>? data,
      dynamic error,
      StackTrace? stackTrace}) {
    _log(levelCritical, message,
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
    if (!kDebugMode) return;

    final levelName = _getLevelName(log.level);
    final icon = _getLevelIcon(log.level);
    final timestamp = log.timestamp.toIso8601String().substring(11, 23);

    final mainMessage =
        '$icon [$timestamp] [${log.tag}] $levelName: ${log.message}';

    debugPrint(mainMessage);

    if (log.data != null && log.data!.isNotEmpty) {
      debugPrint('  📊 Data: ${jsonEncode(log.data)}');
    }

    if (log.error != null) {
      debugPrint('  ❌ Error: ${log.error}');
      if (log.stackTrace != null) {
        debugPrint('  Stack: ${log.stackTrace}');
      }
    }
  }

  // ==================== UTILITY METHODS ====================

  static String _getLevelName(int level) {
    switch (level) {
      case levelVerbose:
        return 'VERBOSE';
      case levelDebug:
        return 'DEBUG';
      case levelInfo:
        return 'INFO';
      case levelWarning:
        return 'WARNING';
      case levelError:
        return 'ERROR';
      case levelCritical:
        return 'CRITICAL';
      default:
        return 'UNKNOWN';
    }
  }

  static String _getLevelIcon(int level) {
    switch (level) {
      case levelVerbose:
        return '🔍';
      case levelDebug:
        return '🐛';
      case levelInfo:
        return 'ℹ️';
      case levelWarning:
        return '⚠️';
      case levelError:
        return '❌';
      case levelCritical:
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
