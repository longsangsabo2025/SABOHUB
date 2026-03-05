import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/task_board_filter_provider.dart';
import '../../services/email_notification_service.dart';
// managementTaskServiceProvider comes from management_task_provider re-exports
import '../../core/theme/app_spacing.dart';
import '../../pages/ceo/task_detail_page.dart';
import 'task_card.dart';
import 'task_badges.dart';
import 'task_create_dialog.dart';

// =============================================================================
// TASK BOARD — THE ONE reusable task management widget
// Used by: CEO, Manager, Staff, ShiftLeader, Company view
// No tabs, no bloat. Search + Filter + List + Create. That's it.
// =============================================================================

/// What tasks to show
enum TaskBoardMode {
  /// Tasks created by CEO
  ceoCreated,
  /// Tasks created by Manager (assigned to staff)
  managerCreated,
  /// Tasks assigned to me (Manager/Staff view)
  assigned,
  /// All tasks for a company
  company,
}

/// Role-based capabilities
class TaskBoardConfig {
  final TaskBoardMode mode;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canChangeStatus;
  final bool canSendEmail; // Allow sending email notifications
  final bool showAssignee;
  final bool showCreator;
  final bool showProgress;
  final bool showCompany;
  final bool showStats;
  final String? companyId;
  final String? branchId;
  /// Assignee list for create/edit dialog (empty = no assign dropdown)
  final Future<List<Map<String, dynamic>>> Function()? loadAssignees;
  /// Company list for create dialog (null = no company dropdown)
  final Future<List<Map<String, dynamic>>> Function()? loadCompanies;
  /// Media channels for create dialog (null = no channel picker)
  final Future<List<Map<String, dynamic>>> Function()? loadMediaChannels;

  const TaskBoardConfig({
    required this.mode,
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canChangeStatus = true,
    this.canSendEmail = false,
    this.showAssignee = true,
    this.showCreator = false,
    this.showProgress = true,
    this.showCompany = false,
    this.showStats = true,
    this.companyId,
    this.branchId,
    this.loadAssignees,
    this.loadCompanies,
    this.loadMediaChannels,
  });

  /// CEO: full control
  factory TaskBoardConfig.ceo({
    required Future<List<Map<String, dynamic>>> Function() loadAssignees,
    required Future<List<Map<String, dynamic>>> Function() loadCompanies,
    Future<List<Map<String, dynamic>>> Function()? loadMediaChannels,
  }) =>
      TaskBoardConfig(
        mode: TaskBoardMode.ceoCreated,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canChangeStatus: true,
        canSendEmail: true,
        showAssignee: true,
        showCreator: false,
        showProgress: true,
        showCompany: true,
        showStats: true,
        loadAssignees: loadAssignees,
        loadCompanies: loadCompanies,
        loadMediaChannels: loadMediaChannels,
      );

  /// Manager: see assigned + created, can create & assign to staff
  factory TaskBoardConfig.managerAssigned({
    Future<List<Map<String, dynamic>>> Function()? loadAssignees,
  }) =>
      TaskBoardConfig(
        mode: TaskBoardMode.assigned,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canChangeStatus: true,
        showAssignee: false,
        showCreator: true,
        showProgress: true,
        showCompany: false,
        showStats: true,
        loadAssignees: loadAssignees,
      );

  factory TaskBoardConfig.managerCreated({
    required Future<List<Map<String, dynamic>>> Function() loadAssignees,
  }) =>
      TaskBoardConfig(
        mode: TaskBoardMode.managerCreated,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canChangeStatus: true,
        canSendEmail: true,
        showAssignee: true,
        showCreator: false,
        showProgress: true,
        showCompany: false,
        showStats: true,
        loadAssignees: loadAssignees,
      );

  /// Staff: see assigned tasks, can update status
  factory TaskBoardConfig.staff() => const TaskBoardConfig(
        mode: TaskBoardMode.assigned,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canChangeStatus: true,
        showAssignee: false,
        showCreator: true,
        showProgress: true,
        showCompany: false,
        showStats: true,
      );

  /// Company view: see all company tasks
  factory TaskBoardConfig.companyView({required String companyId}) =>
      TaskBoardConfig(
        mode: TaskBoardMode.company,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canChangeStatus: false,
        showAssignee: true,
        showCreator: true,
        showProgress: true,
        showCompany: false,
        showStats: true,
        companyId: companyId,
      );
}

class TaskBoard extends ConsumerStatefulWidget {
  final TaskBoardConfig config;

  const TaskBoard({super.key, required this.config});

  @override
  ConsumerState<TaskBoard> createState() => _TaskBoardState();
}

