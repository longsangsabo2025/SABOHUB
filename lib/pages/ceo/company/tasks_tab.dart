import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/company.dart';
import '../../../models/management_task.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cached_data_providers.dart';
import '../../../providers/data_action_providers.dart';
import '../../../providers/cache_provider.dart';
import '../../../providers/cached_providers.dart' show managementTaskServiceProvider;
import '../../../services/task_service.dart'; // used for direct field updates (recurrence, assignee)
import '../../../widgets/task/task_create_dialog.dart';
import '../edit_task_dialog.dart';
import '../task_detail_page.dart';

// ─── Recurrence helpers ───────────────────────────────────────────────────────
String _recurrenceLabel(String r) {
  switch (r) {
    case 'daily': return 'Hằng ngày';
    case 'weekly': return 'Hằng tuần';
    case 'monthly': return 'Hằng tháng';
    case 'adhoc': return 'Đột xuất';
    case 'project': return 'Dự án';
    default: return 'Không lặp';
  }
}

Color _recurrenceColor(String r) {
  switch (r) {
    case 'daily': return AppColors.success;
    case 'weekly': return AppColors.info;
    case 'monthly': return AppColors.paymentRefunded;
    case 'adhoc': return AppColors.warning;
    case 'project': return AppColors.secondary;
    default: return AppColors.neutral500;
  }
}

IconData _recurrenceIcon(String r) {
  switch (r) {
    case 'daily': return Icons.today_rounded;
    case 'weekly': return Icons.date_range_rounded;
    case 'monthly': return Icons.calendar_month_rounded;
    case 'adhoc': return Icons.flash_on_rounded;
    case 'project': return Icons.work_rounded;
    default: return Icons.event_note_rounded;
  }
}

/// Task Template for library
class TaskTemplate {
  final String title;
  final String description;
  final String recurrence; // 'daily', 'weekly', 'monthly', 'adhoc', 'project', 'none'
  final String priority;   // 'critical', 'high', 'medium', 'low'
  final String? category;  // 'operations', 'maintenance', etc.

  TaskTemplate({
    required this.title,
    required this.description,
    required this.recurrence,
    required this.priority,
    this.category,
  });
}

