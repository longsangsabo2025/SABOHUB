import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../pages/manager/manager_analytics_page.dart';
import '../pages/manager/manager_attendance_page.dart';
import '../pages/manager/manager_companies_page.dart';
import '../pages/manager/manager_dashboard_page.dart';
import '../pages/manager/manager_staff_page.dart';
import '../pages/manager/manager_tasks_page.dart';
import '../widgets/dev_role_switcher.dart';
import '../widgets/quick_account_switcher.dart';
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
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: const [
              ManagerDashboardPage(),
              ManagerCompaniesPage(),
              ManagerTasksPage(),
              ManagerAttendancePage(),
              ManagerAnalyticsPage(),
              ManagerStaffPage(),
            ],
          ),
          // DEV: Role Switcher Button
          const DevRoleSwitcher(),
        ],
      ),
      bottomNavigationBar: UnifiedBottomNavigation(
        userRole: UserRole.manager,
        currentIndex: _currentPageIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
