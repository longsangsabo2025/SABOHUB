import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/management_task.dart';
import '../../providers/management_task_provider.dart';
// managementTaskServiceProvider comes from management_task_provider re-exports
import '../../core/theme/app_colors.dart';
import 'task_card.dart';
import 'task_badges.dart';
import 'task_create_dialog.dart';
import 'task_detail_sheet.dart';

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

class _TaskBoardState extends ConsumerState<TaskBoard> {
  String _search = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;

  TaskBoardConfig get cfg => widget.config;

  @override
  Widget build(BuildContext context) {
    // Pick the right provider based on mode
    final tasksAsync = _getTasksAsync();

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
              const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text('Lỗi: $e', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 12),
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
        return Stack(
          children: [
            Column(
              children: [
                // Stats row
                if (cfg.showStats) _buildStatsRow(tasks),
                // Filter bar
                _buildFilterBar(tasks),
                // Task list
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: () async => _refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (ctx, i) =>
                                _buildTaskItem(filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
            // FAB
            if (cfg.canCreate)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'task_board_fab_${cfg.mode.name}',
                  onPressed: _showCreateDialog,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
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
    var result = tasks.toList();

    // Search
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((t) =>
          t.title.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false) ||
          (t.assignedToName?.toLowerCase().contains(q) ?? false) ||
          (t.createdByName?.toLowerCase().contains(q) ?? false)).toList();
    }

    // Status filter
    if (_statusFilter != null) {
      result = result.where((t) => t.status == _statusFilter).toList();
    }

    // Priority filter
    if (_priorityFilter != null) {
      result = result.where((t) => t.priority == _priorityFilter).toList();
    }

    return result;
  }

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
          _statChip('Tổng', total, const Color(0xFF6B7280), null),
          _statChip('Chờ', pending, const Color(0xFFF59E0B), TaskStatus.pending),
          _statChip('Đang', inProg, AppColors.info, TaskStatus.inProgress),
          _statChip('Xong', done, AppColors.success, TaskStatus.completed),
          if (overdue > 0)
            _statChip('Trễ', overdue, AppColors.error, TaskStatus.overdue),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color, TaskStatus? filter) {
    final isActive = _statusFilter == filter && filter != null;
    return Expanded(
      child: GestureDetector(
        onTap: filter == null
            ? () => setState(() => _statusFilter = null)
            : () => setState(() =>
                _statusFilter = _statusFilter == filter ? null : filter),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : const Color(0xFFE5E7EB),
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
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() => _search = ''),
                          child: const Icon(Icons.clear_rounded,
                              size: 16, color: Color(0xFF9CA3AF)),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Priority filter
          _buildPriorityFilterButton(),
          // Refresh
          const SizedBox(width: 4),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              onPressed: _refresh,
              padding: EdgeInsets.zero,
              tooltip: 'Tải lại',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterButton() {
    final hasFilter = _priorityFilter != null;
    return PopupMenuButton<TaskPriority?>(
      onSelected: (v) => setState(() => _priorityFilter = v),
      tooltip: 'Lọc ưu tiên',
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: hasFilter 
              ? priorityColor(_priorityFilter!).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFilter 
                ? priorityColor(_priorityFilter!) 
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          size: 18,
          color: hasFilter 
              ? priorityColor(_priorityFilter!) 
              : const Color(0xFF6B7280),
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
                  const SizedBox(width: 8),
                  Text(p.label, style: const TextStyle(fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  // ==================== TASK ITEMS ====================

  Widget _buildTaskItem(ManagementTask task) {
    return UnifiedTaskCard(
      task: task,
      showAssignee: cfg.showAssignee,
      showCreator: cfg.showCreator,
      showProgress: cfg.showProgress,
      showCompany: cfg.showCompany,
      onTap: () => _showTaskDetail(task),
      onStatusChange: cfg.canChangeStatus
          ? (status) => _updateTaskStatus(task, status)
          : null,
      onEdit: cfg.canEdit ? () => _showEditDialog(task) : null,
      onDelete: cfg.canDelete ? () => _confirmDelete(task) : null,
    );
  }

  // ==================== EMPTY STATE ====================

  Widget _buildEmpty() {
    final hasFilters = _search.isNotEmpty || _statusFilter != null || _priorityFilter != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters ? Icons.filter_alt_off_rounded : Icons.task_rounded,
              size: 48,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'Không tìm thấy nhiệm vụ phù hợp' : 'Chưa có nhiệm vụ nào',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _search = '';
                  _statusFilter = null;
                  _priorityFilter = null;
                }),
                child: const Text('Xóa bộ lọc', style: TextStyle(fontSize: 13)),
              ),
            ],
            if (!hasFilters && cfg.canCreate) ...[
              const SizedBox(height: 8),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật: ${newStatus.label}'),
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
            backgroundColor: const Color(0xFFEF4444),
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

  Future<void> _confirmDelete(ManagementTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Xóa nhiệm vụ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text(
          'Bạn sẽ xóa "${task.title}". Thao tác này không thể hoàn tác.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
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
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    }
  }

  void _showTaskDetail(ManagementTask task) {
    // Use TaskDetailSheet for ALL modes (including CEO)
    // This provides tabbed view: Chi tiết, Bình luận, Tệp đính kèm, Thêm
    // Permissions differ based on mode:
    // - assigned: full access (progress, checklist, comments, attachments, extension)
    // - managerCreated/ceo: can view all, add comments/attachments, but no progress/checklist edit
    final isAssignee = cfg.mode == TaskBoardMode.assigned;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskDetailSheet(
        task: task,
        canChangeStatus: cfg.canChangeStatus,
        canUpdateProgress: isAssignee, // Only assignee can update progress
        canEditChecklist: isAssignee,  // Only assignee can edit checklist
        canAddComments: true,          // Everyone can add comments
        canAddAttachments: true,       // Everyone can add attachments
        canRequestExtension: isAssignee && task.dueDate != null,
        onTaskUpdated: _refresh,
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