/// Tasks Tab for Company Details
class TasksTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const TasksTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab>
    with SingleTickerProviderStateMixin {
  String? _selectedRecurrence;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(cachedCompanyTasksProvider(widget.companyId));
    final statsAsync =
        ref.watch(cachedCompanyTaskStatsProvider(widget.companyId));

    return Column(
      children: [
        _buildHeader(context, statsAsync),
        _buildMainTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChecklistView(tasksAsync),
              _buildTemplateLibrary(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist_rounded, size: 20),
                SizedBox(width: 8),
                Text('Checklist', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, size: 20),
                SizedBox(width: 8),
                Text('Thư viện mẫu', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quản lý công việc',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateTaskDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Tạo công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) {
              final total = stats['total'] ?? 0;
              final completed = stats['completed'] ?? 0;
              final progress = total > 0 ? completed / total : 0.0;
              final isDone = total > 0 && completed == total;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.assignment,
                          '$total',
                          'Tổng số',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.pending_actions,
                          '${stats['pending'] ?? 0}',
                          'Cần làm',
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.sync,
                          '${stats['in_progress'] ?? 0}',
                          'Đang làm',
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          Icons.check_circle,
                          '$completed',
                          'Hoàn thành',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Overall progress bar
                  Row(
                    children: [
                      Icon(
                        isDone ? Icons.emoji_events_rounded : Icons.track_changes_rounded,
                        size: 14,
                        color: isDone ? Colors.green[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tiến độ tổng quát',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '$completed/$total hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.green[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDone ? Colors.green : Colors.blue,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list, size: 16),
                  SizedBox(width: 6),
                  Text('Tất cả')
                ],
              ),
              selected: _selectedRecurrence == null,
              onSelected: (selected) =>
                  setState(() => _selectedRecurrence = null),
              selectedColor: Colors.blue[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, size: 16),
                  SizedBox(width: 6),
                  Text('Hằng ngày')
                ],
              ),
              selected: _selectedRecurrence == 'daily',
              onSelected: (selected) => setState(() =>
                  _selectedRecurrence = selected ? 'daily' : null),
              selectedColor: Colors.green[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range, size: 16),
                  SizedBox(width: 6),
                  Text('Hằng tuần')
                ],
              ),
              selected: _selectedRecurrence == 'weekly',
              onSelected: (selected) => setState(() => _selectedRecurrence =
                  selected ? 'weekly' : null),
              selectedColor: Colors.blue[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 16),
                  SizedBox(width: 6),
                  Text('Hằng tháng')
                ],
              ),
              selected: _selectedRecurrence == 'monthly',
              onSelected: (selected) => setState(() => _selectedRecurrence =
                  selected ? 'monthly' : null),
              selectedColor: Colors.purple[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, size: 16),
                  SizedBox(width: 6),
                  Text('Đột xuất')
                ],
              ),
              selected: _selectedRecurrence == 'adhoc',
              onSelected: (selected) => setState(() =>
                  _selectedRecurrence = selected ? 'adhoc' : null),
              selectedColor: Colors.orange[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work, size: 16),
                  SizedBox(width: 6),
                  Text('Dự án')
                ],
              ),
              selected: _selectedRecurrence == 'project',
              onSelected: (selected) => setState(() => _selectedRecurrence =
                  selected ? 'project' : null),
              selectedColor: Colors.teal[100],
            ),
          ],
        ),
      ),
    );
  }

  // ─── CHECKLIST VIEW ──────────────────────────────────────────────────────

  Widget _buildChecklistView(AsyncValue<List<ManagementTask>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) return _buildEmptyState();

        // Group by recurrence
        final daily = tasks.where((t) => t.recurrence == 'daily').toList();
        final weekly = tasks.where((t) => t.recurrence == 'weekly').toList();
        final monthly = tasks.where((t) => t.recurrence == 'monthly').toList();
        final others = tasks
            .where((t) =>
                t.recurrence != 'daily' &&
                t.recurrence != 'weekly' &&
                t.recurrence != 'monthly')
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
            ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (daily.isNotEmpty)
                _buildChecklistSection(
                  'Hôm nay',
                  'Hằng ngày',
                  Icons.today_rounded,
                  AppColors.success,
                  daily,
                ),
              if (weekly.isNotEmpty)
                _buildChecklistSection(
                  'Tuần này',
                  'Hằng tuần',
                  Icons.date_range_rounded,
                  AppColors.info,
                  weekly,
                ),
              if (monthly.isNotEmpty)
                _buildChecklistSection(
                  'Tháng này',
                  'Hằng tháng',
                  Icons.calendar_month_rounded,
                  AppColors.paymentRefunded,
                  monthly,
                ),
              if (others.isNotEmpty)
                _buildChecklistSection(
                  'Đột xuất & Dự án',
                  '',
                  Icons.flash_on_rounded,
                  AppColors.warning,
                  others,
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Lỗi tải dữ liệu', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<ManagementTask> tasks,
  ) {
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final total = tasks.length;
    final progress = total > 0 ? completed / total : 0.0;
    final isDone = total > 0 && completed == total;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 17, color: color),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              height: 1.2,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    // Progress badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDone
                              ? Colors.green.withValues(alpha: 0.5)
                              : color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDone) ...
                            [
                              Icon(Icons.check_circle_rounded,
                                  size: 13, color: Colors.green[700]),
                              const SizedBox(width: 4),
                            ],
                          Text(
                            '$completed/$total',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDone ? Colors.green[700] : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add task button for this recurrence
                    InkWell(
                      onTap: () => _showCreateTaskDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.add, size: 15, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : color,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // ── Task checklist items ─────────────────────────
          ...tasks.asMap().entries.map((entry) {
            final idx = entry.key;
            final task = entry.value;
            return Column(
              children: [
                if (idx > 0)
                  Divider(
                      height: 1,
                      indent: 50,
                      endIndent: 0,
                      color: Colors.grey[100]),
                _buildChecklistItem(task),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ManagementTask task) {
    final isCompleted = task.status == TaskStatus.completed;
    final isInProgress = task.status == TaskStatus.inProgress;

    return InkWell(
      onTap: () => _showTaskDetails(task),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated Checkbox
            GestureDetector(
              onTap: () => _toggleComplete(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : isInProgress
                            ? Colors.purple
                            : Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: isCompleted
                    ? Icon(Icons.check_rounded,
                        size: 15, color: Theme.of(context).colorScheme.surface)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Priority dot
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: task.priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isCompleted ? FontWeight.w400 : FontWeight.w600,
                      color:
                          isCompleted ? Colors.grey[400] : Colors.grey[800],
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.grey[400],
                      height: 1.25,
                    ),
                  ),
                  if (task.assignedToName != null || task.dueDate != null) ...
                    [
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (task.assignedToName != null) ...
                            [
                              Icon(Icons.person_outline,
                                  size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 3),
                              Text(
                                task.assignedToName!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                              if (task.dueDate != null)
                                Text(' · ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400])),
                            ],
                          if (task.dueDate != null) ...
                            [
                              Icon(Icons.access_time_rounded,
                                  size: 11, color: _dueDateColor(task)),
                              const SizedBox(width: 3),
                              Text(
                                DateFormat('dd/MM').format(task.dueDate!),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _dueDateColor(task)),
                              ),
                            ],
                        ],
                      ),
                    ],
                ],
              ),
            ),
            // Status badge for in-progress
            if (isInProgress) ...
              [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Đang làm',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            // 3-dot menu
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTaskDialog(task);
                } else if (value == 'delete') {
                  _deleteTask(task);
                } else if (value == 'assignee') {
                  _showChangeAssigneeDialog(task);
                } else if (value == 'recurrence') {
                  _showChangeRecurrenceDialog(task);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'assignee',
                  child: Row(children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Phân công')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'recurrence',
                  child: Row(children: [
                    Icon(Icons.repeat, size: 18),
                    SizedBox(width: 8),
                    Text('Chuyển lịch lặp')
                  ]),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa',
                        style: TextStyle(color: Colors.red))
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _dueDateColor(ManagementTask task) {
    if (task.dueDate == null) return Colors.grey[400]!;
    final diff = task.dueDate!.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.red[600]!;
    if (diff <= 3) return Colors.orange[700]!;
    return Colors.grey[500]!;
  }

  Future<void> _toggleComplete(ManagementTask task) async {
    final newStatusStr = task.status == TaskStatus.completed
        ? TaskStatus.pending.value
        : TaskStatus.completed.value;
    try {
      final service = ref.read(managementTaskServiceProvider);
      await service.updateTaskStatus(taskId: task.id, status: newStatusStr);
      if (mounted) {
        ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
        ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ignore: unused_element
  Widget _buildTaskCard(ManagementTask task) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final daysUntilDue = task.dueDate?.difference(now).inDays ?? 0;
    final isOverdue = task.dueDate != null && daysUntilDue < 0;
    final isUrgent = task.dueDate != null && daysUntilDue >= 0 && daysUntilDue <= 3;
    
    // Màu viền theo mức độ ưu tiên
    Color borderColor = Colors.grey[300]!;
    if (isOverdue) {
      borderColor = Colors.red;
    } else if (task.priority == TaskPriority.critical || isUrgent) {
      borderColor = Colors.red[700]!;
    } else if (task.priority == TaskPriority.high) {
      borderColor = Colors.orange[700]!;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 2),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // HÀNG 1: Icon + Title + Badges + Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon ưu tiên
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: task.priority.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPriorityIcon(task.priority),
                      color: task.priority.color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title + Description (nếu có)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((task.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Priority badge
                  _buildCompactBadge(
                    task.priority.label,
                    task.priority.color,
                    icon: _getPriorityIcon(task.priority),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // Status badge
                  _buildCompactBadge(
                    task.status.label,
                    task.status.color,
                    icon: _getStatusIcon(task.status),
                  ),
                  
                  // Menu
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditTaskDialog(task);
                      } else if (value == 'delete') {
                        _deleteTask(task);
                      } else if (value == 'change_recurrence') {
                        _showChangeRecurrenceDialog(task);
                      } else if (value == 'change_assignee') {
                        _showChangeAssigneeDialog(task);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_recurrence',
                        child: Row(
                          children: [
                            Icon(Icons.repeat, size: 18),
                            SizedBox(width: 8),
                            Text('Chuyển lịch lặp'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change_recurrence',
                        child: Row(
                          children: [
                            Icon(Icons.repeat, size: 18),
                            SizedBox(width: 8),
                            Text('Chuyển lịch lặp'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change_assignee',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Đổi người phụ trách'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // HÀNG 2: Người phụ trách | Deadline | Recurring
              Row(
                children: [
                  // Người phụ trách
                  if (task.assignedToName != null)
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                task.assignedToName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Chưa phân công',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Deadline - NỔI BẬT
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red[50]
                            : isUrgent
                                ? Colors.orange[50]
                                : Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isOverdue
                              ? Colors.red[400]!
                              : isUrgent
                                  ? Colors.orange[400]!
                                  : Colors.green[400]!,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.warning_rounded
                                : Icons.access_time_rounded,
                            size: 14,
                            color: isOverdue
                                ? Colors.red[700]
                                : isUrgent
                                    ? Colors.orange[700]
                                    : Colors.green[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOverdue
                                  ? 'QUÁ HẠN ${-daysUntilDue}d'
                                  : isUrgent
                                      ? 'GẤP ${daysUntilDue}d - ${task.dueDate != null ? dateFormat.format(task.dueDate!) : 'Chưa có'}'
                                      : task.dueDate != null ? dateFormat.format(task.dueDate!) : 'Chưa có',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isOverdue || isUrgent ? FontWeight.bold : FontWeight.w600,
                                color: isOverdue
                                    ? Colors.red[900]
                                    : isUrgent
                                        ? Colors.orange[900]
                                        : Colors.green[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Recurring badge (nếu có)
                  if (task.recurrence.isNotEmpty && task.recurrence != 'none') ...[
                    const SizedBox(width: 6),
                    _buildCompactBadge(
                      _recurrenceLabel(task.recurrence),
                      _recurrenceColor(task.recurrence),
                      icon: Icons.repeat,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Icons.crisis_alert_rounded;
      case TaskPriority.high:
        return Icons.priority_high_rounded;
      case TaskPriority.medium:
        return Icons.remove_circle_outline;
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icons.check_circle_rounded;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline_rounded;
      case TaskStatus.pending:
        return Icons.pending_outlined;
      case TaskStatus.overdue:
        return Icons.warning_rounded;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Widget _buildCompactBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Chưa có công việc', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo công việc'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateLibrary() {
    final templates = _getTaskTemplates();

    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _buildTemplateCard(template);
        },
      ),
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCompactBadge(
                    _recurrenceLabel(template.recurrence), _recurrenceColor(template.recurrence),
                    icon: _recurrenceIcon(template.recurrence)),
                const SizedBox(width: 8),
                _buildCompactBadge(
                  TaskPriority.fromString(template.priority).label,
                  TaskPriority.fromString(template.priority).color,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _applyTemplate(template),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Áp dụng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Theme.of(context).colorScheme.surface,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: TextStyle(color: Colors.grey[600]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (template.category != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.category, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    template.category!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TaskTemplate> _getTaskTemplates() {
    return [
      // Hằng ngày
      TaskTemplate(
        title: 'Kiểm tra vệ sinh khu vực làm việc',
        description:
            'Kiểm tra và đảm bảo vệ sinh sạch sẽ tất cả các bàn bi-a, khu vực chơi, và khu vực chung',
        recurrence: 'daily',
        priority: 'high',
        category: 'maintenance',
      ),
      TaskTemplate(
        title: 'Báo cáo doanh thu cuối ngày',
        description:
            'Tổng hợp doanh thu, số lượng khách, và các chỉ số kinh doanh của ngày',
        recurrence: 'daily',
        priority: 'high',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Kiểm tra thiết bị âm thanh ánh sáng',
        description:
            'Kiểm tra hệ thống âm thanh, đèn chiếu sáng và thiết bị kỹ thuật hoạt động bình thường',
        recurrence: 'daily',
        priority: 'medium',
        category: 'maintenance',
      ),
      TaskTemplate(
        title: 'Cập nhật tình trạng kho',
        description:
            'Kiểm tra và cập nhật số lượng đồ uống, thức ăn và vật tư tiêu hao',
        recurrence: 'daily',
        priority: 'medium',
        category: 'inventory',
      ),

      // Hằng tuần
      TaskTemplate(
        title: 'Họp team hàng tuần',
        description:
            'Họp đánh giá hiệu suất, chia sẻ kinh nghiệm và lên kế hoạch cho tuần tiếp theo',
        recurrence: 'weekly',
        priority: 'high',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Vệ sinh tổng thể cơ sở',
        description:
            'Vệ sinh sâu toàn bộ cơ sở: sàn nhà, tường, trần, kho và khu vực ngoài trời',
        recurrence: 'weekly',
        priority: 'high',
        category: 'maintenance',
      ),
      TaskTemplate(
        title: 'Kiểm tra và bảo dưỡng bàn bi-a',
        description:
            'Kiểm tra độ phẳng bàn, nỉ, giấy, băng cao su và các bộ phận của bàn bi-a',
        recurrence: 'weekly',
        priority: 'medium',
        category: 'maintenance',
      ),
      TaskTemplate(
        title: 'Review feedback khách hàng',
        description:
            'Đọc và phân tích các feedback từ khách hàng, đề xuất cải thiện',
        recurrence: 'weekly',
        priority: 'medium',
        category: 'customerService',
      ),
      TaskTemplate(
        title: 'Cập nhật bảng giá và khuyến mãi',
        description:
            'Review và cập nhật bảng giá dịch vụ, các chương trình khuyến mãi',
        recurrence: 'weekly',
        priority: 'medium',
        category: 'operations',
      ),

      // Hằng tháng
      TaskTemplate(
        title: 'Kiểm kê kho hàng tháng',
        description:
            'Kiểm kê toàn bộ kho hàng, đối chiếu với sổ sách và lập báo cáo',
        recurrence: 'monthly',
        priority: 'high',
        category: 'inventory',
      ),
      TaskTemplate(
        title: 'Báo cáo tài chính tháng',
        description:
            'Tổng hợp doanh thu, chi phí, lợi nhuận và các chỉ số tài chính của tháng',
        recurrence: 'monthly',
        priority: 'high',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Đánh giá nhân viên tháng',
        description:
            'Đánh giá hiệu suất làm việc, thái độ và kỹ năng của từng nhân viên',
        recurrence: 'monthly',
        priority: 'medium',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Bảo trì thiết bị định kỳ',
        description:
            'Bảo trì, bảo dưỡng toàn bộ thiết bị: máy lạnh, quạt, đèn, máy tính tiền',
        recurrence: 'monthly',
        priority: 'medium',
        category: 'maintenance',
      ),

      // Đột xuất
      TaskTemplate(
        title: 'Xử lý khiếu nại khách hàng',
        description:
            'Tiếp nhận và xử lý nhanh các khiếu nại, phàn nàn từ khách hàng',
        recurrence: 'adhoc',
        priority: 'critical',
        category: 'customerService',
      ),
      TaskTemplate(
        title: 'Sửa chữa thiết bị hỏng hóc',
        description:
            'Xử lý sự cố và sửa chữa thiết bị bị hỏng trong quá trình hoạt động',
        recurrence: 'adhoc',
        priority: 'critical',
        category: 'maintenance',
      ),
      TaskTemplate(
        title: 'Đặt hàng khẩn cấp',
        description: 'Đặt hàng bổ sung khẩn cấp khi hết hàng hoặc thiếu vật tư',
        recurrence: 'adhoc',
        priority: 'high',
        category: 'inventory',
      ),

      // Dự án
      TaskTemplate(
        title: 'Tổ chức sự kiện giải đấu',
        description: 'Lên kế hoạch và tổ chức giải đấu bi-a thu hút khách hàng',
        recurrence: 'project',
        priority: 'high',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Mở rộng/cải tạo cơ sở',
        description:
            'Lên kế hoạch và thực hiện dự án mở rộng hoặc cải tạo cơ sở',
        recurrence: 'project',
        priority: 'medium',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Đào tạo nhân viên mới',
        description:
            'Chương trình đào tạo toàn diện cho nhân viên mới về quy trình và kỹ năng',
        recurrence: 'project',
        priority: 'medium',
        category: 'operations',
      ),
      TaskTemplate(
        title: 'Chiến dịch marketing',
        description:
            'Lên kế hoạch và triển khai chiến dịch marketing thu hút khách hàng mới',
        recurrence: 'project',
        priority: 'medium',
        category: 'operations',
      ),
    ];
  }

  Future<void> _applyTemplate(TaskTemplate template) async {
    try {
      final appUser = ref.read(currentUserProvider);
      if (appUser == null) return;

      final service = ref.read(managementTaskServiceProvider);
      await service.createTask(
        title: template.title,
        description: template.description,
        priority: template.priority,
        assignedTo: '',
        companyId: widget.company.id,
        dueDate: _calculateDueDate(template.recurrence),
        category: template.category,
        recurrence: template.recurrence,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo công việc: ${template.title}'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to tasks tab
        _tabController.animateTo(0);

        // Invalidate CACHED providers (đang dùng cached providers trong UI)
        ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
        ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  DateTime _calculateDueDate(String recurrence) {
    final now = DateTime.now();
    switch (recurrence) {
      case 'daily':
        return DateTime(now.year, now.month, now.day, 23, 59);
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      case 'adhoc':
        return now.add(const Duration(days: 1));
      case 'project':
        return now.add(const Duration(days: 30));
      default:
        return now.add(const Duration(days: 7));
    }
  }

  void _showCreateTaskDialog(BuildContext context) async {
    // Load assignees for the task dialog
    final employeesAsync = ref.read(cachedCompanyEmployeesProvider(widget.companyId));
    final employees = employeesAsync.when(
      data: (data) => data,
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );
    
    // Convert to format expected by TaskCreateEditDialog
    final assignees = employees.map<Map<String, dynamic>>((e) => {
      'id': e['id'],
      'full_name': e['name'] ?? e['email'] ?? '',
      'role': e['role'] ?? '',
    }).toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreateEditDialog(
        assignees: assignees,
        defaultCompanyId: widget.companyId,
        onSave: (data) async {
          // Use ManagementTaskService.createTask
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
            companyId: widget.companyId,
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

    if (result == true && mounted) {
      // Invalidate CACHED providers để UI cập nhật ngay
      ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
      ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
    }
  }

  void _showEditTaskDialog(ManagementTask task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditTaskDialog(
        task: task,
        companyId: widget.companyId,
      ),
    );

    if (result == true && mounted) {
      // Invalidate CACHED providers để UI cập nhật ngay
      ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
      ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
    }
  }

  void _showTaskDetails(ManagementTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
    ).then((_) {
      if (mounted) {
        ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
        ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
      }
    });
  }

  Future<void> _deleteTask(ManagementTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ✅ Use action provider to auto-invalidate cache
      final taskActions = ref.read(taskActionsProvider);
      await taskActions.deleteTask(task.id);

      if (mounted) {
        // ✅ NUCLEAR OPTION: Clear ALL caches immediately
        final memoryCache = ref.read(memoryCacheProvider);
        memoryCache.clear(); // XÓA TẤT CẢ cache luôn
        
        // ✅ Force REFRESH providers - làm providers fetch lại từ DB
        // ignore: unused_local_variable
        final unused1 = ref.refresh(cachedCompanyTasksProvider(widget.companyId));
        // ignore: unused_local_variable
        final unused2 = ref.refresh(cachedCompanyTaskStatsProvider(widget.companyId));
        
        // ✅ Force UI rebuild by updating state
        setState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã xóa công việc'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Chuyển lịch lặp
  Future<void> _showChangeRecurrenceDialog(ManagementTask task) async {
    final recurrenceOptions = [
      ('daily', 'Hằng ngày', Icons.today_rounded),
      ('weekly', 'Hằng tuần', Icons.date_range_rounded),
      ('monthly', 'Hằng tháng', Icons.calendar_month_rounded),
      ('adhoc', 'Đột xuất', Icons.flash_on_rounded),
      ('project', 'Dự án', Icons.work_rounded),
      ('none', 'Không lặp', Icons.event_note_rounded),
    ];

    final newRecurrence = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn lịch lặp mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: recurrenceOptions.map((opt) {
            return ListTile(
              leading: Icon(opt.$3, color: _recurrenceColor(opt.$1)),
              title: Text(opt.$2),
              selected: task.recurrence == opt.$1,
              onTap: () => Navigator.pop(context, opt.$1),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (newRecurrence == null || newRecurrence == task.recurrence) return;

    try {
      final taskService = TaskService();
      await taskService.updateTask(task.id, {
        'recurrence': newRecurrence,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển sang "${_recurrenceLabel(newRecurrence)}"'),
            backgroundColor: Colors.green,
          ),
        );

        // Invalidate CACHED providers để UI cập nhật ngay
        ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
        ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Đổi người phụ trách
  Future<void> _showChangeAssigneeDialog(ManagementTask task) async {
    final employeesAsync = ref.read(cachedCompanyEmployeesProvider(widget.companyId));

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn người phụ trách'),
        content: SizedBox(
          width: double.maxFinite,
          child: employeesAsync.when(
            data: (employees) {
              if (employees.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chưa có nhân viên nào'),
                );
              }

              return ListView(
                shrinkWrap: true,
                children: [
                  // Option: Không phân công
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person_off, color: Colors.grey),
                    ),
                    title: const Text('Chưa phân công'),
                    selected: task.assignedTo == null,
                    onTap: () => Navigator.pop(context, {'id': null, 'name': null}),
                  ),
                  const Divider(),
                  // Danh sách nhân viên
                  ...employees.map((employee) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          employee.fullName.isNotEmpty
                              ? employee.fullName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(employee.fullName),
                      subtitle: Text(employee.email),
                      selected: task.assignedTo == employee.userId,
                      onTap: () => Navigator.pop(context, {
                        'id': employee.userId,
                        'name': employee.fullName,
                      }),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi: $err'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    ).then((result) async {
      if (result == null) return;

      final newAssigneeId = result['id'] as String?;
      final newAssigneeName = result['name'] as String?;

      // Nếu không thay đổi
      if (newAssigneeId == task.assignedTo) return;

      try {
        final taskService = TaskService();
        await taskService.updateTask(task.id, {
          'assigned_to': newAssigneeId,
          'assigned_to_name': newAssigneeName,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newAssigneeName != null
                    ? 'Đã phân công cho $newAssigneeName'
                    : 'Đã bỏ phân công',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Invalidate CACHED providers để UI cập nhật ngay
          ref.invalidate(cachedCompanyTasksProvider(widget.companyId));
          ref.invalidate(cachedCompanyTaskStatsProvider(widget.companyId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }
}

