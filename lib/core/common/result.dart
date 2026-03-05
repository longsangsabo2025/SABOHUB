/// Functional error handling — thay thế throw/catch tràn lan.
///
/// Dùng [Result] để wrap kết quả operations có thể fail,
/// giúp caller xử lý lỗi tường minh thay vì dùng try-catch.
///
/// ```dart
/// // Trong Repository:
/// Future<Result<List<Order>>> getOrders(String companyId) async {
///   try {
///     final orders = await _service.getOrders(companyId);
///     return Result.success(orders);
///   } on AppError catch (e) {
///     return Result.failure(e);
///   }
/// }
///
/// // Trong ViewModel / Provider:
/// final result = await _repo.getOrders(companyId);
/// result.when(
///   success: (orders) => state = AsyncData(orders),
///   failure: (error) => state = AsyncError(error, StackTrace.current),
/// );
/// ```
library;

import '../errors/app_errors.dart';

/// A sealed Result type for functional error handling.
///
/// Forces the caller to handle both success and failure cases
/// instead of relying on try-catch.
sealed class Result<T> {
  const Result();

  /// Create a successful result.
  const factory Result.success(T data) = Success<T>;

  /// Create a failed result.
  const factory Result.failure(AppError error) = Failure<T>;

  /// Pattern match on the result.
  ///
  /// Both [success] and [failure] callbacks are required,
  /// ensuring exhaustive handling.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }

  /// Map the success value to a new type.
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(:final data) => Result.success(transform(data)),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Chain async operations that return Result.
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    return switch (this) {
      Success(:final data) => transform(data),
      Failure(:final error) => Result.failure(error),
    };
  }

  /// Get data or null.
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Get error or null.
  AppError? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  /// Check if this is a success.
  bool get isSuccess => this is Success<T>;

  /// Check if this is a failure.
  bool get isFailure => this is Failure<T>;

  /// Get data or throw the AppError.
  ///
  /// Use sparingly — prefer [when] for explicit handling.
  T get dataOrThrow => switch (this) {
        Success(:final data) => data,
        Failure(:final error) => throw error,
      };
}

/// Successful result containing [data].
final class Success<T> extends Result<T> {
  /// The success value.
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// Failed result containing an [AppError].
final class Failure<T> extends Result<T> {
  /// The error that caused the failure.
  final AppError error;

  const Failure(this.error);

  @override
  String toString() => 'Failure(${error.message})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// Extension to convert a Future into a Result.
///
/// Useful for wrapping existing service calls:
/// ```dart
/// final result = await _service.getOrders(companyId).toResult();
/// ```
extension FutureResultExtension<T> on Future<T> {
  /// Execute this Future and wrap the outcome in a [Result].
  ///
  /// [AppError] exceptions become [Failure]; all other exceptions
  /// are wrapped in a [SystemError] → [Failure].
  Future<Result<T>> toResult() async {
    try {
      return Result.success(await this);
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stack) {
      return Result.failure(SystemError(
        message: e.toString(),
        stackTrace: stack,
      ));
    }
  }
}
