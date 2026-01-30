import 'package:flutter/material.dart';
import 'sabo_refresh_button.dart';

/// Empty state widget with icon, title, and optional action
class SaboEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;

  const SaboEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 64,
    this.iconColor,
  });

  /// Factory constructor for common "no data" state
  factory SaboEmptyState.noData({
    String title = 'Không có dữ liệu',
    String? subtitle,
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for common "no results" state (search)
  factory SaboEmptyState.noResults({
    String title = 'Không tìm thấy kết quả',
    String? subtitle = 'Thử tìm kiếm với từ khóa khác',
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.search_off_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for "no orders" state
  factory SaboEmptyState.noOrders({
    String title = 'Chưa có đơn hàng',
    String? subtitle,
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.receipt_long_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for "no customers" state
  factory SaboEmptyState.noCustomers({
    String title = 'Chưa có khách hàng',
    String? subtitle,
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.people_outline,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for "no products" state
  factory SaboEmptyState.noProducts({
    String title = 'Chưa có sản phẩm',
    String? subtitle,
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.inventory_2_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for "no deliveries" state
  factory SaboEmptyState.noDeliveries({
    String title = 'Chưa có giao hàng',
    String? subtitle,
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.local_shipping_outlined,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory constructor for error state
  factory SaboEmptyState.error({
    String title = 'Đã xảy ra lỗi',
    String? subtitle = 'Vui lòng thử lại sau',
    Widget? action,
  }) {
    return SaboEmptyState(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      action: action,
      iconColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget
class SaboLoadingState extends StatelessWidget {
  final String? message;
  final double size;

  const SaboLoadingState({
    super.key,
    this.message,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state widget with retry action
class SaboErrorState extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const SaboErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, color: SaboRefreshButton.refreshColor),
                label: Text('Thử lại', style: TextStyle(color: SaboRefreshButton.refreshColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: SaboRefreshButton.refreshColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic async content builder
class SaboAsyncContent<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object? error)? errorBuilder;
  final Widget? empty;
  final bool Function(T data)? isEmpty;

  const SaboAsyncContent({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loading,
    this.errorBuilder,
    this.empty,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loading ?? const SaboLoadingState();
    }

    if (snapshot.hasError) {
      if (errorBuilder != null) {
        return errorBuilder!(snapshot.error);
      }
      return SaboErrorState(
        message: snapshot.error.toString(),
      );
    }

    if (!snapshot.hasData) {
      return empty ?? SaboEmptyState.noData();
    }

    final data = snapshot.data as T;
    
    if (isEmpty != null && isEmpty!(data)) {
      return empty ?? SaboEmptyState.noData();
    }

    return builder(data);
  }
}
