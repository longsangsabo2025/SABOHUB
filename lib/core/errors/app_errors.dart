/// Error handling models and types
library;

import 'package:equatable/equatable.dart';

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Error categories for better handling
enum ErrorCategory {
  network,
  authentication,
  validation,
  permission,
  system,
  unknown,
}

/// Application error base class
abstract class AppError extends Equatable implements Exception {
  final String message;
  final String? code;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.message,
    this.code,
    required this.severity,
    required this.category,
    this.stackTrace,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
        message,
        code,
        severity,
        category,
        timestamp,
        metadata,
      ];

  /// Convert error to user-friendly message
  String get userMessage {
    switch (category) {
      case ErrorCategory.network:
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
      case ErrorCategory.authentication:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case ErrorCategory.validation:
        return message; // Validation messages are usually user-friendly
      case ErrorCategory.permission:
        return 'Bạn không có quyền thực hiện hành động này.';
      case ErrorCategory.system:
        return 'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.';
      case ErrorCategory.unknown:
        return 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
    }
  }

  /// Check if error should be reported to error tracking service
  bool get shouldReport =>
      severity == ErrorSeverity.high || severity == ErrorSeverity.critical;
}

/// Network-related errors
class NetworkError extends AppError {
  final int? statusCode;
  final String? endpoint;

  NetworkError({
    required super.message,
    super.code,
    this.statusCode,
    this.endpoint,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.medium,
          category: ErrorCategory.network,
        );

  @override
  List<Object?> get props => [...super.props, statusCode, endpoint];
}

/// Authentication errors
class AuthenticationError extends AppError {
  AuthenticationError({
    required super.message,
    super.code,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.high,
          category: ErrorCategory.authentication,
        );
}

/// Validation errors
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;

  ValidationError({
    required super.message,
    super.code,
    this.fieldErrors,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.low,
          category: ErrorCategory.validation,
        );

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

/// Permission errors
class PermissionError extends AppError {
  final String? requiredPermission;

  PermissionError({
    required super.message,
    super.code,
    this.requiredPermission,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.medium,
          category: ErrorCategory.permission,
        );

  @override
  List<Object?> get props => [...super.props, requiredPermission];
}

/// System errors
class SystemError extends AppError {
  SystemError({
    required super.message,
    super.code,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.critical,
          category: ErrorCategory.system,
        );
}

/// Unknown errors
class UnknownError extends AppError {
  final Object? originalError;

  UnknownError({
    required super.message,
    super.code,
    this.originalError,
    super.stackTrace,
    super.metadata,
  }) : super(
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );

  @override
  List<Object?> get props => [...super.props, originalError];
}
