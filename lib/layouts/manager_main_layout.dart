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
import '../widgets/error_boundary.dart';
import '../widgets/grouped_navigation_drawer.dart';
import '../widgets/unified_bottom_navigation.dart';
import '../widgets/realtime_notification_widgets.dart';
import '../utils/app_logger.dart';

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
    final user = authState.user;
    final companyId = user?.companyId;
    final currentRoute = GoRouterState.of(context).uri.path;

    // 🔥 DEBUG: Log why this layout is shown instead of DistributionManagerLayout
    AppLogger.box('⚠️ SABO ManagerLayout SHOWN', {
      'userName': user?.name ?? 'null',
      'role': user?.role.toString() ?? 'null',
      'businessType': user?.businessType?.toString() ?? '❌ NULL',
      'companyName': user?.companyName ?? 'null',
      'companyId': user?.companyId ?? 'null',
    });

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SABOHUB Manager'),
          actions: const [
            RealtimeNotificationBell(),
          ],
        ),
        drawer: GroupedNavigationDrawer(
          userRole: UserRole.manager,
          currentRoute: currentRoute,
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
                const ManagerStaffPage(),
              ],
            ),
            // 🔥 DEBUG BANNER - Shows why wrong layout is displayed
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.9),
                child: Text(
                  '⚠️ DEBUG: businessType = ${user?.businessType?.toString() ?? "NULL"} | '
                  'Expected: distribution for Odori',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
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
