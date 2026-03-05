import 'package:flutter/material.dart';
import '../../models/management_task.dart';
import '../../core/theme/app_colors.dart';

// =============================================================================
// UNIFIED TASK BADGES — ONE source of truth for all task visual indicators
// Replaces 6+ copies of priority/status badge widgets across the codebase
// =============================================================================

/// Priority colors mapping
Color priorityColor(TaskPriority p) => switch (p) {
  TaskPriority.critical => AppColors.error,
  TaskPriority.high     => AppColors.warning,
  TaskPriority.medium   => AppColors.info,
  TaskPriority.low      => AppColors.neutral500,
};

/// Priority icons
IconData priorityIcon(TaskPriority p) => switch (p) {
  TaskPriority.critical => Icons.local_fire_department_rounded,
  TaskPriority.high     => Icons.arrow_upward_rounded,
  TaskPriority.medium   => Icons.remove_rounded,
  TaskPriority.low      => Icons.arrow_downward_rounded,
};

/// Status colors mapping
Color statusColor(TaskStatus s) => switch (s) {
  TaskStatus.pending    => AppColors.neutral500,
  TaskStatus.inProgress => AppColors.info,
  TaskStatus.completed  => AppColors.success,
  TaskStatus.overdue    => AppColors.error,
  TaskStatus.cancelled  => AppColors.neutral400,
};

/// Status icons
IconData statusIcon(TaskStatus s) => switch (s) {
  TaskStatus.pending    => Icons.schedule_rounded,
  TaskStatus.inProgress => Icons.play_circle_outline_rounded,
  TaskStatus.completed  => Icons.check_circle_rounded,
  TaskStatus.overdue    => Icons.warning_amber_rounded,
  TaskStatus.cancelled  => Icons.cancel_outlined,
};

/// Compact priority badge — inline chip
class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool compact;
  
  const PriorityBadge(this.priority, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    if (compact) {
      return Icon(priorityIcon(priority), size: 16, color: color);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priorityIcon(priority), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact status badge — inline chip
class StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool compact;
  
  const StatusBadge(this.status, {super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    if (compact) {
      return Icon(statusIcon(status), size: 16, color: color);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar
class TaskProgressBar extends StatelessWidget {
  final int progress;
  final double height;
  
  const TaskProgressBar(this.progress, {super.key, this.height = 4});

  @override
  Widget build(BuildContext context) {
    final pct = progress.clamp(0, 100) / 100.0;
    final color = pct >= 1.0 ? AppColors.success 
        : pct >= 0.5 ? AppColors.info 
        : pct > 0 ? AppColors.warning 
        : Color(0xFFE5E7EB);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: height,
        backgroundColor: Color(0xFFE5E7EB),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
