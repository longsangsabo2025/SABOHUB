import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/management_task_provider.dart';
import '../../widgets/task/task_board.dart';

// =============================================================================
// STAFF TASKS PAGE — Single TaskBoard, no tabs needed
// Shows tasks assigned to me, can update status only
// =============================================================================

class StaffTasksPage extends ConsumerWidget {
  const StaffTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nhiệm vụ',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(managerAssignedTasksProvider),
          ),
        ],
      ),
      body: TaskBoard(config: TaskBoardConfig.staff()),
    );
  }
}
