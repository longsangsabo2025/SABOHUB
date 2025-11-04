import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/company.dart';
import '../../../models/task.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/cached_data_providers.dart';
import '../../../services/task_service.dart';
import '../create_task_dialog.dart';
import '../edit_task_dialog.dart';
import '../task_details_dialog.dart';

/// Task Template for library
class TaskTemplate {
  final String title;
  final String description;
  final TaskRecurrence recurrence;
  final TaskPriority priority;
  final TaskCategory? category;

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

class _TasksTabState extends ConsumerState<TasksTab> with SingleTickerProviderStateMixin {
  TaskRecurrence? _selectedRecurrence;
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
    final statsAsync = ref.watch(cachedCompanyTaskStatsProvider(widget.companyId));

    return Column(
      children: [
        _buildHeader(context, statsAsync),
        _buildFilterChips(),
        _buildMainTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTasksList(tasksAsync.whenData((tasks) => tasks.cast<Task>())),
              _buildTemplateLibrary(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    return Container(
      color: Colors.white,
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
                Icon(Icons.list_alt, size: 20),
                SizedBox(width: 8),
                Text('Công việc', style: TextStyle(fontSize: 15)),
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

  Widget _buildHeader(BuildContext context, AsyncValue<Map<String, int>> statsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
                label: const Text('Tạo công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.assignment,
                    '${stats['total'] ?? 0}',
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
                    '${stats['completed'] ?? 0}',
                    'Hoàn thành',
                    Colors.green,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.list, size: 16), SizedBox(width: 6), Text('Tất cả')],
              ),
              selected: _selectedRecurrence == null,
              onSelected: (selected) => setState(() => _selectedRecurrence = null),
              selectedColor: Colors.blue[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.today, size: 16), SizedBox(width: 6), Text('Hằng ngày')],
              ),
              selected: _selectedRecurrence == TaskRecurrence.daily,
              onSelected: (selected) => setState(() => _selectedRecurrence = selected ? TaskRecurrence.daily : null),
              selectedColor: Colors.green[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.date_range, size: 16), SizedBox(width: 6), Text('Hằng tuần')],
              ),
              selected: _selectedRecurrence == TaskRecurrence.weekly,
              onSelected: (selected) => setState(() => _selectedRecurrence = selected ? TaskRecurrence.weekly : null),
              selectedColor: Colors.blue[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.calendar_month, size: 16), SizedBox(width: 6), Text('Hằng tháng')],
              ),
              selected: _selectedRecurrence == TaskRecurrence.monthly,
              onSelected: (selected) => setState(() => _selectedRecurrence = selected ? TaskRecurrence.monthly : null),
              selectedColor: Colors.purple[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.flash_on, size: 16), SizedBox(width: 6), Text('Đột xuất')],
              ),
              selected: _selectedRecurrence == TaskRecurrence.adhoc,
              onSelected: (selected) => setState(() => _selectedRecurrence = selected ? TaskRecurrence.adhoc : null),
              selectedColor: Colors.orange[100],
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.work, size: 16), SizedBox(width: 6), Text('Dự án')],
              ),
              selected: _selectedRecurrence == TaskRecurrence.project,
              onSelected: (selected) => setState(() => _selectedRecurrence = selected ? TaskRecurrence.project : null),
              selectedColor: Colors.teal[100],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(AsyncValue<List<Task>> tasksAsync) {
    return Expanded(
      child: tasksAsync.when(
        data: (tasks) {
          var filteredTasks = _selectedRecurrence == null
              ? tasks
              : tasks.where((task) => task.recurrence == _selectedRecurrence).toList();

          if (filteredTasks.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyTasksProvider(widget.companyId));
              ref.invalidate(companyTaskStatsProvider(widget.companyId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBadge(task.recurrence.label, task.recurrence.color),
                  const SizedBox(width: 8),
                  _buildBadge(task.priority.label, task.priority.color),
                  const SizedBox(width: 8),
                  _buildBadge(task.status.label, task.status.color),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditTaskDialog(task);
                      } else if (value == 'delete') {
                        _deleteTask(task);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(task.description, style: TextStyle(color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(dateFormat.format(task.dueDate), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (task.assignedToName != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(task.assignedToName!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
                _buildBadge(template.recurrence.label, template.recurrence.color),
                const SizedBox(width: 8),
                _buildBadge(template.priority.label, template.priority.color),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _applyTemplate(template),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Áp dụng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    template.category!.label,
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
        description: 'Kiểm tra và đảm bảo vệ sinh sạch sẽ tất cả các bàn bi-a, khu vực chơi, và khu vực chung',
        recurrence: TaskRecurrence.daily,
        priority: TaskPriority.high,
        category: TaskCategory.maintenance,
      ),
      TaskTemplate(
        title: 'Báo cáo doanh thu cuối ngày',
        description: 'Tổng hợp doanh thu, số lượng khách, và các chỉ số kinh doanh của ngày',
        recurrence: TaskRecurrence.daily,
        priority: TaskPriority.high,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Kiểm tra thiết bị âm thanh ánh sáng',
        description: 'Kiểm tra hệ thống âm thanh, đèn chiếu sáng và thiết bị kỹ thuật hoạt động bình thường',
        recurrence: TaskRecurrence.daily,
        priority: TaskPriority.medium,
        category: TaskCategory.maintenance,
      ),
      TaskTemplate(
        title: 'Cập nhật tình trạng kho',
        description: 'Kiểm tra và cập nhật số lượng đồ uống, thức ăn và vật tư tiêu hao',
        recurrence: TaskRecurrence.daily,
        priority: TaskPriority.medium,
        category: TaskCategory.inventory,
      ),

      // Hằng tuần
      TaskTemplate(
        title: 'Họp team hàng tuần',
        description: 'Họp đánh giá hiệu suất, chia sẻ kinh nghiệm và lên kế hoạch cho tuần tiếp theo',
        recurrence: TaskRecurrence.weekly,
        priority: TaskPriority.high,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Vệ sinh tổng thể cơ sở',
        description: 'Vệ sinh sâu toàn bộ cơ sở: sàn nhà, tường, trần, kho và khu vực ngoài trời',
        recurrence: TaskRecurrence.weekly,
        priority: TaskPriority.high,
        category: TaskCategory.maintenance,
      ),
      TaskTemplate(
        title: 'Kiểm tra và bảo dưỡng bàn bi-a',
        description: 'Kiểm tra độ phẳng bàn, nỉ, giấy, băng cao su và các bộ phận của bàn bi-a',
        recurrence: TaskRecurrence.weekly,
        priority: TaskPriority.medium,
        category: TaskCategory.maintenance,
      ),
      TaskTemplate(
        title: 'Review feedback khách hàng',
        description: 'Đọc và phân tích các feedback từ khách hàng, đề xuất cải thiện',
        recurrence: TaskRecurrence.weekly,
        priority: TaskPriority.medium,
        category: TaskCategory.customerService,
      ),
      TaskTemplate(
        title: 'Cập nhật bảng giá và khuyến mãi',
        description: 'Review và cập nhật bảng giá dịch vụ, các chương trình khuyến mãi',
        recurrence: TaskRecurrence.weekly,
        priority: TaskPriority.medium,
        category: TaskCategory.operations,
      ),

      // Hằng tháng
      TaskTemplate(
        title: 'Kiểm kê kho hàng tháng',
        description: 'Kiểm kê toàn bộ kho hàng, đối chiếu với sổ sách và lập báo cáo',
        recurrence: TaskRecurrence.monthly,
        priority: TaskPriority.high,
        category: TaskCategory.inventory,
      ),
      TaskTemplate(
        title: 'Báo cáo tài chính tháng',
        description: 'Tổng hợp doanh thu, chi phí, lợi nhuận và các chỉ số tài chính của tháng',
        recurrence: TaskRecurrence.monthly,
        priority: TaskPriority.high,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Đánh giá nhân viên tháng',
        description: 'Đánh giá hiệu suất làm việc, thái độ và kỹ năng của từng nhân viên',
        recurrence: TaskRecurrence.monthly,
        priority: TaskPriority.medium,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Bảo trì thiết bị định kỳ',
        description: 'Bảo trì, bảo dưỡng toàn bộ thiết bị: máy lạnh, quạt, đèn, máy tính tiền',
        recurrence: TaskRecurrence.monthly,
        priority: TaskPriority.medium,
        category: TaskCategory.maintenance,
      ),

      // Đột xuất
      TaskTemplate(
        title: 'Xử lý khiếu nại khách hàng',
        description: 'Tiếp nhận và xử lý nhanh các khiếu nại, phàn nàn từ khách hàng',
        recurrence: TaskRecurrence.adhoc,
        priority: TaskPriority.urgent,
        category: TaskCategory.customerService,
      ),
      TaskTemplate(
        title: 'Sửa chữa thiết bị hỏng hóc',
        description: 'Xử lý sự cố và sửa chữa thiết bị bị hỏng trong quá trình hoạt động',
        recurrence: TaskRecurrence.adhoc,
        priority: TaskPriority.urgent,
        category: TaskCategory.maintenance,
      ),
      TaskTemplate(
        title: 'Đặt hàng khẩn cấp',
        description: 'Đặt hàng bổ sung khẩn cấp khi hết hàng hoặc thiếu vật tư',
        recurrence: TaskRecurrence.adhoc,
        priority: TaskPriority.high,
        category: TaskCategory.inventory,
      ),

      // Dự án
      TaskTemplate(
        title: 'Tổ chức sự kiện giải đấu',
        description: 'Lên kế hoạch và tổ chức giải đấu bi-a thu hút khách hàng',
        recurrence: TaskRecurrence.project,
        priority: TaskPriority.high,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Mở rộng/cải tạo cơ sở',
        description: 'Lên kế hoạch và thực hiện dự án mở rộng hoặc cải tạo cơ sở',
        recurrence: TaskRecurrence.project,
        priority: TaskPriority.medium,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Đào tạo nhân viên mới',
        description: 'Chương trình đào tạo toàn diện cho nhân viên mới về quy trình và kỹ năng',
        recurrence: TaskRecurrence.project,
        priority: TaskPriority.medium,
        category: TaskCategory.operations,
      ),
      TaskTemplate(
        title: 'Chiến dịch marketing',
        description: 'Lên kế hoạch và triển khai chiến dịch marketing thu hút khách hàng mới',
        recurrence: TaskRecurrence.project,
        priority: TaskPriority.medium,
        category: TaskCategory.operations,
      ),
    ];
  }

  Future<void> _applyTemplate(TaskTemplate template) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final taskService = TaskService();
      final task = Task(
        id: '',
        branchId: widget.company.id,
        title: template.title,
        description: template.description,
        category: template.category ?? TaskCategory.operations,
        priority: template.priority,
        status: TaskStatus.todo,
        recurrence: template.recurrence,
        dueDate: _calculateDueDate(template.recurrence),
        createdBy: currentUser.id,
        createdByName: currentUser.email ?? '',
        createdAt: DateTime.now(),
      );

      await taskService.createTask(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo công việc: ${template.title}'),
            backgroundColor: Colors.green,
          ),
        );

        // Switch to tasks tab
        _tabController.animateTo(0);

        ref.invalidate(companyTasksProvider(widget.companyId));
        ref.invalidate(companyTaskStatsProvider(widget.companyId));
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

  DateTime _calculateDueDate(TaskRecurrence recurrence) {
    final now = DateTime.now();
    switch (recurrence) {
      case TaskRecurrence.daily:
        return DateTime(now.year, now.month, now.day, 23, 59);
      case TaskRecurrence.weekly:
        return now.add(const Duration(days: 7));
      case TaskRecurrence.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case TaskRecurrence.adhoc:
        return now.add(const Duration(days: 1));
      case TaskRecurrence.project:
        return now.add(const Duration(days: 30));
      default:
        return now.add(const Duration(days: 7));
    }
  }

  void _showCreateTaskDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateTaskDialog(companyId: widget.companyId),
    );

    if (result == true && mounted) {
      ref.invalidate(companyTasksProvider(widget.companyId));
      ref.invalidate(companyTaskStatsProvider(widget.companyId));
    }
  }

  void _showEditTaskDialog(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditTaskDialog(task: task),
    );

    if (result == true && mounted) {
      ref.invalidate(companyTasksProvider(widget.companyId));
      ref.invalidate(companyTaskStatsProvider(widget.companyId));
    }
  }

  void _showTaskDetails(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );

    if (result == true && mounted) {
      ref.invalidate(companyTasksProvider(widget.companyId));
      ref.invalidate(companyTaskStatsProvider(widget.companyId));
    }
  }

  Future<void> _deleteTask(Task task) async {
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
      final taskService = TaskService();
      await taskService.deleteTask(task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa công việc'), backgroundColor: Colors.green),
        );

        ref.invalidate(companyTasksProvider(widget.companyId));
        ref.invalidate(companyTaskStatsProvider(widget.companyId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
