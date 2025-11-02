import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/management_task_provider.dart';

/// Debug button to manually refresh CEO Analytics data
class RefreshDataButton extends ConsumerWidget {
  const RefreshDataButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        // Invalidate all providers to force refresh
        ref.invalidate(companyTaskStatisticsProvider);
        ref.invalidate(ceoStrategicTasksProvider);
        ref.invalidate(taskStatisticsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Đã làm mới dữ liệu!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      icon: const Icon(Icons.refresh),
      label: const Text('Làm mới'),
      backgroundColor: Colors.green,
    );
  }
}
