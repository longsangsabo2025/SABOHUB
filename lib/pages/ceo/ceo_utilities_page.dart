import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/keys/ceo_keys.dart';

import 'ai_management/ai_management_dashboard.dart';
import 'ceo_documents_page.dart';
import '../travis/travis_chat_tab.dart';
import '../../features/gym_agent/widgets/gym_coach_tab.dart';
import '../../features/coaching/pages/coaching_page.dart';

/// CEO Utilities Page — Gom: Tài liệu + AI Center
/// Các tiện ích hỗ trợ CEO
class CEOUtilitiesPage extends ConsumerStatefulWidget {
  const CEOUtilitiesPage({super.key});

  @override
  ConsumerState<CEOUtilitiesPage> createState() => _CEOUtilitiesPageState();
}

class _CEOUtilitiesPageState extends ConsumerState<CEOUtilitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          'Tiện ích',
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
              icon: Icon(Icons.folder_rounded, size: 20),
              text: 'Tài liệu',
            ),
            Tab(
              icon: Icon(Icons.psychology_rounded, size: 20),
              text: 'AI Center',
            ),
            Tab(
              icon: Icon(Icons.smart_toy_rounded, size: 20),
              text: 'Travis AI',
            ),
            Tab(
              icon: Icon(Icons.fitness_center_rounded, size: 20),
              text: 'Gym Coach',
            ),
            Tab(
              icon: Icon(Icons.self_improvement_rounded, size: 20),
              text: 'Self Coach',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Tab 1: Quản lý tài liệu
          CEODocumentsPage(),
          // Tab 2: AI hỗ trợ
          AIManagementDashboard(),
          // Tab 3: Travis AI Chat
          TravisChatTab(),
          // Tab 4: Gym Coach AI
          GymCoachTab(),
          // Tab 5: Self-Improvement Coaching
          CoachingPage(),
        ],
      ),
    );
  }
}
