import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/navigation_models.dart';
import '../pages/manager/manager_analytics_page.dart';
import '../pages/manager/manager_attendance_page.dart';
import '../pages/manager/manager_company_info_page.dart';
import '../pages/manager/manager_dashboard_page.dart';
import '../pages/manager/manager_staff_page.dart';
import '../pages/manager/manager_tasks_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/company_switcher.dart';
import '../widgets/error_boundary.dart';
import '../widgets/unified_bottom_navigation.dart';
import '../widgets/realtime_notification_widgets.dart';

/// Manager Main Layout
/// Complete layout with navigation for manager role
class ManagerMainLayout extends ConsumerStatefulWidget {
  const ManagerMainLayout({super.key});

  @override
  ConsumerState<ManagerMainLayout> createState() => _ManagerMainLayoutState();
}

class _ManagerMainLayoutState extends ConsumerState<ManagerMainLayout>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId;

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý'),
          actions: [
            IconButton(
              icon: const Icon(Icons.assignment),
              tooltip: 'Báo cáo nhân viên',
              onPressed: () => context.push('/manager-reports'),
            ),
            const CompanySwitcher(),
            const SizedBox(width: 4),
            const RealtimeNotificationBell(),
            IconButton(
              icon: const Icon(Icons.person_outline),
              tooltip: 'Hồ sơ cá nhân',
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              children: [
                const ManagerDashboardPage(),
                if (companyId != null)
                  ManagerCompanyInfoPage(companyId: companyId)
                else
                  const Center(child: Text('Không tìm thấy thông tin công ty')),
                const ManagerTasksPage(),
                const ManagerAttendancePage(),
                const ManagerAnalyticsPage(),
                ManagerStaffPage(),
              ],
            ),
            // Debug banner removed - Musk fix applied 🚀
          ],
        ),
        bottomNavigationBar: UnifiedBottomNavigation(
          userRole: UserRole.manager,
          currentIndex: _currentPageIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }

}
