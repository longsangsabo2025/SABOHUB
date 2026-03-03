import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_errors.dart';
import '../errors/error_handler.dart';

/// Base service class for all Supabase services.
///
/// Provides:
/// - Centralized Supabase client access (single source of truth)
/// - Typed error handling via [AppError] hierarchy
/// - Consistent logging in debug mode
/// - Required [companyId] enforcement pattern
///
/// Usage:
/// ```dart
/// class MyService extends BaseService {
///   Future<List<Item>> getItems(String companyId) async {
///     return safeCall(
///       operation: 'getItems',
///       action: () async {
///         final data = await client.from('items')
///             .select()
///             .eq('company_id', companyId);
///         return (data as List).map((e) => Item.fromJson(e)).toList();
///       },
///     );
///   }
/// }
/// ```
abstract class BaseService {
  /// Supabase client — single access point for all services
  @protected
  SupabaseClient get client => Supabase.instance.client;

  /// Error handler singleton
  @protected
  ErrorHandler get errorHandler => ErrorHandler();

  /// Service name for logging (override in subclass)
  String get serviceName => runtimeType.toString();

  /// Execute a Supabase operation with unified error handling.
  ///
  /// Catches all exceptions, converts them to typed [AppError],
  /// logs in debug mode, and re-throws as [AppError].
  ///
  /// [operation] — Name of the operation for logging (e.g. 'getAllOrders')
  /// [action] — The async action to execute
  @protected
  Future<T> safeCall<T>({
    required String operation,
    required Future<T> Function() action,
  }) async {
    try {
      return await action();
    } on AppError {
      rethrow; // Already a typed error, pass through
    } on PostgrestException catch (e, stack) {
      final appError = _handlePostgrestError(e, stack, operation);
      throw appError;
    } on AuthException catch (e, stack) {
      final appError = AuthenticationError(
        message: e.message,
        code: e.statusCode,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
      _logError(appError, operation);
      throw appError;
    } catch (e, stack) {
      final appError = errorHandler.handleError(e, stack);
      _logError(appError, operation);
      throw appError;
    }
  }

  /// Convert PostgREST errors to typed [AppError]
  AppError _handlePostgrestError(
    PostgrestException e,
    StackTrace stack,
    String operation,
  ) {
    final code = e.code;
    final message = e.message;

    AppError appError;

    // Map common PostgREST error codes
    if (code == '42501' || code == 'PGRST301') {
      appError = PermissionError(
        message: 'Không có quyền: $message',
        code: code,
        requiredPermission: operation,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else if (code == 'PGRST116') {
      // Single row expected, 0 found
      appError = ValidationError(
        message: 'Không tìm thấy dữ liệu: $message',
        code: code,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else if (code == '23505') {
      // Unique violation
      appError = ValidationError(
        message: 'Dữ liệu đã tồn tại: $message',
        code: code,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else if (code == '23503') {
      // Foreign key violation
      appError = ValidationError(
        message: 'Dữ liệu tham chiếu không hợp lệ: $message',
        code: code,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else if (code == '23514') {
      // Check constraint violation
      appError = ValidationError(
        message: 'Dữ liệu không hợp lệ: $message',
        code: code,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else if (code != null && code.startsWith('08')) {
      // Connection errors
      appError = NetworkError(
        message: 'Lỗi kết nối database: $message',
        code: code,
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    } else {
      appError = SystemError(
        message: 'Lỗi database: $message',
        code: code ?? 'UNKNOWN',
        stackTrace: stack,
        metadata: {'operation': operation, 'service': serviceName},
      );
    }

    _logError(appError, operation);
    return appError;
  }

  /// Log error in debug mode
  void _logError(AppError error, String operation) {
    if (kDebugMode) {
      developer.log(
        '[$serviceName.$operation] ${error.category.name}: ${error.message}',
        name: 'SABO_SERVICE',
        error: error,
        stackTrace: error.stackTrace,
      );
    }
  }

  /// Log info in debug mode
  @protected
  void logInfo(String operation, String message) {
    if (kDebugMode) {
      developer.log(
        '[$serviceName.$operation] $message',
        name: 'SABO_SERVICE',
      );
    }
  }
}