// Date filter UI extensions (Todoist-style)
extension TaskDateFilterX on TaskDateFilter {
  String get label => switch (this) {
    TaskDateFilter.today    => 'Hôm nay',
    TaskDateFilter.thisWeek => 'Tuần này',
    TaskDateFilter.overdue  => 'Quá hạn',
  };
  IconData get icon => switch (this) {
    TaskDateFilter.today    => Icons.wb_sunny_rounded,
    TaskDateFilter.thisWeek => Icons.date_range_rounded,
    TaskDateFilter.overdue  => Icons.warning_amber_rounded,
  };
  Color get color => switch (this) {
    TaskDateFilter.today    => AppColors.info,
    TaskDateFilter.thisWeek => AppColors.primary,
    TaskDateFilter.overdue  => AppColors.error,
  };
}

// Sort options UI extensions for CEO / Manager speed
extension TaskSortByX on TaskSortBy {
  String get label => switch (this) {
    TaskSortBy.smartAuto    => 'Thông minh (tự động)',
    TaskSortBy.deadlineAsc  => 'Deadline gần nhất',
    TaskSortBy.priorityDesc => 'Ưu tiên cao nhất',
    TaskSortBy.statusGroup  => 'Trạng thái',
    TaskSortBy.createdDesc  => 'Mới nhất',
  };
  IconData get icon => switch (this) {
    TaskSortBy.smartAuto    => Icons.auto_awesome_rounded,
    TaskSortBy.deadlineAsc  => Icons.calendar_today_rounded,
    TaskSortBy.priorityDesc => Icons.priority_high_rounded,
    TaskSortBy.statusGroup  => Icons.sort_rounded,
    TaskSortBy.createdDesc  => Icons.history_rounded,
  };
}

class _TaskBoardState extends ConsumerState<TaskBoard> {
  // #1 Quick-create inline (Linear pattern) — local UI state
  bool _showQuickCreate = false;
  final TextEditingController _quickTitleCtrl = TextEditingController();
  TaskPriority _quickPriority = TaskPriority.medium;
  bool _quickCreating = false;

  TaskBoardConfig get cfg => widget.config;

