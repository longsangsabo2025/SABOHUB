import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/action_center_provider.dart';
import '../services/realtime_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Notification Bell Widget with Badge
/// Use this in AppBar to show notification icon with action item count
class RealtimeNotificationBell extends ConsumerWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;
  final bool showActionCount; // If true, shows tasks+approvals+notifications count

  const RealtimeNotificationBell({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24,
    this.showActionCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use action summary if showActionCount is true, otherwise just notifications
    final count = showActionCount
        ? ref.watch(actionSummaryProvider).when(
              data: (s) => s.totalCount + s.unreadNotifications,
              loading: () => ref.watch(unreadCountProvider),
              error: (_, __) => ref.watch(unreadCountProvider),
            )
        : ref.watch(unreadCountProvider);

    final hasUrgent = showActionCount
        ? ref.watch(actionSummaryProvider).when(
              data: (s) => s.hasUrgentItems,
              loading: () => false,
              error: (_, __) => false,
            )
        : false;

    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor ?? Theme.of(context).iconTheme.color,
            size: iconSize,
          ),
          onPressed: onTap ?? () => _showNotificationsSheet(context),
          tooltip: 'Thông báo & Công việc',
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: hasUrgent ? Colors.red : AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
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

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RealtimeNotificationsSheet(),
    );
  }
}

/// Full Notifications Sheet (Bottom Sheet)
class RealtimeNotificationsSheet extends ConsumerWidget {
  const RealtimeNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.watch(notificationActionsProvider);
    final summaryAsync = ref.watch(actionSummaryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: AppSpacing.paddingVMD,
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Action Summary Section
              summaryAsync.when(
                data: (summary) {
                  if (summary.totalCount == 0) return const SizedBox.shrink();
                  return _ActionSummaryBanner(
                    summary: summary,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/action-center');
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              // Header
              Padding(
                padding: AppSpacing.paddingHLG,
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
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => actions.markAllAsRead(),
                          child: const Text('Đọc tất cả'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/action-center');
                          },
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            AppSpacing.gapLG,
                            Text(
                              'Không có thông báo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: AppSpacing.paddingVSM,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return RealtimeNotificationTile(
                          notification: notification,
                          onTap: () {
                            actions.markAsRead(notification.id);
                            if (notification.actionUrl != null &&
                                notification.actionUrl!.isNotEmpty) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                context.go(notification.actionUrl!);
                              }
                            }
                          },
                          onDismiss: () {
                            actions.deleteNotification(notification.id);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        AppSpacing.gapLG,
                        Text('Lỗi: $error'),
                        AppSpacing.gapLG,
                        ElevatedButton(
                          onPressed: () => ref.invalidate(notificationsProvider),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Single Notification Tile
class RealtimeNotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const RealtimeNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.surface),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: notification.color.withValues(alpha: 0.1),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body != null) ...[
              Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              AppSpacing.gapXXS,
            ],
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}

/// Notification Toast/Popup Widget
/// Shows when new notification arrives
class RealtimeNotificationToast extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const RealtimeNotificationToast({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          padding: AppSpacing.paddingLG,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: notification.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: notification.color.withValues(alpha: 0.1),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              AppSpacing.hGapMD,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (notification.body != null) ...[
                      AppSpacing.gapXXS,
                      Text(
                        notification.body!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification Listener Widget
/// Wrap your main scaffold with this to show toast notifications
class RealtimeNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeNotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RealtimeNotificationListener> createState() => _RealtimeNotificationListenerState();
}

class _RealtimeNotificationListenerState extends ConsumerState<RealtimeNotificationListener> {
  OverlayEntry? _currentToast;

  @override
  void dispose() {
    _currentToast?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppNotification>>(newNotificationProvider, (previous, next) {
      next.whenData((notification) {
        _showNotificationToast(context, notification);
      });
    });

    return widget.child;
  }

  void _showNotificationToast(BuildContext context, AppNotification notification) {
    _currentToast?.remove();

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: RealtimeNotificationToast(
          notification: notification,
          onTap: () {
            _currentToast?.remove();
            _currentToast = null;
            if (notification.actionUrl != null &&
                notification.actionUrl!.isNotEmpty) {
              if (context.mounted) {
                context.go(notification.actionUrl!);
              }
            }
          },
          onDismiss: () {
            _currentToast?.remove();
            _currentToast = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentToast!);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      _currentToast?.remove();
      _currentToast = null;
    });
  }
}

/// Action Summary Banner shown in notification sheet
class _ActionSummaryBanner extends StatelessWidget {
  final ActionSummary summary;
  final VoidCallback? onTap;

  const _ActionSummaryBanner({
    required this.summary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.hasUrgentItems
              ? [Colors.red.shade400, Colors.orange.shade400]
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    summary.hasUrgentItems
                        ? Icons.warning_amber_rounded
                        : Icons.assignment_outlined,
                    color: Theme.of(context).colorScheme.surface,
                    size: 22,
                  ),
                ),
                AppSpacing.hGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.hasUrgentItems
                            ? '${summary.totalCount} việc cần xử lý ngay!'
                            : '${summary.totalCount} việc cần làm',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      AppSpacing.gapXXXS,
                      Text(
                        _summaryText(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.surface70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summaryText() {
    final parts = <String>[];
    if (summary.overdueTasks > 0) {
      parts.add('${summary.overdueTasks} quá hạn');
    }
    if (summary.pendingTasks > 0) {
      parts.add('${summary.pendingTasks} task');
    }
    if (summary.pendingApprovals > 0) {
      parts.add('${summary.pendingApprovals} phê duyệt');
    }
    return parts.isEmpty ? 'Nhấn để xem chi tiết' : parts.join(' • ');
  }
}
