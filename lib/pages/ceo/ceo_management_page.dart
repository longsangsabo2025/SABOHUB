import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/keys/ceo_keys.dart';

import 'ceo_companies_page.dart';
import 'ceo_tasks_page.dart';

/// CEO Management Page — Gom: Công ty + Công việc
/// Đơn giản hóa navigation: 1 tab chứa 2 sub-tabs
class CEOManagementPage extends ConsumerStatefulWidget {
  const CEOManagementPage({super.key});

  @override
  ConsumerState<CEOManagementPage> createState() => _CEOManagementPageState();
}

class _CEOManagementPageState extends ConsumerState<CEOManagementPage>
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
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ceoScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Quản lý',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(
              icon: Icon(Icons.business_rounded, size: 20),
              text: 'Công ty',
            ),
            Tab(
              icon: Icon(Icons.assignment_rounded, size: 20),
              text: 'Công việc',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Quản lý công ty con
          CEOCompaniesPage(),
          // Tab 2: Công việc & Phê duyệt
          CEOTasksPage(),
        ],
      ),
    );
  }
}
