import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../pages/manager/manager_analytics_page.dart';
import '../pages/manager/manager_attendance_page.dart';
import '../pages/manager/manager_company_info_page.dart';
import '../pages/manager/manager_dashboard_page.dart';
import '../pages/manager/manager_staff_page.dart';
import '../pages/manager/manager_tasks_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_boundary.dart';
import '../widgets/unified_bottom_navigation.dart';

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
    final authState = ref.watch(authProvider);
    final companyId = authState.user?.companyId;

    return ErrorBoundary(
      child: Scaffold(
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
                const ManagerStaffPage(),
              ],
            ),
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
