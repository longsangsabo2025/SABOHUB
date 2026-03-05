import 'package:flutter/foundation.dart';

/// Error tracking utility for production monitoring
/// Logs errors and performance metrics
class ErrorTracker {
  static final ErrorTracker _instance = ErrorTracker._internal();
  factory ErrorTracker() => _instance;
  ErrorTracker._internal();

  bool _initialized = false;

  /// Initialize error tracking
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[ErrorTracker] Initialized');
  }

  /// Track an error
  void trackError(dynamic error, {StackTrace? stackTrace, String? context}) {
    debugPrint('[ErrorTracker] Error: $error${context != null ? ' ($context)' : ''}');
  }

  /// Track a performance event
  void trackPerformance(String name, Duration duration) {
    debugPrint('[ErrorTracker] Performance: $name took ${duration.inMilliseconds}ms');
  }
}
