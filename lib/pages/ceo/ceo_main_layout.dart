import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/navigation_models.dart';
import '../../widgets/grouped_navigation_drawer.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/realtime_notification_widgets.dart';
import 'ai_management/ai_management_dashboard.dart';
import 'ceo_analytics_page.dart';
import 'ceo_companies_page.dart';
import 'ceo_dashboard_page.dart';
import 'ceo_reports_settings_page.dart';
import 'ceo_tasks_page.dart';
import 'ceo_documents_page.dart';

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

  final List<Widget> _pages = const [
    CEODashboardPage(),
    CEOTasksPage(),
    CEOCompaniesPage(),
    CEODocumentsPage(),
    CEOAnalyticsPage(),
    CEOReportsPage(),
    AIManagementDashboard(),
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
        appBar: AppBar(
          title: const Text('SABOHUB CEO'),
          actions: [
            const RealtimeNotificationBell(),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // TODO: Show profile
              },
            ),
          ],
        ),
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
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Công việc',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Công ty',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: 'Tài liệu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Phân tích',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Báo cáo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology),
          label: 'AI Center',
        ),
      ],
    );
  }
}
