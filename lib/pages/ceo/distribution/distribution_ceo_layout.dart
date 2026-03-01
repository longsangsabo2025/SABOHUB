import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../ceo_profile_page.dart';
import '../ceo_notifications_page.dart';
import '../shared/ceo_more_page.dart';

// Distribution-specific tabs
import 'distribution_ceo_dashboard.dart';
import 'distribution_ceo_sales.dart';
import 'distribution_ceo_operations.dart';
import 'distribution_ceo_finance.dart';
import 'distribution_ceo_team.dart';

/// Distribution CEO Layout — 5 tabs focused on distribution business
/// Dashboard | Kinh doanh | Vận hành | Tài chính | Đội ngũ
class DistributionCEOLayout extends ConsumerStatefulWidget {
  const DistributionCEOLayout({super.key});

  @override
  ConsumerState<DistributionCEOLayout> createState() =>
      _DistributionCEOLayoutState();
}

class _DistributionCEOLayoutState
    extends ConsumerState<DistributionCEOLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DistributionCEODashboard(),
    DistributionCEOSales(),
    DistributionCEOOperations(),
    DistributionCEOFinance(),
    DistributionCEOTeam(),
  ];

  void _onTabSelected(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyName = user?.companyName ?? 'Công ty';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              'Phân phối',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          const RealtimeNotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOProfilePage()));
                  break;
                case 'notifications':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CEONotificationsPage()));
                  break;
                case 'more':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOMorePage()));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: ListTile(
                dense: true,
                leading: Icon(Icons.person_outline),
                title: Text('Hồ sơ cá nhân'),
              )),
              PopupMenuItem(value: 'notifications', child: ListTile(
                dense: true,
                leading: Icon(Icons.notifications_outlined),
                title: Text('Thông báo'),
              )),
              PopupMenuItem(value: 'more', child: ListTile(
                dense: true,
                leading: Icon(Icons.apps),
                title: Text('Thêm (Công ty, Tài liệu, AI...)'),
              )),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart, color: AppColors.primary),
            label: 'Kinh doanh',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
            label: 'Vận hành',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance, color: AppColors.primary),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Đội ngũ',
          ),
        ],
      ),
    );
  }
}
