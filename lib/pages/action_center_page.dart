import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/action_center_provider.dart';
import '../providers/notification_provider.dart';
import '../services/realtime_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Action Center Page - Shows all items needing user attention
class ActionCenterPage extends ConsumerWidget {
  const ActionCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trung tâm hành động'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Công việc'),
              Tab(text: 'Thông báo'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(actionItemsProvider);
                ref.invalidate(actionSummaryProvider);
                ref.invalidate(notificationsProvider);
              },
              tooltip: 'Làm mới',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: All action items
            _AllActionsTab(),
            // Tab 2: Tasks only
            _TasksTab(),
            // Tab 3: Notifications
            _NotificationsTab(),
          ],
        ),
      ),
    );
  }
}

class _AllActionsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(actionSummaryProvider);
    final itemsAsync = ref.watch(actionItemsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(actionItemsProvider);
        ref.invalidate(actionSummaryProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Summary header
          SliverToBoxAdapter(
            child: summaryAsync.when(
              data: (summary) => _ActionSummaryHeader(summary: summary),
              loading: () => const _ActionSummaryHeaderSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Action items list
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'Không có việc cần làm',
                    subtitle: 'Tuyệt vời! Bạn đã hoàn thành mọi thứ.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _ActionItemCard(item: item);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: _EmptyState(
                icon: Icons.error_outline,
                title: 'Đã xảy ra lỗi',
                subtitle: error.toString(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(actionItemsProvider);

    return itemsAsync.when(
      data: (items) {
        final taskItems = items.where((i) => i.type == 'task').toList();

        if (taskItems.isEmpty) {
          return _EmptyState(
            icon: Icons.task_alt,
            title: 'Không có công việc',
            subtitle: 'Chưa có công việc nào được giao cho bạn.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: taskItems.length,
          itemBuilder: (context, index) => _ActionItemCard(item: taskItems[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        icon: Icons.error_outline,
        title: 'Đã xảy ra lỗi',
        subtitle: error.toString(),
      ),
    );
  }
}

class _NotificationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final actions = ref.watch(notificationActionsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Không có thông báo',
            subtitle: 'Bạn chưa có thông báo nào.',
          );
        }

        return Column(
          children: [
            // Mark all as read button
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => actions.markAllAsRead(),
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Đọc tất cả'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: () {
                      actions.markAsRead(notification.id);
                      if (notification.actionUrl != null &&
                          notification.actionUrl!.isNotEmpty) {
                        context.go(notification.actionUrl!);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _EmptyState(
        icon: Icons.error_outline,
        title: 'Đã xảy ra lỗi',
        subtitle: error.toString(),
      ),
    );
  }
}

///
/// SUMMARY HEADER
///
class _ActionSummaryHeader extends StatelessWidget {
  final ActionSummary summary;

  const _ActionSummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.hasUrgentItems
              ? [AppColors.error, AppColors.warning]
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (summary.hasUrgentItems ? AppColors.error : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                summary.hasUrgentItems
                    ? Icons.warning_amber_rounded
                    : Icons.assignment_outlined,
                color: AppColors.textOnPrimary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.hasUrgentItems
                          ? 'Có ${summary.totalCount} việc cần xử lý ngay!'
                          : summary.totalCount > 0
                              ? '${summary.totalCount} việc cần làm'
                              : 'Không có việc cần làm',
                      style: AppTextStyles.title.copyWith(color: AppColors.textOnPrimary),
                    ),
                    if (summary.overdueTasks > 0)
                      Text(
                        '${summary.overdueTasks} công việc đã quá hạn',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textOnPrimary.withValues(alpha: 0.9)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.task_alt,
                label: 'Công việc',
                count: summary.pendingTasks,
                hasUrgent: summary.overdueTasks > 0,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.approval,
                label: 'Phê duyệt',
                count: summary.pendingApprovals,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.notifications,
                label: 'Thông báo',
                count: summary.unreadNotifications,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool hasUrgent;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    this.hasUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textOnPrimary, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$count',
                style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSummaryHeaderSkeleton extends StatelessWidget {
  const _ActionSummaryHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

///
/// ACTION ITEM CARD
///
class _ActionItemCard extends StatelessWidget {
  final ActionItem item;

  const _ActionItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isUrgent
            ? BorderSide(color: item.color.withValues(alpha: 0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (item.actionUrl != null) {
            context.go(item.actionUrl!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isUrgent) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'KHẨN',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: item.isUrgent
                              ? item.color
                              : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(item.dueDate!),
                            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay ${DateFormat.Hm('vi').format(date)}';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Ngày mai ${DateFormat.Hm('vi').format(date)}';
    } else if (dateOnly.isBefore(today)) {
      return 'Quá hạn ${DateFormat('dd/MM').format(date)}';
    } else {
      return DateFormat('dd/MM HH:mm').format(date);
    }
  }
}

///
/// NOTIFICATION TILE
///
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null)
            Text(
              notification.body!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          Text(
            _timeAgo(notification.createdAt),
            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

///
/// EMPTY STATE
///
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.title.copyWith(color: AppColors.grey700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

///
/// Compact Action Summary Widget (for dashboards)
///
class ActionSummaryWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const ActionSummaryWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(actionSummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary.totalCount == 0) return const SizedBox.shrink();

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap ?? () => context.go('/action-center'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: summary.hasUrgentItems
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      summary.hasUrgentItems
                          ? Icons.warning_amber_rounded
                          : Icons.assignment_outlined,
                      color: summary.hasUrgentItems
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.totalCount} việc cần làm',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summaryText(summary),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _summaryText(ActionSummary summary) {
    final parts = <String>[];
    if (summary.overdueTasks > 0) {
      parts.add('${summary.overdueTasks} quá hạn');
    }
    if (summary.pendingTasks > 0) {
      parts.add('${summary.pendingTasks} công việc');
    }
    if (summary.pendingApprovals > 0) {
      parts.add('${summary.pendingApprovals} phê duyệt');
    }
    return parts.isEmpty ? 'Không có việc cấp bách' : parts.join(' • ');
  }
}
