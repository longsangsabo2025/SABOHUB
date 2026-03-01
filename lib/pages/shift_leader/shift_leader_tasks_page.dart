import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../providers/task_provider.dart';

class ShiftLeaderTasksPage extends ConsumerStatefulWidget {
  const ShiftLeaderTasksPage({super.key});
  @override
  ConsumerState<ShiftLeaderTasksPage> createState() =>
      _ShiftLeaderTasksPageState();
}

class _ShiftLeaderTasksPageState extends ConsumerState<ShiftLeaderTasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskStatus _selectedStatus = TaskStatus.todo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedStatus = [
            TaskStatus.todo,
            TaskStatus.inProgress,
            TaskStatus.completed,
            TaskStatus.cancelled
          ][_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Quản lý nhiệm vụ',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(tasksByStatusProvider);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('🔄 Đã làm mới'),
                  backgroundColor: AppColors.primary));
            },
            icon: const Icon(Icons.refresh, color: Colors.black54),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Chờ xử lý'),
                Tab(text: 'Đang làm'),
                Tab(text: 'Hoàn thành'),
                Tab(text: 'Hủy bỏ')
              ],
            ),
          ),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasksAsync = ref.watch(
        tasksByStatusProvider((status: _selectedStatus, branchId: null)));
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(tasksByStatusProvider),
      child: tasksAsync.when(
        data: (tasks) => tasks.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (_, i) => _buildCard(tasks[i]),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: ElevatedButton(
                onPressed: () => ref.invalidate(tasksByStatusProvider),
                child: const Text('Thử lại'))),
      ),
    );
  }

  Widget _buildEmpty() {
    final msgs = [
      'Không có việc chờ',
      'Không có việc đang làm',
      'Chưa hoàn thành việc nào',
      'Không có việc bị hủy'
    ];
    return Center(
        child: Text(msgs[_tabController.index],
            style: TextStyle(color: Colors.grey.shade500)));
  }

  Widget _buildCard(Task t) {
    final pc = [
      AppColors.error,
      AppColors.warning,
      AppColors.info,
      AppColors.success
    ][t.priority.index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pc.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _showDetail(t),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                          color: pc, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(
                            [
                              'Vận hành',
                              'Bảo trì',
                              'Kho',
                              'CSKH',
                              'Khác'
                            ][t.category.index],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (t.status != TaskStatus.completed &&
                      t.status != TaskStatus.cancelled)
                    _buildMenu(t),
                ],
              ),
              if (t.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(t.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(t.dueDate != null ? DateFormat('dd/MM HH:mm').format(t.dueDate!) : 'Chưa có',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(Task t) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'edit') return _showEditDialog(t);
        if (v == 'delete') return _confirmDelete(t);
        final s = {
          'start': TaskStatus.inProgress,
          'done': TaskStatus.completed,
          'cancel': TaskStatus.cancelled
        }[v]!;
        await ref.read(taskServiceProvider).updateTaskStatus(t.id, s);
        ref.invalidate(tasksByStatusProvider);
        ref.invalidate(taskStatsProvider);
      },
      itemBuilder: (_) => [
        if (t.status == TaskStatus.todo)
          const PopupMenuItem(value: 'start', child: Text('Bắt đầu')),
        if (t.status == TaskStatus.inProgress)
          const PopupMenuItem(value: 'done', child: Text('Hoàn thành')),
        const PopupMenuItem(value: 'edit', child: Text('Sửa')),
        const PopupMenuItem(value: 'cancel', child: Text('Hủy')),
        const PopupMenuItem(value: 'delete', child: Text('Xóa')),
      ],
    );
  }

  void _showDetail(Task t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Trạng thái: ${['Chờ', 'Làm', 'Xong', 'Hủy'][t.status.index]}'),
            Text('Ưu tiên: ${['Khẩn', 'Cao', 'TB', 'Thấp'][t.priority.index]}'),
            if (t.description.isNotEmpty) Text('Mô tả: ${t.description}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'))
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final tc = TextEditingController();
    final dc = TextEditingController();
    var p = TaskPriority.medium;
    var c = TaskCategory.operations;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Tạo việc mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: tc,
                    decoration: const InputDecoration(labelText: 'Tiêu đề')),
                TextField(
                    controller: dc,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 2),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: p,
                  items: TaskPriority.values
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(['Khẩn', 'Cao', 'TB', 'Thấp'][e.index])))
                      .toList(),
                  onChanged: (v) => setState(() => p = v!),
                ),
                DropdownButtonFormField<TaskCategory>(
                  initialValue: c,
                  items: TaskCategory.values
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text([
                            'Vận hành',
                            'Bảo trì',
                            'Kho',
                            'CSKH',
                            'Khác'
                          ][e.index])))
                      .toList(),
                  onChanged: (v) => setState(() => c = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                
                final task = Task(
                  id: '',
                  branchId: '',
                  title: tc.text,
                  description: dc.text.isEmpty ? '' : dc.text,
                  category: c,
                  priority: p,
                  status: TaskStatus.todo,
                  createdBy: '',
                  createdByName: '',
                  dueDate: DateTime.now(),
                  createdAt: DateTime.now(),
                );
                await ref.read(taskServiceProvider).createTask(task);
                if (!mounted) return;
                navigator.pop();
                ref.invalidate(tasksByStatusProvider);
                ref.invalidate(taskStatsProvider);
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Task t) {
    final tc = TextEditingController(text: t.title);
    final dc = TextEditingController(text: t.description);
    var p = t.priority;
    var c = t.category;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Sửa việc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: tc,
                    decoration: const InputDecoration(labelText: 'Tiêu đề')),
                TextField(
                    controller: dc,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                    maxLines: 2),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: p,
                  items: TaskPriority.values
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(['Khẩn', 'Cao', 'TB', 'Thấp'][e.index])))
                      .toList(),
                  onChanged: (v) => setState(() => p = v!),
                ),
                DropdownButtonFormField<TaskCategory>(
                  initialValue: c,
                  items: TaskCategory.values
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text([
                            'Vận hành',
                            'Bảo trì',
                            'Kho',
                            'CSKH',
                            'Khác'
                          ][e.index])))
                      .toList(),
                  onChanged: (v) => setState(() => c = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                
                final updates = <String, dynamic>{
                  'title': tc.text,
                  'description': dc.text.isEmpty ? null : dc.text,
                  'priority': p.name,
                  'category': c.name,
                };
                await ref.read(taskServiceProvider).updateTask(t.id, updates);
                if (!mounted) return;
                navigator.pop();
                ref.invalidate(tasksByStatusProvider);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Task t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa "${t.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(taskServiceProvider).deleteTask(t.id);
              if (mounted) {
                Navigator.pop(context);
                ref.invalidate(tasksByStatusProvider);
                ref.invalidate(taskStatsProvider);
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

