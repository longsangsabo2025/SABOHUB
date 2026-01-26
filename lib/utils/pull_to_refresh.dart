/// Pull-to-Refresh Support Utilities
/// Provides widgets and utilities for pull-to-refresh functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cached_providers.dart';

/// RefreshableListView - A ListView that supports pull-to-refresh
/// Automatically invalidates the provided providers on refresh
class RefreshableListView<T> extends ConsumerWidget {
  final AsyncValue<List<T>> dataProvider;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final VoidCallback onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? separator;

  const RefreshableListView({
    super.key,
    required this.dataProvider,
    required this.itemBuilder,
    required this.onRefresh,
    this.emptyBuilder,
    this.errorBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.separator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        // Wait for data to reload
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: dataProvider.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            padding: padding,
            physics: physics ?? const AlwaysScrollableScrollPhysics(),
            shrinkWrap: shrinkWrap,
            itemCount: items.length,
            separatorBuilder: (context, index) => separator ?? const SizedBox.shrink(),
            itemBuilder: (context, index) => itemBuilder(context, items[index], index),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (emptyBuilder != null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: emptyBuilder!(context),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không có dữ liệu',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    if (errorBuilder != null) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: errorBuilder!(context, error),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi: $error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// RefreshableContent - A generic content wrapper with pull-to-refresh
class RefreshableContent extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const RefreshableContent({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor,
      displacement: displacement,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}

/// Mixin for State classes that need refresh functionality
mixin RefreshableStateMixin<T extends StatefulWidget> on State<T> {
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  Future<void> handleRefresh(Future<void> Function() refreshAction) async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      await refreshAction();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}

/// Extension on WidgetRef for easy refresh operations
extension RefreshExtension on WidgetRef {
  /// Refresh all manager-related data
  void refreshManagerData() {
    refreshAllManagerData(this);
  }

  /// Refresh all task data
  void refreshTasks() {
    refreshAllManagementTasks(this);
  }

  /// Refresh all staff data
  void refreshStaff() {
    refreshAllStaffData(this);
  }

  /// Refresh specific assigned tasks
  void refreshAssignedTasks() {
    refreshManagerAssignedTasks(this);
  }

  /// Refresh specific created tasks
  void refreshCreatedTasks() {
    refreshManagerCreatedTasks(this);
  }
}

/// AsyncValueUI - A widget that renders AsyncValue with loading, error, and data states
class AsyncValueUI<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final VoidCallback? onRetry;

  const AsyncValueUI({
    super.key,
    required this.value,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stack);
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text('Lỗi: $error', textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// AsyncValueWidget - A simpler version for basic use cases
class AsyncValueWidget<T> extends ConsumerWidget {
  final FutureProvider<T> provider;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const AsyncValueWidget({
    super.key,
    required this.provider,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return AsyncValueUI<T>(
      value: value,
      builder: builder,
      loadingWidget: loadingWidget,
      errorBuilder: errorBuilder,
      onRetry: () => ref.invalidate(provider),
    );
  }
}
