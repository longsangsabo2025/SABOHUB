import 'package:flutter/material.dart';
import '../widgets/notification_widgets.dart';

/// Service quản lý hệ thống thông báo toàn app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Context để hiển thị SnackBar
  BuildContext? _context;

  /// Overlay để hiển thị notifications
  OverlayEntry? _currentOverlay;

  /// Khởi tạo service với context
  void initialize(BuildContext context) {
    _context = context;
  }

  /// Hiển thị thông báo thành công
  void showSuccess(String message, {Duration? duration}) {
    _showNotification(
      message: message,
      type: NotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Hiển thị thông báo lỗi
  void showError(String message, {Duration? duration}) {
    _showNotification(
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// Hiển thị cảnh báo
  void showWarning(String message, {Duration? duration}) {
    _showNotification(
      message: message,
      type: NotificationType.warning,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Hiển thị thông tin
  void showInfo(String message, {Duration? duration}) {
    _showNotification(
      message: message,
      type: NotificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Hiển thị thông báo loading
  void showLoading(String message) {
    _showNotification(
      message: message,
      type: NotificationType.loading,
      duration: null, // Không tự động ẩn
    );
  }

  /// Ẩn thông báo hiện tại
  void hideNotification() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }

  /// Hiển thị SnackBar đơn giản
  void showSnackBar(String message, NotificationType type) {
    if (_context == null) return;

    final config = _getSnackBarConfig(type);

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hiển thị dialog lỗi chi tiết
  void showErrorDialog({
    required String title,
    required String message,
    String? details,
    List<Widget>? actions,
  }) {
    if (_context == null) return;

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            if (details != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết lỗi:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: actions ??
            [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
      ),
    );
  }

  /// Hiển thị bottom sheet với thông báo
  void showBottomNotification({
    required String message,
    required NotificationType type,
    List<Widget>? actions,
  }) {
    if (_context == null) return;

    showModalBottomSheet(
      context: _context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationBanner(
              message: message,
              type: type,
            ),
            if (actions != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Private method để hiển thị overlay notification
  void _showNotification({
    required String message,
    required NotificationType type,
    Duration? duration,
  }) {
    if (_context == null) return;

    // Ẩn notification hiện tại nếu có
    hideNotification();

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: NotificationBanner(
            message: message,
            type: type,
            onDismiss: hideNotification,
          ),
        ),
      ),
    );

    Overlay.of(_context!).insert(_currentOverlay!);

    // Tự động ẩn sau duration nếu có
    if (duration != null) {
      Future.delayed(duration, () {
        hideNotification();
      });
    }
  }

  /// Cấu hình cho SnackBar
  _SnackBarConfig _getSnackBarConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _SnackBarConfig(
          icon: Icons.check_circle,
          backgroundColor: Colors.green.shade600,
        );
      case NotificationType.error:
        return _SnackBarConfig(
          icon: Icons.error,
          backgroundColor: Colors.red.shade600,
        );
      case NotificationType.warning:
        return _SnackBarConfig(
          icon: Icons.warning,
          backgroundColor: Colors.orange.shade600,
        );
      case NotificationType.info:
        return _SnackBarConfig(
          icon: Icons.info,
          backgroundColor: Colors.blue.shade600,
        );
      case NotificationType.loading:
        return _SnackBarConfig(
          icon: Icons.hourglass_empty,
          backgroundColor: Colors.grey.shade600,
        );
    }
  }
}

/// Model cấu hình SnackBar
class _SnackBarConfig {
  final IconData icon;
  final Color backgroundColor;

  _SnackBarConfig({
    required this.icon,
    required this.backgroundColor,
  });
}

/// Extension cho BuildContext để dễ sử dụng
extension NotificationExtension on BuildContext {
  NotificationService get notifications => NotificationService();
}

/// Mixin để dễ sử dụng trong StatefulWidget
mixin NotificationMixin<T extends StatefulWidget> on State<T> {
  NotificationService get notifications => NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifications.initialize(context);
    });
  }

  /// Hiển thị lỗi từ Exception
  void showErrorFromException(dynamic error, {String? customMessage}) {
    String message = customMessage ?? 'Đã xảy ra lỗi không mong muốn';
    String? details;

    if (error is Exception) {
      details = error.toString();
    } else if (error is Error) {
      details = error.toString();
    } else {
      details = error?.toString();
    }

    notifications.showErrorDialog(
      title: 'Lỗi hệ thống',
      message: message,
      details: details,
    );
  }

  /// Hiển thị loading với auto-hide
  void showLoadingNotification(String message) {
    notifications.showLoading(message);
  }

  /// Ẩn loading
  void hideLoadingNotification() {
    notifications.hideNotification();
  }
}
