import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
// Entertainment pages
import '../pages/tables/table_list_page.dart';
import '../pages/sessions/session_list_page.dart';
import '../pages/menu/menu_list_page.dart';

/// Entertainment Manager Layout
/// Layout cho Manager loại hình giải trí (billiards, restaurant, cafe, hotel, retail)
/// Tabs: Tổng quan, Bàn/Phòng, Phiên chơi, Thực đơn
class EntertainmentManagerLayout extends ConsumerStatefulWidget {
  const EntertainmentManagerLayout({super.key});

  @override
  ConsumerState<EntertainmentManagerLayout> createState() =>
      _EntertainmentManagerLayoutState();
}

class _EntertainmentManagerLayoutState
    extends ConsumerState<EntertainmentManagerLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Quản lý';
    final companyName = authState.user?.companyName ?? 'Giải trí';
    final businessType = authState.user?.businessType;

    final pages = <Widget>[
      _EntertainmentDashboardPage(businessType: businessType?.label ?? 'Giải trí'),
      const TableListPage(),
      const SessionListPage(),
      const MenuListPage(),
    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tổng quan',
      ),
      NavigationDestination(
        icon: const Icon(Icons.table_bar_outlined),
        selectedIcon: const Icon(Icons.table_bar),
        label: businessType?.label == 'Khách Sạn' ? 'Phòng' : 'Bàn',
      ),
      const NavigationDestination(
        icon: Icon(Icons.timer_outlined),
        selectedIcon: Icon(Icons.timer),
        label: 'Phiên',
      ),
      const NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Thực đơn',
      ),
    ];

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  businessType?.icon ?? Icons.sports_bar,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '🎱 Quản lý - $userName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã làm mới dữ liệu'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showProfileMenu(context, ref),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: destinations,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Hồ sơ cá nhân'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report_outlined, color: Colors.red.shade400),
              title: const Text('Báo cáo lỗi'),
              onTap: () {
                Navigator.pop(ctx);
                BugReportDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.sports_bar, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Giải Trí',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quản lý cơ sở giải trí',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'Nhân viên',
            onTap: () {
              Navigator.pop(context);
              context.push('/employees/list');
            },
          ),
          _buildDrawerItem(
            icon: Icons.schedule_outlined,
            title: 'Lịch làm việc',
            onTap: () {
              Navigator.pop(context);
              // Schedules
            },
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart_outlined,
            title: 'Báo cáo',
            onTap: () {
              Navigator.pop(context);
              context.push('/manager-reports');
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.person_outline,
            title: 'Hồ sơ cá nhân',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt công ty',
            onTap: () {
              Navigator.pop(context);
              context.push('/company/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

/// Entertainment Dashboard - Tổng quan giải trí
class _EntertainmentDashboardPage extends StatelessWidget {
  final String businessType;

  const _EntertainmentDashboardPage({required this.businessType});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎱 Dashboard $businessType',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tổng quan hoạt động kinh doanh',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.table_bar,
                title: 'Bàn',
                subtitle: 'Quản lý bàn/phòng',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.timer,
                title: 'Phiên',
                subtitle: 'Phiên đang hoạt động',
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.restaurant_menu,
                title: 'Thực đơn',
                subtitle: 'Món ăn & đồ uống',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.attach_money,
                title: 'Doanh thu',
                subtitle: 'Hôm nay',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
