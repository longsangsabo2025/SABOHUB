import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/management_task_provider.dart';
import '../../widgets/task/task_board.dart';

// =============================================================================
// MANAGER TASKS PAGE — Lean, 2-tab design (Từ CEO | Đã giao)
// Uses unified TaskBoard widget — zero duplicated card/dialog code
// =============================================================================

class ManagerTasksPage extends ConsumerStatefulWidget {
  const ManagerTasksPage({super.key});

  @override
  ConsumerState<ManagerTasksPage> createState() => _ManagerTasksPageState();
}

class _ManagerTasksPageState extends ConsumerState<ManagerTasksPage>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Công việc',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Làm mới',
            onPressed: () => refreshAllTasks(ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Từ CEO'),
            Tab(text: 'Đã giao'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tasks assigned to me by CEO
          TaskBoard(config: TaskBoardConfig.managerAssigned()),
          // Tab 2: Tasks I created & assigned to staff
          TaskBoard(
            config: TaskBoardConfig.managerCreated(
              loadAssignees: () async {
                final service = ref.read(managementTaskServiceProvider);
                return service.getManagers(); // Get staff members
              },
            ),
          ),
        ],
      ),
    );
  }
}
