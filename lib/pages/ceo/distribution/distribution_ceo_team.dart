import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../ceo_tasks_page.dart';
import '../ceo_employees_page.dart';

/// Distribution CEO Team Tab — Employees + Tasks in one view
class DistributionCEOTeam extends ConsumerStatefulWidget {
  const DistributionCEOTeam({super.key});

  @override
  ConsumerState<DistributionCEOTeam> createState() =>
      _DistributionCEOTeamState();
}

class _DistributionCEOTeamState extends ConsumerState<DistributionCEOTeam>
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
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: 'Công việc'),
              Tab(icon: Icon(Icons.people), text: 'Nhân viên'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CEOTasksPage(),
              CEOEmployeesPage(),
            ],
          ),
        ),
      ],
    );
  }
}
