import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/result.dart';
import '../errors/app_errors.dart';

/// State holder for a ViewModel that manages loading / data / error states.
///
/// Works with Riverpod's [AsyncNotifier] to provide a standard ViewModel
/// lifecycle that matches Flutter Architecture Guide 2026 MVVM pattern.
///
/// Usage:
/// ```dart
/// class OrderListViewModel extends BaseViewModel<List<Order>> {
///   @override
///   Future<List<Order>> build() async {
///     final repo = ref.read(orderRepositoryProvider);
///     return repo.getOrders(companyId).then((r) => r.dataOrThrow);
///   }
///
///   Future<void> deleteOrder(String id) async {
///     await execute(() => ref.read(orderRepositoryProvider).deleteOrder(id));
///     ref.invalidateSelf(); // refresh list
///   }
/// }
/// ```
///
/// Guidelines:
/// - ❌ KHÔNG import 'package:flutter/material.dart' trong ViewModel
/// - ❌ KHÔNG reference bất kỳ Widget/BuildContext nào
/// - ✅ Chỉ chứa business logic + state management
/// - ✅ Dùng [execute] để wrap async operations có Result
/// - ✅ 1 View ↔ 1 ViewModel
abstract class BaseViewModel<T> extends AsyncNotifier<T> {
  /// Execute an async operation that returns [Result],
  /// auto-handling loading and error states.
  ///
  /// Returns the unwrapped data on success, or null on failure.
  ///
  /// ```dart
  /// final order = await execute(
  ///   () => _repo.createOrder(data),
  ///   onSuccess: (order) => AppLogger.info('Created: ${order.id}'),
  ///   onFailure: (error) => AppLogger.error('Failed: ${error.message}'),
  /// );
  /// ```
  Future<S?> execute<S>(
    Future<Result<S>> Function() action, {
    void Function(S data)? onSuccess,
    void Function(AppError error)? onFailure,
  }) async {
    final result = await action();
    return result.when(
      success: (data) {
        onSuccess?.call(data);
        return data;
      },
      failure: (error) {
        onFailure?.call(error);
        return null;
      },
    );
  }

  /// Execute an async operation and update this ViewModel's state
  /// based on the [Result].
  ///
  /// On success, [updateState] is called with current state + new data
  /// to produce the next state.
  ///
  /// ```dart
  /// await executeAndUpdate(
  ///   () => _repo.updateOrder(orderId, updates),
  ///   updateState: (currentState, updatedOrder) {
  ///     return currentState.copyWith(selectedOrder: updatedOrder);
  ///   },
  /// );
  /// ```
  Future<void> executeAndUpdate<S>(
    Future<Result<S>> Function() action, {
    required T Function(T currentState, S data) updateState,
    void Function(AppError error)? onFailure,
  }) async {
    final currentState = state.value;
    if (currentState == null) return;

    final result = await action();
    result.when(
      success: (data) {
        state = AsyncData(updateState(currentState, data));
      },
      failure: (error) {
        onFailure?.call(error);
        // Keep current state, don't blow away data on error
        // Caller can decide to set error state via onFailure callback
      },
    );
  }

  /// Set state to loading (preserves previous data via AsyncLoading).
  void setLoading() {
    state = const AsyncLoading();
  }

  /// Set state to error, preserving previous data.
  void setError(AppError error) {
    state = AsyncError(error, StackTrace.current);
  }
}
