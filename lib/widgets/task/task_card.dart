import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    Color borderColor = const Color(0xFFE5E7EB);
    if (_isOverdue) {
      borderColor = const Color(0xFFEF4444);
    } else if (task.priority == TaskPriority.critical || _isDueSoon) {
      borderColor = const Color(0xFFF59E0B);
    } else if (task.priority == TaskPriority.high) {
      borderColor = const Color(0xFFFB923C);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: _isOverdue ? 2 : 1.5),
      ),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                            color: const Color(0xFF1F2937),
                            height: 1.2,
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF9CA3AF),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.description != null &&
                            task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF6B7280),
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Priority badge
                  PriorityBadge(task.priority),

                  const SizedBox(width: 4),

                  // Status badge
                  StatusBadge(effectiveStatus),

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

                  const SizedBox(width: 8),

                  // Deadline
                  Expanded(
                    flex: 3,
                    child: _buildDeadlineChip(),
                  ),

                  // Category badge (if not general)
                  if (task.category != TaskCategory.general) ...[
                    const SizedBox(width: 6),
                    _buildCompactBadge(
                      task.category.displayName,
                      const Color(0xFF6366F1),
                    ),
                  ],

                  // Recurring badge
                  if (task.isRecurring) ...[
                    const SizedBox(width: 6),
                    _buildCompactBadge(
                      '🔁',
                      const Color(0xFF8B5CF6),
                    ),
                  ],

                  // Company badge
                  if (showCompany && task.companyName != null) ...[
                    const SizedBox(width: 6),
                    _buildCompactBadge(
                      task.companyName!,
                      const Color(0xFF0EA5E9),
                      icon: Icons.business_rounded,
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
                    const SizedBox(width: 8),
                    Text(
                      '${task.progress}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],

              // ─── ROW 4: Checklist summary ───
              if (task.checklist.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildChecklistSummary(),
              ],

              // ─── ROW 5: Inline action buttons (for non-completed tasks) ───
              if (onStatusChange != null &&
                  task.status != TaskStatus.completed &&
                  task.status != TaskStatus.cancelled) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (task.status == TaskStatus.pending)
                      _buildActionButton(
                        'Bắt đầu',
                        Icons.play_arrow_rounded,
                        const Color(0xFF3B82F6),
                        () => onStatusChange?.call(TaskStatus.inProgress),
                      ),
                    if (task.status == TaskStatus.inProgress ||
                        task.status == TaskStatus.overdue) ...[
                      _buildActionButton(
                        'Hoàn thành',
                        Icons.check_circle_rounded,
                        const Color(0xFF10B981),
                        () => onStatusChange?.call(TaskStatus.completed),
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        'Tạm dừng',
                        Icons.pause_rounded,
                        const Color(0xFFF59E0B),
                        () => onStatusChange?.call(TaskStatus.pending),
                      ),
                    ],
                    const Spacer(),
                    if (onEdit != null)
                      _buildActionButton(
                        'Sửa',
                        Icons.edit_rounded,
                        const Color(0xFF6B7280),
                        onEdit!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────── Person chip (Assignee / Creator) ───────────

  Widget _buildPersonChip(String? name, {required bool isAssigned}) {
    if (name != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isAssigned
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isAssigned
                ? const Color(0xFFBFDBFE)
                : const Color(0xFFBBF7D0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAssigned ? Icons.person_rounded : Icons.edit_note_rounded,
              size: 13,
              color: isAssigned
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF16A34A),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAssigned
                      ? const Color(0xFF1E40AF)
                      : const Color(0xFF15803D),
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 13,
              color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Text(
            isAssigned ? 'Chưa phân công' : 'N/A',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
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
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 5),
            Text('Chưa có deadline',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
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
      bgColor = const Color(0xFFFEF2F2);
      borderClr = const Color(0xFFFCA5A5);
      textColor = const Color(0xFF991B1B);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.warning_rounded;
      label = 'QUÁ HẠN ${-_daysUntilDue}d';
    } else if (_isDueSoon) {
      bgColor = const Color(0xFFFFFBEB);
      borderClr = const Color(0xFFFDE68A);
      textColor = const Color(0xFF92400E);
      iconColor = const Color(0xFFD97706);
      icon = Icons.access_time_rounded;
      label = 'GẤP ${_daysUntilDue}d · ${fmt.format(task.dueDate!)}';
    } else {
      bgColor = const Color(0xFFF0FDF4);
      borderClr = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF166534);
      iconColor = const Color(0xFF16A34A);
      icon = Icons.event_available_rounded;
      label = fmt.format(task.dueDate!);
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
          color: allDone ? const Color(0xFF10B981) : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 5),
        Text(
          '$done/$total',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: allDone ? const Color(0xFF10B981) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation(
                allDone ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────── Action buttons ───────────

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── Menu button ───────────

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: 20,
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: Color(0xFF9CA3AF)),
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
                      size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
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
                      size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
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
                Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text('Sửa', style: TextStyle(fontSize: 13)),
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
                    size: 16, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text('Xóa',
                    style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
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
          case 'delete':
            onDelete?.call();
        }
      },
    );
  }
}
