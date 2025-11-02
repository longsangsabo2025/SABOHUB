import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_errors.dart';

/// Error handler service for centralized error management
class ErrorHandler {
  static final _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Error listeners
  final List<Function(AppError)> _listeners = [];

  /// Add error listener
  void addListener(Function(AppError) listener) {
    _listeners.add(listener);
  }

  /// Remove error listener
  void removeListener(Function(AppError) listener) {
    _listeners.remove(listener);
  }

  /// Handle any error and convert to AppError
  AppError handleError(Object error, [StackTrace? stackTrace]) {
    final appError = _convertToAppError(error, stackTrace);

    // Log error
    _logError(appError);

    // Report to error tracking service if needed
    if (appError.shouldReport) {
      _reportError(appError);
    }

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(appError);
      } catch (e) {
        // Don't let listener errors crash the app
        _logError(SystemError(message: 'Error in error listener: $e'));
      }
    }

    return appError;
  }

  /// Convert any error to AppError
  AppError _convertToAppError(Object error, StackTrace? stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Handle specific error types
    if (error is FormatException) {
      return ValidationError(
        message: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return ValidationError(
        message: error.message ?? 'Invalid argument',
        stackTrace: stackTrace,
      );
    }

    // Handle network errors (will be extended when Dio is added)
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return NetworkError(
        message: 'Network connection failed',
        stackTrace: stackTrace,
      );
    }

    // Default to unknown error
    return UnknownError(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error to console in debug mode
  void _logError(AppError error) {
    if (kDebugMode) {
      developer.log(
        'Error: ${error.message}',
        name: 'SABOHUB_ERROR',
        error: error,
        stackTrace: error.stackTrace,
        level: _getLogLevel(error.severity),
      );
    }
  }

  /// Get log level based on error severity
  int _getLogLevel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 500; // INFO
      case ErrorSeverity.medium:
        return 900; // WARNING
      case ErrorSeverity.high:
        return 1000; // SEVERE
      case ErrorSeverity.critical:
        return 1200; // SHOUT
    }
  }

  /// Report error to external service (placeholder for future implementation)
  void _reportError(AppError error) {
    // TODO: Implement error reporting to services like Sentry, Crashlytics, etc.
    if (kDebugMode) {
      developer.log(
        'Would report error to external service: ${error.message}',
        name: 'SABOHUB_ERROR_REPORT',
      );
    }
  }
}

/// Global error handler function
AppError handleError(Object error, [StackTrace? stackTrace]) {
  return ErrorHandler().handleError(error, stackTrace);
}

/// Riverpod provider for error handler
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});
