import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Error Tracking System for SABOHUB
/// Captures, logs, and reports errors with context
class ErrorTracker {
  static final ErrorTracker _instance = ErrorTracker._internal();
  factory ErrorTracker() => _instance;
  ErrorTracker._internal();

  final List<ErrorReport> _errors = [];
  final int _maxErrors = 100; // Keep last 100 errors

  static const String _storageKey = 'sabohub_error_logs';

  /// Initialize error tracking
  Future<void> initialize() async {
    await _loadStoredErrors();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Flutter Framework Error',
        additionalInfo: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        error: error,
        stackTrace: stack,
        context: 'Async Error',
      );
      return true;
    };
  }

  /// Report an error with full context
  void reportError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final report = ErrorReport(
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'Unknown',
      additionalInfo: additionalInfo ?? {},
      severity: severity,
      timestamp: DateTime.now(),
      userId: _getCurrentUserId(),
      appVersion: _getAppVersion(),
      platform: _getPlatform(),
    );

    _addError(report);
    _logError(report);
    _storeErrors();

    // In production, you might want to send to crash reporting service
    if (kReleaseMode && severity == ErrorSeverity.critical) {
      _sendToCrashReporting(report);
    }
  }

  /// Report a handled exception
  void reportHandledException(
    Object exception, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    reportError(
      error: exception,
      stackTrace: stackTrace,
      context: context,
      additionalInfo: additionalInfo,
      severity: ErrorSeverity.warning,
    );
  }

  /// Report a critical error that might crash the app
  void reportCriticalError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
  }) {
    reportError(
      error: error,
      stackTrace: stackTrace,
      context: context,
      additionalInfo: additionalInfo,
      severity: ErrorSeverity.critical,
    );
  }

  /// Report an info level event (for debugging)
  void reportInfo(
    String message, {
    Map<String, dynamic>? additionalInfo,
  }) {
    reportError(
      error: message,
      context: 'Info',
      additionalInfo: additionalInfo,
      severity: ErrorSeverity.info,
    );
  }

  /// Add error to internal list
  void _addError(ErrorReport report) {
    _errors.add(report);

    // Keep only recent errors
    if (_errors.length > _maxErrors) {
      _errors.removeAt(0);
    }
  }

  /// Log error to console/debug output
  void _logError(ErrorReport report) {
    if (kDebugMode) {
      final severity = report.severity.name.toUpperCase();
      debugPrint('🚨 [$severity] ${report.context}: ${report.error}');
      if (report.stackTrace != null) {
        debugPrint('Stack trace: ${report.stackTrace}');
      }
      if (report.additionalInfo.isNotEmpty) {
        debugPrint('Additional info: ${report.additionalInfo}');
      }
    }
  }

  /// Store errors to local storage
  Future<void> _storeErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorData = _errors.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(errorData));
    } catch (e) {
      debugPrint('Failed to store errors: $e');
    }
  }

  /// Load stored errors from local storage
  Future<void> _loadStoredErrors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_storageKey);

      if (storedData != null) {
        final List<dynamic> errorData = jsonDecode(storedData);
        _errors.clear();
        _errors.addAll(errorData.map((e) => ErrorReport.fromJson(e)));
      }
    } catch (e) {
      debugPrint('Failed to load stored errors: $e');
    }
  }

  /// Send to crash reporting service (placeholder)
  Future<void> _sendToCrashReporting(ErrorReport report) async {
    // In production, implement actual crash reporting
    // Examples: Firebase Crashlytics, Sentry, Bugsnag
    debugPrint('Sending critical error to crash reporting: ${report.error}');
  }

  /// Get current user ID (from auth state)
  String? _getCurrentUserId() {
    // You would get this from your auth provider
    return 'current_user_id';
  }

  /// Get app version
  String _getAppVersion() {
    return '1.0.0'; // You would get this from package info
  }

  /// Get platform info
  String _getPlatform() {
    return '${defaultTargetPlatform.name} (${kIsWeb ? 'Web' : 'Native'})';
  }

  /// Get all errors
  List<ErrorReport> getErrors({ErrorSeverity? severity}) {
    if (severity == null) return List.from(_errors);
    return _errors.where((e) => e.severity == severity).toList();
  }

  /// Get recent errors
  List<ErrorReport> getRecentErrors({int limit = 20}) {
    final sorted = List<ErrorReport>.from(_errors)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get error statistics
  ErrorStatistics getStatistics() {
    final now = DateTime.now();
    final last24h = now.subtract(const Duration(hours: 24));
    final lastWeek = now.subtract(const Duration(days: 7));

    final errors24h = _errors.where((e) => e.timestamp.isAfter(last24h)).length;
    final errorsWeek =
        _errors.where((e) => e.timestamp.isAfter(lastWeek)).length;

    final bySeverity = <ErrorSeverity, int>{};
    for (final error in _errors) {
      bySeverity[error.severity] = (bySeverity[error.severity] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalErrors: _errors.length,
      errorsLast24h: errors24h,
      errorsLastWeek: errorsWeek,
      bySeverity: bySeverity,
    );
  }

  /// Clear all errors
  Future<void> clearErrors() async {
    _errors.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Export errors as JSON string
  String exportErrors() {
    return jsonEncode(_errors.map((e) => e.toJson()).toList());
  }
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error report data class
class ErrorReport {
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final Map<String, dynamic> additionalInfo;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? userId;
  final String appVersion;
  final String platform;

  ErrorReport({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.additionalInfo,
    required this.severity,
    required this.timestamp,
    this.userId,
    required this.appVersion,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'additionalInfo': additionalInfo,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'appVersion': appVersion,
      'platform': platform,
    };
  }

  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      error: json['error'] ?? 'Unknown error',
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'])
          : null,
      context: json['context'] ?? 'Unknown',
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      userId: json['userId'],
      appVersion: json['appVersion'] ?? 'Unknown',
      platform: json['platform'] ?? 'Unknown',
    );
  }

  @override
  String toString() {
    return 'ErrorReport(severity: ${severity.name}, context: $context, error: $error)';
  }
}

/// Error statistics data class
class ErrorStatistics {
  final int totalErrors;
  final int errorsLast24h;
  final int errorsLastWeek;
  final Map<ErrorSeverity, int> bySeverity;

  ErrorStatistics({
    required this.totalErrors,
    required this.errorsLast24h,
    required this.errorsLastWeek,
    required this.bySeverity,
  });
}

/// Widget wrapper for error boundary
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.red.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {
                _error = null;
                _stackTrace = null;
              }),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
        _stackTrace = details.stack;
      });

      ErrorTracker().reportError(
        error: details.exception,
        stackTrace: details.stack,
        context: 'Widget Error Boundary',
      );
    };
  }
}
