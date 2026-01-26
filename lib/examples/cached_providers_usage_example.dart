/// Example: Using Cached Providers with Pull-to-Refresh
/// This shows how to use the new cached providers system in Manager Dashboard
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/management_task.dart';
import '../providers/cached_providers.dart';
import '../utils/pull_to_refresh.dart';

/// Example Manager Tasks Tab using cached providers
class ExampleManagerTasksTab extends ConsumerWidget {
  const ExampleManagerTasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cached assigned tasks provider
    final tasksAsync = ref.watch(cachedManagerAssignedTasksProvider);
    
    return RefreshableListView<ManagementTask>(
      dataProvider: tasksAsync,
      itemBuilder: (context, task, index) => _TaskCard(task: task),
      onRefresh: () => refreshManagerAssignedTasks(ref),
      emptyBuilder: (context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có công việc nào',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
      separator: const Divider(height: 1),
      padding: const EdgeInsets.all(16),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ManagementTask task;
  
  const _TaskCard({required this.task});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text(task.title),
        subtitle: Text(task.description ?? 'Không có mô tả'),
        trailing: _buildProgressIndicator(),
      ),
    );
  }
  
  Widget _buildStatusIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.schedule, color: Colors.white),
        );
      case TaskStatus.inProgress:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.play_arrow, color: Colors.white),
        );
      case TaskStatus.completed:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          child: Icon(Icons.task),
        );
    }
  }
  
  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${task.progress}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: task.progress / 100),
        ],
      ),
    );
  }
}

/// Example: Dashboard Stats using cached providers
class ExampleDashboardStats extends ConsumerWidget {
  const ExampleDashboardStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(cachedManagerDashboardKPIsProvider);
    
    return kpisAsync.when(
      data: (kpis) => _buildStatsGrid(kpis),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text('Lỗi: $error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(cachedManagerDashboardKPIsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsGrid(Map<String, dynamic> kpis) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: 'Tổng công việc',
          value: '${kpis['total_assigned'] ?? 0}',
          icon: Icons.task,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Đang chờ',
          value: '${kpis['pending'] ?? 0}',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _StatCard(
          title: 'Đang thực hiện',
          value: '${kpis['in_progress'] ?? 0}',
          icon: Icons.play_arrow,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Hoàn thành',
          value: '${kpis['completed'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Quá hạn',
          value: '${kpis['overdue'] ?? 0}',
          icon: Icons.warning,
          color: Colors.red,
        ),
        _StatCard(
          title: 'Tỷ lệ HT',
          value: '${kpis['completion_rate'] ?? 0}%',
          icon: Icons.analytics,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Using Realtime with Auto-refresh
class ExampleRealtimeTasks extends ConsumerWidget {
  const ExampleRealtimeTasks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable realtime listener - will auto-refresh when data changes
    ref.watch(taskChangeListenerProvider);
    
    // Watch cached data (will be invalidated by realtime listener)
    final tasksAsync = ref.watch(cachedManagerAssignedTasksProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refreshAssignedTasks(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshManagerAssignedTasks(ref);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: AsyncValueUI<List<ManagementTask>>(
          value: tasksAsync,
          builder: (tasks) => ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
          ),
          onRetry: () => ref.invalidate(cachedManagerAssignedTasksProvider),
        ),
      ),
    );
  }
}

/// Example: Refresh all manager data on screen init
class ExampleFullDashboard extends ConsumerStatefulWidget {
  const ExampleFullDashboard({super.key});

  @override
  ConsumerState<ExampleFullDashboard> createState() => _ExampleFullDashboardState();
}

class _ExampleFullDashboardState extends ConsumerState<ExampleFullDashboard> {
  @override
  void initState() {
    super.initState();
    // Enable realtime listener
    ref.read(taskChangeListenerProvider);
  }
  
  Future<void> _handleRefresh() async {
    // Refresh all manager data at once
    refreshAllManagerData(ref);
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Stats Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: ExampleDashboardStats(),
              ),
              
              // Tasks Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Công việc được giao',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ExampleManagerTasksTab(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
