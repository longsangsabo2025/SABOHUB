import 'package:flutter/material.dart';
import 'sabo_refresh_button.dart';

/// Enhanced error display widget with retry functionality
class ErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool compact;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.customMessage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? _getErrorMessage(error);

    if (compact) {
      return _buildCompact(context, message);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(error),
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getErrorTitle(error),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SaboRefreshButton.refreshColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRetry,
              color: SaboRefreshButton.refreshColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
    }

    if (errorStr.contains('timeout')) {
      return 'Yêu cầu quá thời gian chờ. Vui lòng thử lại.';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'Bạn không có quyền truy cập tài nguyên này.';
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Không tìm thấy dữ liệu yêu cầu.';
    }

    if (errorStr.contains('server') || errorStr.contains('500')) {
      return 'Lỗi máy chủ. Vui lòng thử lại sau.';
    }

    return error.toString();
  }

  String _getErrorTitle(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection')) {
      return 'Lỗi kết nối';
    }

    if (errorStr.contains('timeout')) {
      return 'Hết thời gian chờ';
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Chưa xác thực';
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return 'Không có quyền';
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return 'Không tìm thấy';
    }

    return 'Đã xảy ra lỗi';
  }

  IconData _getErrorIcon(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('connection')) {
      return Icons.wifi_off;
    }

    if (errorStr.contains('timeout')) {
      return Icons.timer_off;
    }

    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return Icons.lock_outline;
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return Icons.block;
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return Icons.search_off;
    }

    return Icons.error_outline;
  }
}

/// Empty state display widget
class EmptyStateDisplay extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;
  final Color? iconColor;

  const EmptyStateDisplay({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
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

  /// Factory for common empty states
  factory EmptyStateDisplay.noData({VoidCallback? onRefresh}) {
    return EmptyStateDisplay(
      title: 'Không có dữ liệu',
      subtitle: 'Chưa có dữ liệu nào để hiển thị',
      icon: Icons.inbox_outlined,
      action: onRefresh != null
          ? TextButton.icon(
              onPressed: onRefresh,
              icon: Icon(Icons.refresh, color: SaboRefreshButton.refreshColor),
              label: Text('Làm mới', style: TextStyle(color: SaboRefreshButton.refreshColor)),
            )
          : null,
    );
  }

  factory EmptyStateDisplay.noOrders() {
    return const EmptyStateDisplay(
      title: 'Chưa có đơn hàng',
      subtitle: 'Các đơn hàng mới sẽ xuất hiện ở đây',
      icon: Icons.receipt_long_outlined,
      iconColor: Colors.orange,
    );
  }

  factory EmptyStateDisplay.noDeliveries() {
    return const EmptyStateDisplay(
      title: 'Không có đơn giao hôm nay',
      subtitle: 'Nghỉ ngơi thôi! 🎉',
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  factory EmptyStateDisplay.noTasks() {
    return const EmptyStateDisplay(
      title: 'Không có công việc',
      subtitle: 'Tất cả công việc đã hoàn thành!',
      icon: Icons.task_alt,
      iconColor: Colors.green,
    );
  }

  factory EmptyStateDisplay.noNotifications() {
    return const EmptyStateDisplay(
      title: 'Không có thông báo',
      subtitle: 'Bạn đã đọc hết thông báo',
      icon: Icons.notifications_none,
      iconColor: Colors.blue,
    );
  }

  factory EmptyStateDisplay.noStaff() {
    return const EmptyStateDisplay(
      title: 'Chưa có nhân viên',
      subtitle: 'Thêm nhân viên vào đội ngũ của bạn',
      icon: Icons.people_outline,
      iconColor: Colors.purple,
    );
  }

  factory EmptyStateDisplay.noCustomers() {
    return const EmptyStateDisplay(
      title: 'Chưa có khách hàng',
      subtitle: 'Thêm khách hàng đầu tiên của bạn',
      icon: Icons.person_add_outlined,
      iconColor: Colors.teal,
    );
  }

  factory EmptyStateDisplay.searchNoResults(String query) {
    return EmptyStateDisplay(
      title: 'Không tìm thấy kết quả',
      subtitle: 'Không có kết quả nào cho "$query"',
      icon: Icons.search_off,
      iconColor: Colors.grey,
    );
  }
}

/// Loading overlay for full-screen loading
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: barrierColor ?? Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Success/Confirmation display
class SuccessDisplay extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onDismiss;

  const SuccessDisplay({
    super.key,
    required this.title,
    this.subtitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đóng'),
            ),
          ],
        ],
      ),
    );
  }
}
