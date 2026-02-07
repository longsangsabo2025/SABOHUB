import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
// Manufacturing pages
import '../pages/manufacturing/suppliers_page.dart';
import '../pages/manufacturing/materials_page.dart';
import '../pages/manufacturing/bom_page.dart';
import '../pages/manufacturing/purchase_orders_page.dart';
import '../pages/manufacturing/production_orders_page.dart';
import '../pages/manufacturing/payables_page.dart';

/// Manufacturing Manager Layout
/// Layout cho Manager của công ty sản xuất
/// Tabs: Dashboard, Sản xuất, Nguyên liệu, Mua hàng, Công nợ
class ManufacturingManagerLayout extends ConsumerStatefulWidget {
  const ManufacturingManagerLayout({super.key});

  @override
  ConsumerState<ManufacturingManagerLayout> createState() =>
      _ManufacturingManagerLayoutState();
}

class _ManufacturingManagerLayoutState
    extends ConsumerState<ManufacturingManagerLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Quản lý';
    final companyName = authState.user?.companyName ?? 'Sản xuất';

    final pages = <Widget>[
      const _ManufacturingDashboardPage(),
      const ProductionOrdersPage(),
      const MaterialsPage(),
      const PurchaseOrdersPage(),
      const PayablesPage(),
    ];

    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tổng quan',
      ),
      NavigationDestination(
        icon: Icon(Icons.precision_manufacturing_outlined),
        selectedIcon: Icon(Icons.precision_manufacturing),
        label: 'Sản xuất',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_outlined),
        selectedIcon: Icon(Icons.inventory),
        label: 'Nguyên liệu',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined),
        selectedIcon: Icon(Icons.shopping_cart),
        label: 'Mua hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet),
        label: 'Công nợ',
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
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.factory, color: Colors.green, size: 20),
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
                      '🏭 Quản lý - $userName',
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
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.factory, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text(
                  'Sản Xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Quản lý sản xuất',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Manufacturing-specific drawer items
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'Nhà cung cấp',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuppliersPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long_outlined,
            title: 'Định mức BOM',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BOMPage()),
              );
            },
          ),
          const Divider(),
          // Shared navigation items
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

/// Manufacturing Dashboard - Tổng quan sản xuất
class _ManufacturingDashboardPage extends ConsumerWidget {
  const _ManufacturingDashboardPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
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
                  colors: [Colors.green.shade700, Colors.green.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏭 Dashboard Sản Xuất',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tổng quan hoạt động sản xuất',
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
                  icon: Icons.precision_manufacturing,
                  title: 'Lệnh SX',
                  subtitle: 'Đang thực hiện',
                  color: Colors.blue,
                ),
                _buildStatCard(
                  icon: Icons.inventory,
                  title: 'Nguyên liệu',
                  subtitle: 'Quản lý tồn kho',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.shopping_cart,
                  title: 'Đơn mua',
                  subtitle: 'Nhập hàng',
                  color: Colors.purple,
                ),
                _buildStatCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Công nợ',
                  subtitle: 'Phải trả NCC',
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'Thao tác nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo lệnh SX'),
                  onPressed: () {
                    // Navigate to production order form
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Đặt mua NL'),
                  onPressed: () {
                    // Navigate to purchase order form
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Xem BOM'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BOMPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
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
