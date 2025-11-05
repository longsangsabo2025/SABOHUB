import 'package:flutter/foundation.dart';

/// Simple Logger Service
/// Provides structured logging with different levels
/// In production, this can be integrated with Sentry, Firebase Crashlytics, etc.
class LoggerService {
  // Singleton instance
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  /// Log levels
  static const String _levelDebug = '🔍 DEBUG';
  static const String _levelInfo = '📘 INFO';
  static const String _levelWarning = '⚠️  WARNING';
  static const String _levelError = '❌ ERROR';
  static const String _levelCritical = '🔥 CRITICAL';

  /// Internal logging function
  void _log(String level, String message,
      [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $level: $message';

    if (kDebugMode) {
      // Print to console in debug mode
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }

    // TODO: In production, send to analytics service
    // Example: Sentry.captureException(error, stackTrace: stackTrace);
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Debug log - for development only
  void debug(String message, [Object? data]) {
    _log(_levelDebug, message, data);
  }

  /// Info log - general information
  void info(String message, [Object? data]) {
    _log(_levelInfo, message, data);
  }

  /// Warning log - potential issues
  void warning(String message, [Object? data]) {
    _log(_levelWarning, message, data);
  }

  /// Error log - recoverable errors
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(_levelError, message, error, stackTrace);
  }

  /// Critical log - non-recoverable errors
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    _log(_levelCritical, message, error, stackTrace);
  }

  /// Log user action for analytics
  void logUserAction(String action, [Map<String, dynamic>? properties]) {
    final props = properties != null ? ' | Props: $properties' : '';
    _log(_levelInfo, 'User Action: $action$props');

    // TODO: Send to analytics
    // Example: FirebaseAnalytics.instance.logEvent(name: action, parameters: properties);
  }

  /// Log screen view
  void logScreenView(String screenName, [Map<String, dynamic>? properties]) {
    final props = properties != null ? ' | Props: $properties' : '';
    _log(_levelInfo, 'Screen View: $screenName$props');

    // TODO: Send to analytics
    // Example: FirebaseAnalytics.instance.setCurrentScreen(screenName: screenName);
  }

  /// Log API call
  void logApiCall(String endpoint, String method,
      [int? statusCode, Duration? duration]) {
    final status = statusCode != null ? ' | Status: $statusCode' : '';
    final time =
        duration != null ? ' | Duration: ${duration.inMilliseconds}ms' : '';
    _log(_levelDebug, 'API Call: $method $endpoint$status$time');
  }

  /// Log performance metric
  void logPerformance(String metric, Duration duration,
      [Map<String, dynamic>? metadata]) {
    final meta = metadata != null ? ' | Metadata: $metadata' : '';
    _log(_levelInfo,
        'Performance: $metric took ${duration.inMilliseconds}ms$meta');

    // TODO: Send to performance monitoring
    // Example: FirebasePerformance
  }
}

/// Global logger instance
final logger = LoggerService();

/// Helper extension for easy error logging
extension ErrorLogging on Object {
  void logError(String context, [StackTrace? stackTrace]) {
    logger.error(context, this, stackTrace);
  }
}
