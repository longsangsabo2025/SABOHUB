import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../pages/common/company_info_page.dart';
import '../pages/shift_leader/shift_leader_reports_page.dart';
import '../pages/shift_leader/shift_leader_tasks_page.dart';
import '../pages/shift_leader/shift_leader_team_page.dart';
import '../pages/staff/staff_checkin_page.dart';
import '../pages/staff/staff_messages_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_boundary.dart';
import '../widgets/unified_bottom_navigation.dart';

/// Shift Leader Main Layout
/// Complete layout with navigation for shift leader role
class ShiftLeaderMainLayout extends ConsumerStatefulWidget {
  const ShiftLeaderMainLayout({super.key});

  @override
  ConsumerState<ShiftLeaderMainLayout> createState() =>
      _ShiftLeaderMainLayoutState();
}

class _ShiftLeaderMainLayoutState extends ConsumerState<ShiftLeaderMainLayout>
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
    final currentUser = ref.watch(currentUserProvider);
    final companyId = currentUser?.companyId;

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
                // 1. Tasks Page
                ShiftLeaderTasksPage(),
                // 2. Check-in Page (reuse from Staff)
                const StaffCheckinPage(),
                // 3. Messages Page (reuse from Staff)
                const StaffMessagesPage(),
                // 4. Team Management Page
                ShiftLeaderTeamPage(),
                // 5. Reports Page
                ShiftLeaderReportsPage(),
                // 6. Company Info Page
                companyId != null
                    ? CompanyInfoPage(companyId: companyId)
                    : const Center(
                        child: Text('Bạn chưa được gán vào công ty nào'),
                      ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: UnifiedBottomNavigation(
          userRole: UserRole.shiftLeader,
          currentIndex: _currentPageIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }
}
