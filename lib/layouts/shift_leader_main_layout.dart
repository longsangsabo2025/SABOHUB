import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';
import '../pages/shift_leader/shift_leader_reports_page.dart';
import '../pages/shift_leader/shift_leader_tasks_page.dart';
import '../pages/shift_leader/shift_leader_team_page.dart';
import '../widgets/dev_role_switcher.dart';
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
            children: [
              ShiftLeaderTasksPage(),
              ShiftLeaderTeamPage(),
              ShiftLeaderReportsPage(),
            ],
          ),
          // DEV: Role Switcher Button
          const DevRoleSwitcher(),
        ],
      ),
      bottomNavigationBar: UnifiedBottomNavigation(
        userRole: UserRole.shiftLeader,
        currentIndex: _currentPageIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