  @override
  void dispose() {
    _quickTitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pick the right provider based on mode
    final tasksAsync = _getTasksAsync();
    final filterState = ref.watch(taskBoardFilterProvider);

    return tasksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
              AppSpacing.gapMD,
              Text('Lỗi: $e', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
              AppSpacing.gapMD,
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
      data: (tasks) {
        final filtered = _applyFilters(tasks);
        final overdueCount = tasks.where((t) =>
          t.dueDate != null &&
          t.status != TaskStatus.completed &&
          t.status != TaskStatus.cancelled &&
          t.dueDate!.isBefore(DateTime.now())).length;
        return Stack(
          children: [
            Column(
              children: [
                // Overdue alert banner (Linear pattern)
                if (overdueCount > 0 && filterState.dateFilter != TaskDateFilter.overdue)
                  _buildOverdueBanner(overdueCount),
                // Stats row
                if (cfg.showStats) _buildStatsRow(tasks),
                // Date filter chips (Todoist pattern)
                _buildDateFilterRow(tasks),
                // Filter bar
                _buildFilterBar(tasks),
                // Quick-create bar (#1 - Linear pattern)
                if (cfg.canCreate) _buildQuickCreateBar(),
                // Task list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () async => _refresh(),
                            child: filterState.grouped
                                ? _buildGroupedList(filtered)
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => AppSpacing.gapXS,
                                    itemBuilder: (ctx, i) =>
                                        _buildTaskItem(filtered[i]),
                                  ),
                        ),
                ),
              ],
            ),
            // Bulk action bar (#2 - Notion pattern)
            if (filterState.isSelectMode) _buildBulkActionBar(),
            // FAB (hidden during bulk select)
            if (cfg.canCreate && !filterState.isSelectMode)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'task_board_fab_${cfg.mode.name}',
                  onPressed: _showCreateDialog,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  AsyncValue<List<ManagementTask>> _getTasksAsync() {
    switch (cfg.mode) {
      case TaskBoardMode.ceoCreated:
        return ref.watch(ceoStrategicTasksProvider);
      case TaskBoardMode.managerCreated:
        return ref.watch(managerCreatedTasksProvider);
      case TaskBoardMode.assigned:
        return ref.watch(managerAssignedTasksProvider);
      case TaskBoardMode.company:
        return ref.watch(_companyTasksManagementProvider(cfg.companyId!));
    }
  }

  List<ManagementTask> _applyFilters(List<ManagementTask> tasks) {
    final f = ref.read(taskBoardFilterProvider);
    var result = tasks.toList();

    // Search
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      result = result.where((t) =>
          t.title.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false) ||
          (t.assignedToName?.toLowerCase().contains(q) ?? false) ||
          (t.createdByName?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Status filter
    if (f.statusFilter != null) {
      result = result.where((t) => t.status == f.statusFilter).toList();
    }

    // Priority filter
    if (f.priorityFilter != null) {
      result = result.where((t) => t.priority == f.priorityFilter).toList();
    }

    // Date filter (Todoist-style)
    if (f.dateFilter != null) {
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final weekEnd = now.add(const Duration(days: 7));
      result = result.where((t) => switch (f.dateFilter!) {
        TaskDateFilter.today    => t.dueDate != null &&
            !t.dueDate!.isAfter(todayEnd) &&
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled,
        TaskDateFilter.thisWeek => t.dueDate != null &&
            !t.dueDate!.isAfter(weekEnd) &&
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled,
        TaskDateFilter.overdue  => t.dueDate != null &&
            t.dueDate!.isBefore(now) &&
            t.status != TaskStatus.completed &&
            t.status != TaskStatus.cancelled,
      }).toList();
    }

    // Sort
    switch (f.sortBy) {
      case TaskSortBy.smartAuto:
        final tsNow = DateTime.now();
        final tsTodayEnd =
            DateTime(tsNow.year, tsNow.month, tsNow.day, 23, 59, 59);
        final tsWeekEnd = tsNow.add(const Duration(days: 7));
        int smartScore(ManagementTask t) {
          if (t.status == TaskStatus.completed ||
              t.status == TaskStatus.cancelled) {
            return 100;
          }
          final ovd = t.dueDate != null && t.dueDate!.isBefore(tsNow);
          if (ovd) return 0;
          if (t.priority == TaskPriority.critical &&
              t.dueDate != null &&
              !t.dueDate!.isAfter(tsTodayEnd)) {
            return 1;
          }
          if (t.priority == TaskPriority.high &&
              t.dueDate != null &&
              !t.dueDate!.isAfter(tsWeekEnd)) {
            return 2;
          }
          if (t.status == TaskStatus.inProgress) return 3;
          if (t.priority == TaskPriority.critical) return 4;
          if (t.priority == TaskPriority.high) return 5;
          return 6;
        }
        result.sort((a, b) {
          final sc = smartScore(a).compareTo(smartScore(b));
          if (sc != 0) return sc;
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSortBy.deadlineAsc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSortBy.priorityDesc:
        result.sort((a, b) => _priorityOrder(b.priority).compareTo(_priorityOrder(a.priority)));
      case TaskSortBy.statusGroup:
        result.sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));
      case TaskSortBy.createdDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  int _priorityOrder(TaskPriority p) => switch (p) {
    TaskPriority.critical => 4,
    TaskPriority.high     => 3,
    TaskPriority.medium   => 2,
    TaskPriority.low      => 1,
  };

  int _statusOrder(TaskStatus s) => switch (s) {
    TaskStatus.overdue    => 0,
    TaskStatus.inProgress => 1,
    TaskStatus.pending    => 2,
    TaskStatus.completed  => 3,
    TaskStatus.cancelled  => 4,
  };

  // ==================== STATS ROW ====================

  Widget _buildStatsRow(List<ManagementTask> tasks) {
    final total = tasks.length;
    final pending = tasks.where((t) => t.status == TaskStatus.pending).length;
    final inProg = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    final overdue = tasks.where((t) =>
        t.dueDate != null &&
        t.status != TaskStatus.completed &&
        t.status != TaskStatus.cancelled &&
        t.dueDate!.isBefore(DateTime.now())).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _statChip('Tổng', total, AppColors.neutral500, null),
          _statChip('Chờ', pending, AppColors.warning, TaskStatus.pending),
          _statChip('Đang', inProg, AppColors.info, TaskStatus.inProgress),
          _statChip('Xong', done, AppColors.success, TaskStatus.completed),
          // Always show Trễ — CEO needs to know 0 overdue is healthy
          _statChip('Trễ', overdue, AppColors.error, TaskStatus.overdue),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color, TaskStatus? filter) {
    final filterState = ref.watch(taskBoardFilterProvider);
    final isActive = filterState.statusFilter == filter && filter != null;
    return Expanded(
      child: GestureDetector(
        onTap: filter == null
            ? () => ref.read(taskBoardFilterProvider.notifier).setStatusFilter(null)
            : () => ref.read(taskBoardFilterProvider.notifier).toggleStatusFilter(filter),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== FILTER BAR ====================

  Widget _buildFilterBar(List<ManagementTask> tasks) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.neutral400),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.neutral400),
                  suffixIcon: ref.watch(taskBoardFilterProvider).search.isNotEmpty
                      ? GestureDetector(
                          onTap: () => ref.read(taskBoardFilterProvider.notifier).setSearch(''),
                          child: const Icon(Icons.clear_rounded,
                              size: 16, color: AppColors.neutral400),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => ref.read(taskBoardFilterProvider.notifier).setSearch(v),
              ),
            ),
          ),
          AppSpacing.hGapSM,
          // Priority filter
          _buildPriorityFilterButton(),
          AppSpacing.hGapXXS,
          // Sort button
          _buildSortButton(),
          // Refresh
          AppSpacing.hGapXXS,
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18),
              onPressed: _refresh,
              padding: EdgeInsets.zero,
              tooltip: 'Tải lại',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          AppSpacing.hGapXXS,
          _buildGroupToggle(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    final sortBy = ref.watch(taskBoardFilterProvider).sortBy;
    const activeColor = AppColors.primary;
    return PopupMenuButton<TaskSortBy>(
      onSelected: (v) => ref.read(taskBoardFilterProvider.notifier).setSortBy(v),
      tooltip: 'Sắp xếp',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: activeColor.withValues(alpha: 0.3)),
        ),
        child: const Icon(Icons.sort_rounded, size: 18, color: activeColor),
      ),
      itemBuilder: (_) => TaskSortBy.values.map((s) => PopupMenuItem(
        value: s,
        height: 38,
        child: Row(
          children: [
            Icon(s.icon, size: 15,
                color: sortBy == s ? activeColor : AppColors.neutral500),
            const SizedBox(width: 10),
            Text(
              s.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: sortBy == s ? FontWeight.w700 : FontWeight.w400,
                color: sortBy == s ? activeColor : AppColors.textPrimary,
              ),
            ),
            if (sortBy == s) ...[const Spacer(), const Icon(Icons.check_rounded, size: 14, color: activeColor)],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildPriorityFilterButton() {
    final priorityFilter = ref.watch(taskBoardFilterProvider).priorityFilter;
    final hasFilter = priorityFilter != null;
    return PopupMenuButton<TaskPriority?>(
      onSelected: (v) => ref.read(taskBoardFilterProvider.notifier).setPriorityFilter(v),
      tooltip: 'Lọc ưu tiên',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: hasFilter 
              ? priorityColor(priorityFilter).withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFilter 
                ? priorityColor(priorityFilter) 
              : AppColors.grey200,
          ),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: hasFilter 
              ? priorityColor(priorityFilter) 
              : AppColors.neutral500,
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: null,
          height: 36,
          child: Text('Tất cả', style: TextStyle(fontSize: 13)),
        ),
        ...TaskPriority.values.map((p) => PopupMenuItem(
              value: p,
              height: 36,
              child: Row(
                children: [
                  Icon(priorityIcon(p), size: 14, color: priorityColor(p)),
                  AppSpacing.hGapSM,
                  Text(p.label, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  // ==================== TASK ITEMS ====================

  Widget _buildTaskItem(ManagementTask task) {
    final filterState = ref.watch(taskBoardFilterProvider);
    final isSelected = filterState.selectedIds.contains(task.id);
    final card = UnifiedTaskCard(
      task: task,
      showAssignee: cfg.showAssignee,
      showCreator: cfg.showCreator,
      showProgress: cfg.showProgress,
      showCompany: cfg.showCompany,
      onTap: filterState.isSelectMode
          ? () => ref.read(taskBoardFilterProvider.notifier).toggleSelection(task.id)
          : () => _showTaskDetail(task),
      onStatusChange: cfg.canChangeStatus && !filterState.isSelectMode
          ? (status) => _updateTaskStatus(task, status)
          : null,
      onEdit: cfg.canEdit && !filterState.isSelectMode ? () => _showEditDialog(task) : null,
      onDelete:
          cfg.canDelete && !filterState.isSelectMode ? () => _confirmDelete(task) : null,
      onDeadlineTap: cfg.canEdit && !filterState.isSelectMode
          ? () => _showQuickDeadlinePicker(task)
          : null,
      onSendEmail: cfg.canSendEmail && !filterState.isSelectMode && task.assignedTo != null
          ? () => _sendEmailNotification(task)
          : null,
    );

    // Swipe disabled in select mode
    Widget item;
    if (!filterState.isSelectMode &&
        cfg.canChangeStatus &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled) {
      final nextStatus = task.status == TaskStatus.pending
          ? TaskStatus.inProgress
          : TaskStatus.completed;
      final swipeColor = nextStatus == TaskStatus.inProgress
          ? AppColors.info
          : AppColors.success;
      final swipeIcon = nextStatus == TaskStatus.inProgress
          ? Icons.play_arrow_rounded
          : Icons.check_circle_rounded;
      item = Dismissible(
        key: ValueKey('swipe_${task.id}'),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          _updateTaskStatus(task, nextStatus);
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: swipeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: swipeColor.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(swipeIcon, color: swipeColor, size: 22),
              AppSpacing.hGapSM,
              Text(
                nextStatus.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: swipeColor,
                ),
              ),
            ],
          ),
        ),
        child: card,
      );
    } else {
      item = card;
    }

    // Long-press to enter bulk select mode (#2)
    return Stack(
      children: [
        GestureDetector(
          onLongPress: (cfg.canEdit || cfg.canChangeStatus)
              ? () => ref.read(taskBoardFilterProvider.notifier).addSelection(task.id)
              : null,
          child: item,
        ),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmpty() {
    final hasFilters = ref.read(taskBoardFilterProvider).hasFilters;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.filter_alt_off_rounded : Icons.task_rounded,
              size: 48,
              color: AppColors.grey300,
            ),
            AppSpacing.gapMD,
            Text(
              hasFilters ? 'Không tìm thấy nhiệm vụ phù hợp' : 'Chưa có nhiệm vụ nào',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral500,
              ),
            ),
            if (hasFilters) ...[
              AppSpacing.gapSM,
              TextButton(
                onPressed: () => ref.read(taskBoardFilterProvider.notifier).clearFilters(),
                child: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 13)),
              ),
            ],
            if (!hasFilters && cfg.canCreate) ...[
              AppSpacing.gapSM,
              TextButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tạo nhiệm vụ đầu tiên', style: TextStyle(fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== OVERDUE BANNER ====================

  Widget _buildOverdueBanner(int count) {
    return GestureDetector(
      onTap: () => ref.read(taskBoardFilterProvider.notifier).setDateFilter(TaskDateFilter.overdue),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.errorDark),
            AppSpacing.hGapSM,
            Text(
              '$count nhiệm vụ quá hạn — Nhấn để xem',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.errorDark,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.errorDark),
          ],
        ),
      ),
    );
  }

  // ==================== DATE FILTER CHIPS (Todoist pattern) ====================

  Widget _buildDateFilterRow(List<ManagementTask> tasks) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekEnd = now.add(const Duration(days: 7));

    int countFor(TaskDateFilter f) => tasks.where((t) {
      if (t.status == TaskStatus.completed || t.status == TaskStatus.cancelled) return false;
      if (t.dueDate == null) return false;
      return switch (f) {
        TaskDateFilter.today    => !t.dueDate!.isAfter(todayEnd),
        TaskDateFilter.thisWeek => !t.dueDate!.isAfter(weekEnd),
        TaskDateFilter.overdue  => t.dueDate!.isBefore(now),
      };
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: TaskDateFilter.values.map((f) {
          final count = countFor(f);
          final dateFilter = ref.watch(taskBoardFilterProvider).dateFilter;
          final isActive = dateFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => ref.read(taskBoardFilterProvider.notifier).toggleDateFilter(f),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive ? f.color.withValues(alpha: 0.12) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? f.color : AppColors.border,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.icon, size: 13, color: isActive ? f.color : AppColors.neutral500),
                    AppSpacing.hGapXXS,
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? f.color : AppColors.neutral500,
                      ),
                    ),
                    if (count > 0) ...[
                      AppSpacing.hGapXXS,
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isActive ? f.color : AppColors.neutral400)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isActive ? f.color : AppColors.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== GROUPED VIEW (Plane pattern) ====================

  Widget _buildGroupToggle() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(
          ref.watch(taskBoardFilterProvider).grouped ? Icons.view_stream_rounded : Icons.table_rows_rounded,
          size: 18,
          color: ref.watch(taskBoardFilterProvider).grouped ? AppColors.primary : AppColors.neutral500,
        ),
        tooltip: ref.watch(taskBoardFilterProvider).grouped ? 'Danh sách phẳng' : 'Nhóm theo trạng thái',
        onPressed: () => ref.read(taskBoardFilterProvider.notifier).toggleGrouped(),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor:
              ref.watch(taskBoardFilterProvider).grouped ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: ref.watch(taskBoardFilterProvider).grouped ? AppColors.primary : AppColors.border,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<ManagementTask> tasks) {
    bool isOvd(ManagementTask t) =>
        t.dueDate != null &&
        t.status != TaskStatus.completed &&
        t.status != TaskStatus.cancelled &&
        t.dueDate!.isBefore(DateTime.now());

    final overdue = tasks.where(isOvd).toList();
    final inProgress =
        tasks.where((t) => t.status == TaskStatus.inProgress && !isOvd(t)).toList();
    final pending =
        tasks.where((t) => t.status == TaskStatus.pending && !isOvd(t)).toList();
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).toList();
    final cancelled =
        tasks.where((t) => t.status == TaskStatus.cancelled).toList();

    // Sort by deadline within each live group
    for (final g in [overdue, inProgress, pending]) {
      g.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      children: [
        if (overdue.isNotEmpty) ...[_buildGroupHeader(TaskStatus.overdue, overdue.length), ...overdue.map(_buildTaskItem), AppSpacing.gapSM],
        if (inProgress.isNotEmpty) ...[_buildGroupHeader(TaskStatus.inProgress, inProgress.length), ...inProgress.map(_buildTaskItem), AppSpacing.gapSM],
        if (pending.isNotEmpty) ...[_buildGroupHeader(TaskStatus.pending, pending.length), ...pending.map(_buildTaskItem), AppSpacing.gapSM],
        if (completed.isNotEmpty) ...[_buildGroupHeader(TaskStatus.completed, completed.length), ...completed.map(_buildTaskItem), AppSpacing.gapSM],
        if (cancelled.isNotEmpty) ...[_buildGroupHeader(TaskStatus.cancelled, cancelled.length), ...cancelled.map(_buildTaskItem)],
      ],
    );
  }

  Widget _buildGroupHeader(TaskStatus status, int count) {
    final color = statusColor(status);
    return Padding(
      padding: EdgeInsets.fromLTRB(2, 4, 2, 6),
      child: Row(
        children: [
          Icon(statusIcon(status), size: 14, color: color),
          AppSpacing.hGapXS,
          Text(
            status.label,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
          ),
          AppSpacing.hGapXS,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          AppSpacing.hGapSM,
          Expanded(
              child: Divider(color: color.withValues(alpha: 0.2), height: 16)),
        ],
      ),
    );
  }

  // ==================== QUICK-CREATE BAR (#1) ====================

  Widget _buildQuickCreateBar() {
    return AnimatedCrossFade(
      duration: Duration(milliseconds: 220),
      crossFadeState: _showQuickCreate
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _showQuickCreate = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: AppColors.primary),
                AppSpacing.hGapSM,
                Text(
                  'Tạo nhanh task...',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _quickTitleCtrl,
                autofocus: _showQuickCreate,
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề task...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                onSubmitted: (_) => _quickCreate(),
              ),
              AppSpacing.gapSM,
              Row(
                children: [
                  // Priority selector
                  ...TaskPriority.values.map((p) {
                    final active = _quickPriority == p;
                    return GestureDetector(
                      onTap: () => setState(() => _quickPriority = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? _priorityColor(p).withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: active
                                ? _priorityColor(p)
                                : AppColors.grey300,
                          ),
                        ),
                        child: Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: active ? _priorityColor(p) : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _showQuickCreate = false;
                      _quickTitleCtrl.clear();
                    }),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                    child: const Text('Hủy',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ),
                  AppSpacing.hGapXXS,
                  FilledButton(
                    onPressed: _quickCreating ? null : _quickCreate,
                    style: FilledButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        backgroundColor: AppColors.primary),
                    child: _quickCreating
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Tạo',
                            style:
                                TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.critical:
        return AppColors.error;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  Future<void> _quickCreate() async {
    final title = _quickTitleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _quickCreating = true);
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.createTask(
        title: title,
        priority: _quickPriority.value,
        assignedTo: '',
        companyId: cfg.companyId,
        branchId: cfg.branchId,
      );
      setState(() {
        _showQuickCreate = false;
        _quickTitleCtrl.clear();
        _quickPriority = TaskPriority.medium;
      });
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tạo task: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _quickCreating = false);
    }
  }

  // ==================== BULK ACTION BAR (#2) ====================

  Widget _buildBulkActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${ref.watch(taskBoardFilterProvider).selectedIds.length} đã chọn',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () =>
                        ref.read(taskBoardFilterProvider.notifier).clearSelection(),
                    tooltip: 'Bỏ chọn tất cả',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              AppSpacing.gapMD,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (cfg.canChangeStatus)
                    _bulkActionButton(
                      Icons.swap_horiz_rounded,
                      'Trạng thái',
                      onTap: _showBulkStatusPicker,
                    ),
                  if (cfg.canEdit)
                    _bulkActionButton(
                      Icons.flag_rounded,
                      'Ưu tiên',
                      onTap: _showBulkPriorityPicker,
                    ),
                  if (cfg.canDelete)
                    _bulkActionButton(
                      Icons.delete_outline_rounded,
                      'Xóa',
                      color: AppColors.error,
                      onTap: _bulkDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulkActionButton(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    Color color = AppColors.surface,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            AppSpacing.gapXXS,
            Text(label,
                style:
                    TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ==================== QUICK DEADLINE PICKER (#3) ====================

  void _showQuickDeadlinePicker(ManagementTask task) {
    final now = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapLG,
            const Text('Chỉnh hạn chót',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _deadlinePreset(ctx, task, 'Hôm nay', now),
                _deadlinePreset(
                    ctx,
                    task,
                    'Ngày mai',
                    now.add(const Duration(days: 1))),
                _deadlinePreset(
                    ctx,
                    task,
                    'Tuần này (+7)',
                    now.add(const Duration(days: 7))),
                _deadlinePreset(
                    ctx,
                    task,
                    '2 tuần',
                    now.add(const Duration(days: 14))),
                _deadlinePreset(
                    ctx,
                    task,
                    '1 tháng',
                    DateTime(now.year, now.month + 1, now.day)),
              ],
            ),
            AppSpacing.gapMD,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded,
                        size: 16),
                    label: const Text('Chọn ngày...'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            task.dueDate ?? DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 30)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365)),
                      );
                      if (picked != null && mounted) {
                        final service = ref.read(
                            managementTaskServiceProvider);
                        await service.updateTask(
                            taskId: task.id, dueDate: picked);
                        _refresh();
                      }
                    },
                  ),
                ),
                if (task.dueDate != null) ...[
                  AppSpacing.hGapSM,
                  OutlinedButton.icon(
                    icon: const Icon(Icons.clear_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text('Xóa hạn',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                        side:
                            const BorderSide(color: AppColors.error)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final service = ref.read(
                          managementTaskServiceProvider);
                      await service.updateTask(
                          taskId: task.id, clearDueDate: true);
                      _refresh();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deadlinePreset(
      BuildContext ctx, ManagementTask task, String label, DateTime date) {
    final fmt =
        DateFormat('dd/MM', 'vi_VN').format(date);
    return ActionChip(
      label: Text('$label ($fmt)'),
      onPressed: () async {
        Navigator.pop(ctx);
        final service = ref.read(managementTaskServiceProvider);
        await service.updateTask(taskId: task.id, dueDate: date);
        _refresh();
      },
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      labelStyle:
          TextStyle(color: AppColors.primary, fontSize: 12),
      side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }

  // ==================== BULK PICKERS ====================

  void _showBulkStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapLG,
            Text(
                'Đổi trạng thái cho ${ref.read(taskBoardFilterProvider).selectedIds.length} task',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            AppSpacing.gapMD,
            ...TaskStatus.values
                .where((s) =>
                    s != TaskStatus.cancelled)
                .map(
                  (s) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_statusIcon(s),
                        color: _statusColor(s), size: 20),
                    title: Text(s.label),
                    onTap: () {
                      Navigator.pop(ctx);
                      _bulkUpdateStatus(s);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showBulkPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapLG,
            Text(
                'Đổi ưu tiên cho ${ref.read(taskBoardFilterProvider).selectedIds.length} task',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            AppSpacing.gapMD,
            ...TaskPriority.values.map(
              (p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.flag_rounded,
                    color: _priorityColor(p), size: 20),
                title: Text(p.label),
                onTap: () {
                  Navigator.pop(ctx);
                  _bulkUpdatePriority(p);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return Icons.radio_button_unchecked_rounded;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case TaskStatus.completed:
        return Icons.check_circle_outline_rounded;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
      case TaskStatus.overdue:
        return Icons.warning_amber_rounded;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return AppColors.textTertiary;
      case TaskStatus.inProgress:
        return AppColors.info;
      case TaskStatus.completed:
        return AppColors.success;
      case TaskStatus.cancelled:
        return AppColors.error;
      case TaskStatus.overdue:
        return AppColors.warning;
    }
  }

  Future<void> _bulkUpdateStatus(TaskStatus status) async {
    final ids = List<String>.from(ref.read(taskBoardFilterProvider).selectedIds);
    ref.read(taskBoardFilterProvider.notifier).clearSelection();
    final service = ref.read(managementTaskServiceProvider);
    await Future.wait(
        ids.map((id) => service.updateTaskStatus(taskId: id, status: status.value)));
    _refresh();
  }

  Future<void> _bulkUpdatePriority(TaskPriority priority) async {
    final ids = List<String>.from(ref.read(taskBoardFilterProvider).selectedIds);
    ref.read(taskBoardFilterProvider.notifier).clearSelection();
    final service = ref.read(managementTaskServiceProvider);
    await Future.wait(ids.map(
        (id) => service.updateTask(taskId: id, priority: priority.value)));
    _refresh();
  }

  Future<void> _bulkDelete() async {
    final ids = List<String>.from(ref.read(taskBoardFilterProvider).selectedIds);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa ${ids.length} task đã chọn?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(taskBoardFilterProvider.notifier).clearSelection();
    final service = ref.read(managementTaskServiceProvider);
    await Future.wait(ids.map((id) => service.deleteTask(id)));
    _refresh();
  }

  // ==================== ACTIONS ====================

  void _refresh() {
    switch (cfg.mode) {
      case TaskBoardMode.ceoCreated:
        ref.invalidate(ceoStrategicTasksProvider);
      case TaskBoardMode.managerCreated:
        ref.invalidate(managerCreatedTasksProvider);
      case TaskBoardMode.assigned:
        ref.invalidate(managerAssignedTasksProvider);
      case TaskBoardMode.company:
        ref.invalidate(_companyTasksManagementProvider(cfg.companyId!));
    }
  }

  Future<void> _updateTaskStatus(ManagementTask task, TaskStatus newStatus) async {
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.updateTaskStatus(
        taskId: task.id,
        status: newStatus.value,
      );
      _refresh();

      // 🪙 SABO Token: Thưởng token khi hoàn thành task
      if (newStatus == TaskStatus.completed) {
        try {
          await ref.read(tokenWalletProvider.notifier).earnTokens(
            10,
            sourceType: 'task',
            sourceId: task.id,
            description: 'Hoàn thành task: ${task.title}',
          );
        } catch (_) {
          // Token reward is non-critical, don't block task flow
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == TaskStatus.completed
                  ? 'Đã hoàn thành! +10 🪙 SABO'
                  : 'Đã cập nhật: ${newStatus.label}',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final assignees = await cfg.loadAssignees?.call() ?? [];
    final companies = await cfg.loadCompanies?.call();
    final mediaChannels = await cfg.loadMediaChannels?.call();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TaskCreateEditDialog(
        assignees: assignees,
        companies: companies,
        mediaChannels: mediaChannels,
        onSave: (data) async {
          final service = ref.read(managementTaskServiceProvider);
          // Resolve assignee name from the assignees list
          String? assigneeName;
          String? assigneeRole;
          if (data['assigned_to'] != null) {
            final match = assignees.where((a) => a['id'] == data['assigned_to']).toList();
            if (match.isNotEmpty) {
              assigneeName = match.first['full_name'] as String?;
              assigneeRole = match.first['role'] as String?;
            }
          }
          await service.createTask(
            title: data['title'],
            description: data['description'],
            priority: data['priority'],
            assignedTo: data['assigned_to'] ?? '',
            assignedToName: assigneeName,
            assignedToRole: assigneeRole,
            companyId: data['company_id'],
            dueDate: data['due_date'] != null
                ? DateTime.parse(data['due_date'])
                : null,
            category: data['category'],
            checklist: data['checklist'] != null
                ? List<Map<String, dynamic>>.from(data['checklist'])
                : null,
          );
        },
      ),
    );

    if (result == true) _refresh();
  }

  Future<void> _showEditDialog(ManagementTask task) async {
    final assignees = await cfg.loadAssignees?.call() ?? [];
    final companies = await cfg.loadCompanies?.call();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TaskCreateEditDialog(
        task: task,
        assignees: assignees,
        companies: companies,
        onSave: (data) async {
          final service = ref.read(managementTaskServiceProvider);
          await service.updateTask(
            taskId: task.id,
            title: data['title'],
            description: data['description'],
            priority: data['priority'],
            category: data['category'],
            assignedTo: data['assigned_to'],
            companyId: data['company_id'],
            checklist: data['checklist'] != null
                ? List<Map<String, dynamic>>.from(data['checklist'])
                : null,
            dueDate: data['due_date'] != null
                ? DateTime.parse(data['due_date'])
                : null,
          );
        },
      ),
    );

    if (result == true) _refresh();
  }

  /// Send email notification to assignee
  Future<void> _sendEmailNotification(ManagementTask task) async {
    if (task.assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task chưa được giao cho ai'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.email_outlined, size: 20, color: AppColors.paymentRefunded),
            AppSpacing.hGapSM,
            const Text('Gửi email nhắc nhở?', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gửi email thông báo về task "${task.title}" đến:',
              style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
            ),
            AppSpacing.gapSM,
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.neutral400),
                  AppSpacing.hGapSM,
                  Text(
                    task.assignedToName ?? 'Không rõ',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Gửi'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.paymentRefunded),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              AppSpacing.hGapMD,
              Text('Đang gửi email...'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 10),
        ),
      );

      try {
        final emailService = ref.read(emailNotificationServiceProvider);
        await emailService.sendTaskReminder(task: task);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.white),
                  AppSpacing.hGapSM,
                  Text('Đã gửi email đến ${task.assignedToName ?? "nhân viên"}'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi gửi email: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(ManagementTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Xóa nhiệm vụ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Bạn sẽ xóa "${task.title}". Thao tác này không thể hoàn tác.',
          style: const TextStyle(fontSize: 13, color: AppColors.neutral500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(managementTaskServiceProvider);
        await service.deleteTask(task.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa nhiệm vụ'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showTaskDetail(ManagementTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
    ).then((_) => _refresh());
  }

  // ignore: unused_element
  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.neutral400),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Company tasks provider (reads ManagementTask from company)
// =============================================================================
final _companyTasksManagementProvider = FutureProvider.autoDispose
    .family<List<ManagementTask>, String>((ref, companyId) async {
  final service = ref.read(managementTaskServiceProvider);
  return service.getTasksByCompany(companyId);
});
