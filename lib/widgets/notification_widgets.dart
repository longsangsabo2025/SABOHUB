import 'package:flutter/material.dart';

/// Enum định nghĩa các loại thông báo
enum NotificationType {
  success,
  error,
  warning,
  info,
  loading,
}

/// Widget hiển thị thông báo với các style khác nhau
class NotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onDismiss;
  final Duration? duration;
  final Widget? action;

  const NotificationBanner({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
    this.duration,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(type);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        border: Border.all(color: config.borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            config.icon,
            color: config.iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: config.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: config.textColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: config.textColor.withOpacity(0.7),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  _NotificationConfig _getNotificationConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationConfig(
          title: '✅ Thành công',
          icon: Icons.check_circle_outline,
          backgroundColor: const Color(0xFFF0F9FF),
          borderColor: const Color(0xFF10B981),
          iconColor: const Color(0xFF10B981),
          textColor: const Color(0xFF064E3B),
        );
      case NotificationType.error:
        return _NotificationConfig(
          title: '❌ Lỗi',
          icon: Icons.error_outline,
          backgroundColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFEF4444),
          iconColor: const Color(0xFFEF4444),
          textColor: const Color(0xFF7F1D1D),
        );
      case NotificationType.warning:
        return _NotificationConfig(
          title: '⚠️ Cảnh báo',
          icon: Icons.warning_outlined,
          backgroundColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFF59E0B),
          iconColor: const Color(0xFFF59E0B),
          textColor: const Color(0xFF78350F),
        );
      case NotificationType.info:
        return _NotificationConfig(
          title: 'ℹ️ Thông tin',
          icon: Icons.info_outline,
          backgroundColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFF3B82F6),
          iconColor: const Color(0xFF3B82F6),
          textColor: const Color(0xFF1E3A8A),
        );
      case NotificationType.loading:
        return _NotificationConfig(
          title: '⏳ Đang xử lý',
          icon: Icons.refresh,
          backgroundColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFF64748B),
          iconColor: const Color(0xFF64748B),
          textColor: const Color(0xFF334155),
        );
    }
  }
}

/// Model cấu hình cho notification
class _NotificationConfig {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  _NotificationConfig({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// Widget loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating Action Button cho thông báo
class NotificationFloatingButton extends StatelessWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onTap;

  const NotificationFloatingButton({
    super.key,
    required this.message,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getNotificationConfig(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          border: Border.all(color: config.borderColor),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              color: config.iconColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: config.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotificationConfig _getNotificationConfig(NotificationType type) {
    // Same logic as NotificationBanner
    switch (type) {
      case NotificationType.success:
        return _NotificationConfig(
          title: 'Thành công',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFFD1FAE5),
          borderColor: const Color(0xFF10B981),
          iconColor: const Color(0xFF059669),
          textColor: const Color(0xFF065F46),
        );
      case NotificationType.error:
        return _NotificationConfig(
          title: 'Lỗi',
          icon: Icons.error,
          backgroundColor: const Color(0xFFFECDD3),
          borderColor: const Color(0xFFEF4444),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFF991B1B),
        );
      case NotificationType.warning:
        return _NotificationConfig(
          title: 'Cảnh báo',
          icon: Icons.warning,
          backgroundColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFF59E0B),
          iconColor: const Color(0xFFD97706),
          textColor: const Color(0xFF92400E),
        );
      case NotificationType.info:
        return _NotificationConfig(
          title: 'Thông tin',
          icon: Icons.info,
          backgroundColor: const Color(0xFFDBEAFE),
          borderColor: const Color(0xFF3B82F6),
          iconColor: const Color(0xFF2563EB),
          textColor: const Color(0xFF1D4ED8),
        );
      case NotificationType.loading:
        return _NotificationConfig(
          title: 'Đang xử lý',
          icon: Icons.hourglass_empty,
          backgroundColor: const Color(0xFFF1F5F9),
          borderColor: const Color(0xFF64748B),
          iconColor: const Color(0xFF475569),
          textColor: const Color(0xFF334155),
        );
    }
  }
}
