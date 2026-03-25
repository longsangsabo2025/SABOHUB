import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/management_task.dart';
import 'task_badges.dart';

// =============================================================================
// UNIFIED TASK CARD — Rich, information-dense card for CEO/Manager/Staff
// Shows: priority icon, title, description, status+priority+category badges,
// assignee, deadline with urgency, recurring, progress, checklist, actions
// =============================================================================

class UnifiedTaskCard extends StatelessWidget {
  final ManagementTask task;
  final VoidCallback? onTap;
  final ValueChanged<TaskStatus>? onStatusChange;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDeadlineTap; // inline quick-edit deadline (#3)
  final VoidCallback? onSendEmail; // Send email notification to assignee
  final bool showAssignee;
  final bool showCreator;
  final bool showProgress;
  final bool showCompany;

  const UnifiedTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChange,
    this.onEdit,
    this.onDelete,
    this.onDeadlineTap,
    this.onSendEmail,
    this.showAssignee = true,
    this.showCreator = false,
    this.showProgress = true,
    this.showCompany = false,
  });

  bool get _isOverdue =>
      task.dueDate != null &&
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.cancelled &&
      task.dueDate!.isBefore(DateTime.now());

  bool get _isDueSoon =>
      task.dueDate != null &&
      !_isOverdue &&
      task.status != TaskStatus.completed &&
      task.status != TaskStatus.cancelled &&
      task.dueDate!.difference(DateTime.now()).inHours <= 48;

  int get _daysUntilDue =>
      task.dueDate?.difference(DateTime.now()).inDays ?? 0;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = _isOverdue && task.status != TaskStatus.overdue
        ? TaskStatus.overdue
        : task.status;
    final pColor = priorityColor(task.priority);

    // Border color: overdue → red, urgent priority or due soon → orange
    Color borderColor = AppColors.border;
    if (_isOverdue) {
      borderColor = AppColors.error;
    } else if (task.priority == TaskPriority.critical || _isDueSoon) {
      borderColor = AppColors.warning;
    } else if (task.priority == TaskPriority.high) {
      borderColor = Color(0xFFFB923C);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: _isOverdue ? 2 : 1.5),
      ),
      elevation: 1,
      shadowColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── ROW 1: Priority icon + Title + Badges + Menu ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority icon box
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      priorityIcon(task.priority),
                      color: pColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title + Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2,
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.neutral400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.neutral500,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  AppSpacing.hGapXS,

                  // Priority badge
                  PriorityBadge(task.priority),

                  AppSpacing.hGapXXS,

                  // Status badge — tappable for quick status change
                  _buildTappableStatusBadge(effectiveStatus),

                  // Menu button
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(width: 2),
                    _buildMenuButton(),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // ─── ROW 2: Assignee/Creator + Deadline + Recurring ───
              Row(
                children: [
                  // Assignee or Creator
                  if (showAssignee)
                    Expanded(
                      flex: 2,
                      child: _buildPersonChip(
                        task.assignedToName,
                        isAssigned: true,
                      ),
                    )
                  else if (showCreator)
                    Expanded(
                      flex: 2,
                      child: _buildPersonChip(
                        task.createdByName,
                        isAssigned: false,
                      ),
                    )
                  else
                    const Spacer(flex: 2),

                  AppSpacing.hGapSM,

                  // Deadline — tap for inline quick-edit (#3)
                  Expanded(
                    flex: 3,
                    child: onDeadlineTap != null
                        ? GestureDetector(
                            onTap: onDeadlineTap,
                            child: _buildDeadlineChip(),
                          )
                        : _buildDeadlineChip(),
                  ),

                  // Category badge (if not general)
                  if (task.category != TaskCategory.general) ...[
                    AppSpacing.hGapXS,
                    _buildCompactBadge(
                      task.category.displayName,
                      AppColors.primary,
                    ),
                  ],

                  // Recurring badge
                  if (task.isRecurring) ...[
                    AppSpacing.hGapXS,
                    _buildCompactBadge(
                      '🔁',
                      AppColors.paymentRefunded,
                    ),
                  ],

                  // Company badge
                  if (showCompany && task.companyName != null) ...[
                    AppSpacing.hGapXS,
                    _buildCompactBadge(
                      task.companyName!,
                      AppColors.info,
                      icon: Icons.business_rounded,
                    ),
                  ],

                  // Comment count badge (GitHub Issues pattern)
                  if (task.commentCount > 0) ...[
                    AppSpacing.hGapXS,
                    _buildCompactBadge(
                      '${task.commentCount}',
                      AppColors.neutral500,
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                  ],
                ],
              ),

              // ─── ROW 3: Progress bar ───
              if (showProgress && task.progress > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TaskProgressBar(task.progress, height: 5)),
                    AppSpacing.hGapSM,
                    Text(
                      '${task.progress}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],

              // ─── ROW 4: Checklist summary ───
              if (task.checklist.isNotEmpty) ...[
                AppSpacing.gapSM,
                _buildChecklistSummary(),
              ],


            ],
          ),
        ),
      ),
    );
  }

  // ─────────── Tappable Status Badge ───────────

  Widget _buildTappableStatusBadge(TaskStatus effectiveStatus) {
    // No quick-change when completed or cancelled, or no callback
    if (onStatusChange == null ||
        effectiveStatus == TaskStatus.completed ||
        effectiveStatus == TaskStatus.cancelled) {
      return StatusBadge(effectiveStatus);
    }

    final color = statusColor(effectiveStatus);
    final options = _nextStatuses(effectiveStatus);

    return PopupMenuButton<TaskStatus>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: 'Đổi trạng thái',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (s) => onStatusChange!(s),
      itemBuilder: (_) => options.map((s) => PopupMenuItem(
        value: s,
        height: 38,
        child: Row(children: [
          Icon(statusIcon(s), size: 15, color: statusColor(s)),
          AppSpacing.hGapSM,
          Text(s.label, style: const TextStyle(fontSize: 13)),
        ]),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon(effectiveStatus), size: 12, color: color),
            AppSpacing.hGapXXS,
            Text(
              effectiveStatus.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 13, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  List<TaskStatus> _nextStatuses(TaskStatus current) => switch (current) {
    TaskStatus.pending    => [TaskStatus.inProgress, TaskStatus.completed, TaskStatus.cancelled],
    TaskStatus.inProgress => [TaskStatus.completed, TaskStatus.pending, TaskStatus.cancelled],
    TaskStatus.overdue    => [TaskStatus.inProgress, TaskStatus.completed, TaskStatus.cancelled],
    _                     => [],
  };

  // ─────────── Person chip (Assignee / Creator) ───────────

  Widget _buildPersonChip(String? name, {required bool isAssigned}) {
    if (name != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isAssigned
              ? AppColors.infoLight
              : AppColors.successLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAssigned
                ? AppColors.info.withValues(alpha: 0.3)
                : AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAssigned ? Icons.person_rounded : Icons.edit_note_rounded,
              size: 13,
              color: isAssigned
                  ? AppColors.infoDark
                  : AppColors.successDark,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAssigned
                      ? AppColors.infoDark
                      : AppColors.successDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 13,
              color: AppColors.grey500),
          const SizedBox(width: 5),
          Text(
            isAssigned ? 'Chưa phân công' : 'N/A',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Deadline chip ───────────

  Widget _buildDeadlineChip() {
    final fmt = DateFormat('dd/MM/yyyy');

    if (task.dueDate == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: 13, color: AppColors.grey500),
            const SizedBox(width: 5),
            Text('Chưa có deadline',
                style: TextStyle(fontSize: 12, color: AppColors.grey500)),
          ],
        ),
      );
    }

    final Color bgColor;
    final Color borderClr;
    final Color textColor;
    final Color iconColor;
    final IconData icon;
    final String label;

    if (_isOverdue) {
      bgColor = AppColors.errorLight;
      borderClr = Color(0xFFFCA5A5);
      textColor = Color(0xFF991B1B);
      iconColor = AppColors.errorDark;
      icon = Icons.warning_rounded;
      label = 'QUÁ HẠN ${-_daysUntilDue}d';
    } else if (_isDueSoon) {
      bgColor = AppColors.warningLight;
      borderClr = Color(0xFFFDE68A);
      textColor = Color(0xFF92400E);
      iconColor = AppColors.warningDark;
      icon = Icons.access_time_rounded;
      label = 'GẤP ${_daysUntilDue}d · ${fmt.format(task.dueDate!)}';
    } else {
      bgColor = AppColors.successLight;
      borderClr = Color(0xFFBBF7D0);
      textColor = Color(0xFF166534);
      iconColor = Color(0xFF16A34A);
      icon = Icons.event_available_rounded;
      // Relative deadline (Linear pattern)
      final diffDays = _daysUntilDue;
      label = diffDays == 0
          ? 'Hôm nay'
          : diffDays == 1
              ? 'Ngày mai'
              : diffDays <= 6
                  ? '$diffDays ngày nữa'
                  : DateFormat('dd/MM').format(task.dueDate!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderClr, width: _isOverdue ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    _isOverdue || _isDueSoon ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Compact badge ───────────

  Widget _buildCompactBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Checklist summary ───────────

  Widget _buildChecklistSummary() {
    final done = task.checklist.where((c) => c.isDone).length;
    final total = task.checklist.length;
    final allDone = done == total;
    final pct = total > 0 ? done / total : 0.0;

    return Row(
      children: [
        Icon(
          allDone ? Icons.check_box_rounded : Icons.checklist_rounded,
          size: 15,
          color: allDone ? AppColors.success : AppColors.neutral500,
        ),
        const SizedBox(width: 5),
        Text(
          '$done/$total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: allDone ? AppColors.success : AppColors.neutral500,
          ),
        ),
        AppSpacing.hGapSM,
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                allDone ? AppColors.success : AppColors.info,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────── Menu button ───────────

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 20,
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppColors.neutral400),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (ctx) => [
        if (onStatusChange != null) ...[
          if (task.status != TaskStatus.inProgress)
            PopupMenuItem(
              value: 'start',
              height: 36,
              child: const Row(
                children: [
                  Icon(Icons.play_arrow_rounded,
                      size: 16, color: AppColors.info),
                  AppSpacing.hGapSM,
                  Text('Bắt đầu', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (task.status != TaskStatus.completed)
            PopupMenuItem(
              value: 'complete',
              height: 36,
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: AppColors.success),
                  AppSpacing.hGapSM,
                  Text('Hoàn thành', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: AppColors.neutral500),
                AppSpacing.hGapSM,
                Text('Sửa', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (onSendEmail != null && task.assignedTo != null)
          PopupMenuItem(
            value: 'send_email',
            height: 36,
            child: const Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: AppColors.paymentRefunded),
                AppSpacing.hGapSM,
                Text('Gửi email', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: const Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
                AppSpacing.hGapSM,
                Text('Xóa',
                    style: TextStyle(fontSize: 13, color: AppColors.error)),
              ],
            ),
          ),
      ],
      onSelected: (action) {
        switch (action) {
          case 'start':
            onStatusChange?.call(TaskStatus.inProgress);
          case 'complete':
            onStatusChange?.call(TaskStatus.completed);
          case 'edit':
            onEdit?.call();
          case 'send_email':
            onSendEmail?.call();
          case 'delete':
            onDelete?.call();
        }
      },
    );
  }
}
