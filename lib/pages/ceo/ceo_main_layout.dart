import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/navigation_models.dart';
import '../../widgets/grouped_navigation_drawer.dart';
import '../../widgets/error_boundary.dart';
import 'ceo_dashboard_page.dart';
import 'ceo_management_page.dart';
import 'ceo_finance_page.dart';
import 'ceo_utilities_page.dart';

import '../../core/keys/ceo_keys.dart';

/// Global key for CEO Main Layout to access navigation from anywhere
final ceoMainLayoutKey = GlobalKey<_CEOMainLayoutState>();

/// CEO Main Layout with Bottom Navigation
class CEOMainLayout extends ConsumerStatefulWidget {
  const CEOMainLayout({super.key});

  @override
  ConsumerState<CEOMainLayout> createState() => _CEOMainLayoutState();
}

class _CEOMainLayoutState extends ConsumerState<CEOMainLayout> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // ── SIMPLIFIED: 4 tabs instead of 7 ──
  // Tổng quan | Quản lý | Tài chính | Tiện ích
  final List<Widget> _pages = const [
    CEODashboardPage(),    // Tổng quan: KPIs, Pulse, Quick Actions
    CEOManagementPage(),   // Quản lý: Công ty + Công việc
    CEOFinancePage(),      // Tài chính: Phân tích + Báo cáo
    CEOUtilitiesPage(),    // Tiện ích: Tài liệu + AI Center
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Public method to navigate to a specific tab from anywhere
  void navigateToTab(int index) {
    _onTabSelected(index);
  }

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return ErrorBoundary(
      child: Scaffold(
        key: ceoScaffoldKey,
        drawer: GroupedNavigationDrawer(
          userRole: UserRole.ceo,
          currentRoute: currentRoute,
        ),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _pages,
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabSelected,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.info,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_center_rounded),
          label: 'Quản lý',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_rounded),
          label: 'Tài chính',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps_rounded),
          label: 'Tiện ích',
        ),
      ],
    );
  }
}
