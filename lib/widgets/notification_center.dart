import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../business_types/distribution/services/odori_notification_service.dart';

/// Format a DateTime as relative time in Vietnamese
String _formatTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Vừa xong';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} giờ trước';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  } else {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}

/// Notification Bell Widget - Shows unread count badge
class NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;

  const NotificationBell({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(odoriUnreadCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onTap,
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Notification Center Page
class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(odoriNotificationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(odoriNotificationStateProvider.notifier).markAllAsRead();
              },
              child: const Text('Đọc tất cả'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(odoriNotificationStateProvider.notifier).clearAll();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Xóa tất cả'),
              ),
            ],
          ),
        ],
      ),
      body: state.notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return NotificationTile(
                  notification: notification,
                  onTap: () {
                    ref
                        .read(odoriNotificationStateProvider.notifier)
                        .markAsRead(notification.id);
                    _handleNotificationTap(context, notification);
                  },
                  onDismiss: () {
                    ref
                        .read(odoriNotificationStateProvider.notifier)
                        .deleteNotification(notification.id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn sẽ nhận thông báo về đơn hàng,\ngiao hàng và thanh toán tại đây',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, OdoriNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case OdoriNotificationType.orderCreated:
      case OdoriNotificationType.orderApproved:
      case OdoriNotificationType.orderCancelled:
        if (notification.entityId != null) {
          // Navigate to order detail
          // Navigator.push(context, MaterialPageRoute(...));
        }
        break;
      case OdoriNotificationType.deliveryStarted:
      case OdoriNotificationType.deliveryCompleted:
      case OdoriNotificationType.deliveryFailed:
        if (notification.entityId != null) {
          // Navigate to delivery tracking
        }
        break;
      case OdoriNotificationType.paymentReceived:
      case OdoriNotificationType.overduePayment:
        // Navigate to receivables
        break;
      case OdoriNotificationType.lowStock:
        // Navigate to inventory
        break;
      default:
        break;
    }
  }
}

/// Individual Notification Tile
class NotificationTile extends StatelessWidget {
  final OdoriNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(notification.colorValue);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        tileColor: notification.isRead ? null : Colors.blue.withOpacity(0.05),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIcon(notification.type),
            color: color,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimeAgo(notification.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  IconData _getIcon(OdoriNotificationType type) {
    switch (type) {
      case OdoriNotificationType.orderCreated:
        return Icons.shopping_cart;
      case OdoriNotificationType.orderApproved:
        return Icons.check_circle;
      case OdoriNotificationType.orderCancelled:
        return Icons.cancel;
      case OdoriNotificationType.deliveryStarted:
        return Icons.local_shipping;
      case OdoriNotificationType.deliveryCompleted:
        return Icons.done_all;
      case OdoriNotificationType.deliveryFailed:
        return Icons.error;
      case OdoriNotificationType.paymentReceived:
        return Icons.payments;
      case OdoriNotificationType.lowStock:
        return Icons.inventory_2;
      case OdoriNotificationType.overduePayment:
        return Icons.warning;
      case OdoriNotificationType.systemAlert:
        return Icons.info;
    }
  }
}

/// Notification Popup Sheet
class NotificationPopupSheet extends ConsumerWidget {
  const NotificationPopupSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(odoriNotificationStateProvider);
    final recentNotifications = state.notifications.take(5).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.unreadCount > 0)
                  Badge(
                    label: Text(state.unreadCount.toString()),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Notifications list
          if (recentNotifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Không có thông báo mới',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentNotifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = recentNotifications[index];
                return _buildCompactTile(context, ref, notification);
              },
            ),
          
          // Footer
          const Divider(height: 1),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterPage(),
                ),
              );
            },
            title: const Text(
              'Xem tất cả thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTile(
    BuildContext context,
    WidgetRef ref,
    OdoriNotification notification,
  ) {
    return ListTile(
      onTap: () {
        ref
            .read(odoriNotificationStateProvider.notifier)
            .markAsRead(notification.id);
        Navigator.pop(context);
      },
      leading: Icon(
        _getIcon(notification.type),
        color: Color(notification.colorValue),
        size: 20,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        notification.message,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatTimeAgo(notification.createdAt),
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
      dense: true,
    );
  }

  IconData _getIcon(OdoriNotificationType type) {
    switch (type) {
      case OdoriNotificationType.orderCreated:
        return Icons.shopping_cart;
      case OdoriNotificationType.orderApproved:
        return Icons.check_circle;
      case OdoriNotificationType.orderCancelled:
        return Icons.cancel;
      case OdoriNotificationType.deliveryStarted:
        return Icons.local_shipping;
      case OdoriNotificationType.deliveryCompleted:
        return Icons.done_all;
      case OdoriNotificationType.deliveryFailed:
        return Icons.error;
      case OdoriNotificationType.paymentReceived:
        return Icons.payments;
      case OdoriNotificationType.lowStock:
        return Icons.inventory_2;
      case OdoriNotificationType.overduePayment:
        return Icons.warning;
      case OdoriNotificationType.systemAlert:
        return Icons.info;
    }
  }
}

/// Show notification popup
void showNotificationPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (_) => const NotificationPopupSheet(),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}
