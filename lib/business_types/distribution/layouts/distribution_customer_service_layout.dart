import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/realtime_notification_widgets.dart';
import '../../../providers/auth_provider.dart';

// Extracted sub-pages
import 'cskh/cskh_dashboard_page.dart';
import 'cskh/cskh_tickets_page.dart';
import 'cskh/cskh_customers_page.dart';

/// Distribution Customer Service Layout
/// Layout cho nhân viên CSKH của công ty phân phối (Odori)
/// Handles: Customer complaints, Support tickets, Customer feedback
class DistributionCustomerServiceLayout extends ConsumerStatefulWidget {
  const DistributionCustomerServiceLayout({super.key});

  @override
  ConsumerState<DistributionCustomerServiceLayout> createState() =>
      _DistributionCustomerServiceLayoutState();
}

class _DistributionCustomerServiceLayoutState
    extends ConsumerState<DistributionCustomerServiceLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CSKHDashboardPage(),
    const CSKHTicketsPage(),
    const CSKHCustomersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'CSKH';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('CSKH - $userName'),
        actions: const [
          RealtimeNotificationBell(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Yêu cầu',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
        ],
      ),
    );
  }
}
