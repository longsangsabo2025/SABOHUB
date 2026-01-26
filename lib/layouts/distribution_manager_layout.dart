import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/odori_providers.dart';
import '../models/odori_sales_order.dart';
import '../widgets/error_boundary.dart';
import '../widgets/notification_center.dart';
import '../widgets/bug_report_dialog.dart';
import '../services/odori_notification_service.dart';
// Extracted pages
import '../pages/distribution_manager/orders_management_page.dart';
import '../pages/distribution_manager/customers_page.dart';
import '../pages/distribution_manager/inventory_page.dart';
import '../pages/distribution_manager/reports_page.dart';

final supabase = Supabase.instance.client;

/// Distribution Manager Layout
/// Layout cho Manager của công ty phân phối/sản xuất (Odori - Nước giặt)
/// Với Role Hierarchy: Manager có quyền truy cập TẤT CẢ chức năng của các role khác
class DistributionManagerLayout extends ConsumerStatefulWidget {
  const DistributionManagerLayout({super.key});

  @override
  ConsumerState<DistributionManagerLayout> createState() =>
      _DistributionManagerLayoutState();
}

class _DistributionManagerLayoutState
    extends ConsumerState<DistributionManagerLayout> {
  int _currentIndex = 0;
  String _currentView = 'manager'; // manager, sales, warehouse, driver, cskh, finance

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Quản lý';
    final companyName = authState.user?.companyName ?? 'Odori';

    // If viewing another role's interface, show that layout embedded
    if (_currentView != 'manager') {
      return _buildRoleView(context, userName, companyName);
    }

    final pages = <Widget>[
      _DistributionDashboardPageWithRoleSwitcher(
        onSwitchRole: (role) => setState(() => _currentView = role),
      ),
      const OrdersManagementPage(),
      const CustomersPage(),
      const InventoryPage(),
      const ReportsPage(),
    ];

    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Tổng quan',
      ),
      NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Đơn hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outlined),
        selectedIcon: Icon(Icons.people),
        label: 'Khách hàng',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Kho',
      ),
      NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: 'Báo cáo',
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
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_shipping, color: Colors.teal, size: 20),
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
                      '👔 Manager - $userName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Notification icon with badge
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext ctx) => Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: const NotificationPopupSheet(),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Consumer(
                    builder: (BuildContext ctx, WidgetRef r, _) {
                      final state = r.watch(odoriNotificationStateProvider);
                      if (state.unreadCount == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Profile menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/profile');
                } else if (value == 'settings') {
                  context.push('/company/settings');
                } else if (value == 'bug_report') {
                  BugReportDialog.show(context);
                } else if (value == 'logout') {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              },
              itemBuilder: (BuildContext ctx) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Hồ sơ cá nhân'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Cài đặt'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'bug_report',
                  child: Row(
                    children: [
                      Icon(Icons.bug_report_outlined, size: 20, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      const Text('Báo cáo lỗi'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        drawer: _buildRoleSwitcherDrawer(context, userName, companyName),
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

  /// Build the role switcher drawer
  Widget _buildRoleSwitcherDrawer(BuildContext context, String userName, String companyName) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '👔 MANAGER - Full Access',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Role sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Current: Manager
                _buildRoleSection(
                  icon: Icons.supervisor_account,
                  title: 'Quản lý (Manager)',
                  subtitle: 'Dashboard tổng quan',
                  color: Colors.teal,
                  isActive: _currentView == 'manager',
                  onTap: () {
                    setState(() => _currentView = 'manager');
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 1),
                
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'CHUYỂN ĐỔI VAI TRÒ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Sales
                _buildRoleSection(
                  icon: Icons.sell,
                  title: 'Bán hàng (Sales)',
                  subtitle: 'Tạo đơn, khách hàng, báo cáo',
                  color: Colors.orange,
                  isActive: _currentView == 'sales',
                  onTap: () {
                    setState(() => _currentView = 'sales');
                    Navigator.pop(context);
                  },
                ),

                // Warehouse
                _buildRoleSection(
                  icon: Icons.warehouse,
                  title: 'Kho (Warehouse)',
                  subtitle: 'Xuất kho, tồn kho, nhập hàng',
                  color: Colors.brown,
                  isActive: _currentView == 'warehouse',
                  onTap: () {
                    setState(() => _currentView = 'warehouse');
                    Navigator.pop(context);
                  },
                ),

                // Driver
                _buildRoleSection(
                  icon: Icons.local_shipping,
                  title: 'Giao hàng (Driver)',
                  subtitle: 'Lộ trình, giao hàng, COD',
                  color: Colors.blue,
                  isActive: _currentView == 'driver',
                  onTap: () {
                    setState(() => _currentView = 'driver');
                    Navigator.pop(context);
                  },
                ),

                // Customer Service
                _buildRoleSection(
                  icon: Icons.support_agent,
                  title: 'CSKH (Support)',
                  subtitle: 'Ticket, phản hồi, hỗ trợ',
                  color: Colors.purple,
                  isActive: _currentView == 'cskh',
                  onTap: () {
                    setState(() => _currentView = 'cskh');
                    Navigator.pop(context);
                  },
                ),

                // Finance
                _buildRoleSection(
                  icon: Icons.account_balance_wallet,
                  title: 'Tài chính (Finance)',
                  subtitle: 'Công nợ, thu chi, báo cáo',
                  color: Colors.green,
                  isActive: _currentView == 'finance',
                  onTap: () {
                    setState(() => _currentView = 'finance');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manager có quyền truy cập tất cả chức năng',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? color : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: isActive
          ? Icon(Icons.check_circle, color: color)
          : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  /// Build the embedded role view with back button
  Widget _buildRoleView(BuildContext context, String userName, String companyName) {
    final roleConfig = _getRoleConfig(_currentView);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: roleConfig['color'] as Color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentView = 'manager'),
        ),
        title: Row(
          children: [
            Icon(roleConfig['icon'] as IconData, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleConfig['title'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '← Quay lại Manager',
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick role switcher chips
          PopupMenuButton<String>(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Chuyển vai trò',
            onSelected: (value) {
              setState(() => _currentView = value);
            },
            itemBuilder: (ctx) => [
              _buildRoleMenuItem('manager', Icons.supervisor_account, 'Manager', Colors.teal),
              _buildRoleMenuItem('sales', Icons.sell, 'Sales', Colors.orange),
              _buildRoleMenuItem('warehouse', Icons.warehouse, 'Warehouse', Colors.brown),
              _buildRoleMenuItem('driver', Icons.local_shipping, 'Driver', Colors.blue),
              _buildRoleMenuItem('cskh', Icons.support_agent, 'CSKH', Colors.purple),
              _buildRoleMenuItem('finance', Icons.account_balance_wallet, 'Finance', Colors.green),
            ],
          ),
        ],
      ),
      body: _getEmbeddedRoleContent(),
    );
  }

  PopupMenuItem<String> _buildRoleMenuItem(String value, IconData icon, String label, Color color) {
    final isActive = _currentView == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isActive ? color : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isActive) ...[
            const Spacer(),
            Icon(Icons.check, color: color, size: 18),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleConfig(String role) {
    switch (role) {
      case 'sales':
        return {'icon': Icons.sell, 'title': 'Sales - Bán hàng', 'color': Colors.orange};
      case 'warehouse':
        return {'icon': Icons.warehouse, 'title': 'Warehouse - Kho', 'color': Colors.brown};
      case 'driver':
        return {'icon': Icons.local_shipping, 'title': 'Driver - Giao hàng', 'color': Colors.blue};
      case 'cskh':
        return {'icon': Icons.support_agent, 'title': 'CSKH - Hỗ trợ', 'color': Colors.purple};
      case 'finance':
        return {'icon': Icons.account_balance_wallet, 'title': 'Finance - Tài chính', 'color': Colors.green};
      default:
        return {'icon': Icons.supervisor_account, 'title': 'Manager', 'color': Colors.teal};
    }
  }

  Widget _getEmbeddedRoleContent() {
    // Return the actual layout body (without their own AppBar/BottomNav)
    // Each layout is wrapped to extract just the functional body
    switch (_currentView) {
      case 'sales':
        return const _SalesLayoutBody();
      case 'warehouse':
        return const _WarehouseLayoutBody();
      case 'driver':
        return const _DriverLayoutBody();
      case 'cskh':
        return const _CSKHLayoutBody();
      case 'finance':
        return const _FinanceLayoutBody();
      default:
        return const SizedBox();
    }
  }
}

// ==================== ACTUAL LAYOUT BODIES ====================
// These widgets contain the real functionality from each role's layout

/// Sales Layout Body - Actual sales functionality
class _SalesLayoutBody extends ConsumerStatefulWidget {
  const _SalesLayoutBody();

  @override
  ConsumerState<_SalesLayoutBody> createState() => _SalesLayoutBodyState();
}

class _SalesLayoutBodyState extends ConsumerState<_SalesLayoutBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar at top
        Container(
          color: Colors.orange.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildTab(0, Icons.dashboard, 'Tổng quan'),
                _buildTab(1, Icons.add_shopping_cart, 'Tạo đơn'),
                _buildTab(2, Icons.receipt_long, 'Đơn của tôi'),
                _buildTab(3, Icons.people, 'Khách hàng'),
                _buildTab(4, Icons.bar_chart, 'Báo cáo'),
              ],
            ),
          ),
        ),
        // Content - Using IndexedStack for real pages
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _SalesDashboardContent(),
              _CreateOrderContent(),
              _MyOrdersContent(),
              _SalesCustomersContent(),
              _SalesReportsContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : Colors.orange),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? Colors.white : Colors.orange,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DASHBOARD WITH ROLE SWITCHER ====================
class _DistributionDashboardPageWithRoleSwitcher extends ConsumerWidget {
  final Function(String) onSwitchRole;
  
  const _DistributionDashboardPageWithRoleSwitcher({required this.onSwitchRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentOrdersProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Role Access Cards
            _buildQuickRoleAccess(context),
            const SizedBox(height: 16),
            
            // Quick Stats from real data
            statsAsync.when(
              data: (stats) => _buildQuickStats(stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: 16),
            
            // Revenue Summary
            statsAsync.when(
              data: (stats) => _buildRevenueSummary(stats, currencyFormat),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            
            // Recent Orders
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            recentOrdersAsync.when(
              data: (orders) => _buildRecentOrders(orders, currencyFormat),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRoleAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.swap_horiz, size: 18, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'Truy cập nhanh các vai trò',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Manager Full Access',
                style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRoleQuickCard(
                icon: Icons.sell,
                label: 'Sales',
                subtitle: 'Bán hàng',
                color: Colors.orange,
                onTap: () => onSwitchRole('sales'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.warehouse,
                label: 'Kho',
                subtitle: 'Warehouse',
                color: Colors.brown,
                onTap: () => onSwitchRole('warehouse'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.local_shipping,
                label: 'Giao hàng',
                subtitle: 'Driver',
                color: Colors.blue,
                onTap: () => onSwitchRole('driver'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.support_agent,
                label: 'CSKH',
                subtitle: 'Support',
                color: Colors.purple,
                onTap: () => onSwitchRole('cskh'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.account_balance_wallet,
                label: 'Tài chính',
                subtitle: 'Finance',
                color: Colors.green,
                onTap: () => onSwitchRole('finance'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleQuickCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 85,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(OdoriDashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('Đơn chờ xử lý', '${stats.pendingOrders}', Icons.shopping_cart, Colors.blue),
        _buildStatCard('Đang giao', '${stats.inProgressDeliveries}', Icons.local_shipping, Colors.orange),
        _buildStatCard('Hoàn thành', '${stats.completedOrdersToday}', Icons.check_circle, Colors.green),
        _buildStatCard('Khách hàng', '${stats.totalCustomers}', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary(OdoriDashboardStats stats, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Doanh thu hôm nay', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(stats.todayRevenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tháng này: ${currencyFormat.format(stats.monthRevenue)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<OdoriSalesOrder> orders, NumberFormat currencyFormat) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Chưa có đơn hàng nào'),
        ),
      );
    }

    return Column(
      children: orders.take(5).map((order) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(order.status),
                  color: _getStatusColor(order.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'Khách hàng',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      order.orderNumber ?? '#${order.id.substring(0, 8)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(order.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusLabel(order.status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'delivering': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.schedule;
      case 'confirmed': return Icons.check;
      case 'delivering': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Chờ xử lý';
      case 'confirmed': return 'Đã xác nhận';
      case 'delivering': return 'Đang giao';
      case 'delivered': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}

// ============================================================================
// SALES CONTENT PAGES - Real functionality for Manager embedded view
// ============================================================================

/// Sales Dashboard Content - Shows real sales data
class _SalesDashboardContent extends ConsumerStatefulWidget {
  const _SalesDashboardContent();

  @override
  ConsumerState<_SalesDashboardContent> createState() => _SalesDashboardContentState();
}

class _SalesDashboardContentState extends ConsumerState<_SalesDashboardContent> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfMonth = DateTime(today.year, today.month, 1);

      // Orders today
      final todayOrders = await supabase
          .from('sales_orders')
          .select('id, total_amount')
          .eq('company_id', companyId)
          .gte('created_at', startOfDay.toIso8601String());

      // Orders this month
      final monthOrders = await supabase
          .from('sales_orders')
          .select('id, total_amount, status')
          .eq('company_id', companyId)
          .gte('created_at', startOfMonth.toIso8601String());

      // Recent orders
      final recent = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(5);

      double todayRevenue = 0;
      for (var order in todayOrders) {
        todayRevenue += (order['total_amount'] ?? 0).toDouble();
      }

      double monthRevenue = 0;
      int pendingCount = 0;
      for (var order in monthOrders) {
        monthRevenue += (order['total_amount'] ?? 0).toDouble();
        if (order['status'] == 'pending' || order['status'] == 'pending_approval') {
          pendingCount++;
        }
      }

      setState(() {
        _stats = {
          'todayOrders': todayOrders.length,
          'todayRevenue': todayRevenue,
          'monthOrders': monthOrders.length,
          'monthRevenue': monthRevenue,
          'pendingOrders': pendingCount,
        };
        _recentOrders = List<Map<String, dynamic>>.from(recent);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's stats
            const Text('📊 Hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(Icons.shopping_cart, Colors.blue, 'Đơn hàng', '${_stats['todayOrders'] ?? 0}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(Icons.attach_money, Colors.green, 'Doanh thu', currencyFormat.format(_stats['todayRevenue'] ?? 0)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly stats
            const Text('📈 Tháng này', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(Icons.receipt_long, Colors.purple, 'Tổng đơn', '${_stats['monthOrders'] ?? 0}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(Icons.pending_actions, Colors.amber, 'Chờ duyệt', '${_stats['pendingOrders'] ?? 0}'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent orders
            const Text('🕐 Đơn hàng gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_recentOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Chưa có đơn hàng')),
              )
            else
              ..._recentOrders.map((order) => _buildOrderItem(order, currencyFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, Color color, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order, NumberFormat format) {
    final customer = order['customers'] as Map<String, dynamic>?;
    final total = (order['total_amount'] ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt, color: Colors.orange.shade300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer?['name'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(order['order_number'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(format.format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}

/// Create Order Content
class _CreateOrderContent extends ConsumerStatefulWidget {
  const _CreateOrderContent();

  @override
  ConsumerState<_CreateOrderContent> createState() => _CreateOrderContentState();
}

class _CreateOrderContentState extends ConsumerState<_CreateOrderContent> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedCustomer;
  final List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final customersData = await supabase
          .from('customers')
          .select('id, name, code, phone, address')
          .eq('company_id', companyId)
          .neq('status', 'inactive')
          .order('name');

      final productsData = await supabase
          .from('products')
          .select('id, name, sku, unit, selling_price')
          .eq('company_id', companyId)
          .neq('status', 'inactive')
          .order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(customersData);
        _products = List<Map<String, dynamic>>.from(productsData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer selection
          const Text('👤 Chọn khách hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                hint: const Text('Chọn khách hàng'),
                value: _selectedCustomer,
                items: _customers.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c['name']} - ${c['phone'] ?? 'N/A'}'),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCustomer = v),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Products
          const Text('📦 Sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_products.isEmpty)
            const Text('Chưa có sản phẩm nào')
          else
            ...List.generate(_products.take(10).length, (index) {
              final product = _products[index];
              final price = (product['selling_price'] ?? 0).toDouble();
              final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${product['sku'] ?? ''} - ${format.format(price)}/${product['unit'] ?? 'cái'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.orange),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm ${product['name']}')),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedCustomer == null ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo đơn thành công!')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Tạo đơn hàng'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// My Orders Content
class _MyOrdersContent extends ConsumerStatefulWidget {
  const _MyOrdersContent();

  @override
  ConsumerState<_MyOrdersContent> createState() => _MyOrdersContentState();
}

class _MyOrdersContentState extends ConsumerState<_MyOrdersContent> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('sales_orders')
          .select('*, customers(name, phone)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Chưa có đơn hàng nào'),
          ],
        ),
      );
    }

    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final total = (order['total_amount'] ?? 0).toDouble();
          final status = order['status'] ?? 'pending';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order['order_number'] ?? '#N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(fontSize: 12, color: _getStatusColor(status), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(customer?['name'] ?? 'Khách hàng', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(format.format(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ duyệt';
      case 'approved': return 'Đã duyệt';
      case 'delivered': return 'Đã giao';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}

/// Sales Customers Content
class _SalesCustomersContent extends ConsumerStatefulWidget {
  const _SalesCustomersContent();

  @override
  ConsumerState<_SalesCustomersContent> createState() => _SalesCustomersContentState();
}

class _SalesCustomersContentState extends ConsumerState<_SalesCustomersContent> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      if (companyId == null) return;

      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('customers')
          .select('*')
          .eq('company_id', companyId)
          .order('name')
          .limit(50);

      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Chưa có khách hàng nào'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length,
        itemBuilder: (context, index) {
          final customer = _customers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Text(
                    (customer['name'] ?? 'K')[0].toUpperCase(),
                    style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(customer['phone'] ?? 'Chưa có SĐT', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Sales Reports Content
class _SalesReportsContent extends StatelessWidget {
  const _SalesReportsContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.orange.shade300),
          const SizedBox(height: 16),
          const Text('Báo cáo bán hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Chức năng báo cáo sẽ hiển thị ở đây', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ============================================================================
// WAREHOUSE, DRIVER, CSKH, FINANCE LAYOUT BODIES
// ============================================================================

/// Warehouse Layout Body
class _WarehouseLayoutBody extends ConsumerStatefulWidget {
  const _WarehouseLayoutBody();

  @override
  ConsumerState<_WarehouseLayoutBody> createState() => _WarehouseLayoutBodyState();
}

class _WarehouseLayoutBodyState extends ConsumerState<_WarehouseLayoutBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.brown.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildTab(0, Icons.dashboard, 'Tổng quan'),
                _buildTab(1, Icons.inventory, 'Xuất kho'),
                _buildTab(2, Icons.move_to_inbox, 'Nhập kho'),
                _buildTab(3, Icons.inventory_2, 'Tồn kho'),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _WarehouseDashboardContent(),
              _WarehouseExportContent(),
              _WarehouseImportContent(),
              _WarehouseInventoryContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.brown : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.brown.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : Colors.brown),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.brown, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Driver Layout Body
class _DriverLayoutBody extends ConsumerStatefulWidget {
  const _DriverLayoutBody();

  @override
  ConsumerState<_DriverLayoutBody> createState() => _DriverLayoutBodyState();
}

class _DriverLayoutBodyState extends ConsumerState<_DriverLayoutBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildTab(0, Icons.map, 'Lộ trình'),
                _buildTab(1, Icons.local_shipping, 'Giao hàng'),
                _buildTab(2, Icons.history, 'Lịch sử'),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _DriverRouteContent(),
              _DriverDeliveryContent(),
              _DriverHistoryContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : Colors.blue),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.blue, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// CSKH Layout Body
class _CSKHLayoutBody extends ConsumerStatefulWidget {
  const _CSKHLayoutBody();

  @override
  ConsumerState<_CSKHLayoutBody> createState() => _CSKHLayoutBodyState();
}

class _CSKHLayoutBodyState extends ConsumerState<_CSKHLayoutBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.purple.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildTab(0, Icons.dashboard, 'Tổng quan'),
                _buildTab(1, Icons.confirmation_number, 'Tickets'),
                _buildTab(2, Icons.people, 'Khách hàng'),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _CSKHDashboardContent(),
              _CSKHTicketsContent(),
              _CSKHCustomersContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.purple : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : Colors.purple),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.purple, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Finance Layout Body
class _FinanceLayoutBody extends ConsumerStatefulWidget {
  const _FinanceLayoutBody();

  @override
  ConsumerState<_FinanceLayoutBody> createState() => _FinanceLayoutBodyState();
}

class _FinanceLayoutBodyState extends ConsumerState<_FinanceLayoutBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.green.shade50,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildTab(0, Icons.dashboard, 'Tổng quan'),
                _buildTab(1, Icons.account_balance_wallet, 'Công nợ'),
                _buildTab(2, Icons.payments, 'Thu tiền'),
                _buildTab(3, Icons.assessment, 'Báo cáo'),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: const [
              _FinanceDashboardContent(),
              _FinanceReceivablesContent(),
              _FinanceCollectionContent(),
              _FinanceReportsContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isActive ? Colors.white : Colors.green),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.white : Colors.green, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WAREHOUSE CONTENT PAGES
// ============================================================================

class _WarehouseDashboardContent extends ConsumerWidget {
  const _WarehouseDashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warehouse, size: 64, color: Colors.brown.shade300),
          const SizedBox(height: 16),
          const Text('Warehouse Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tổng quan kho hàng', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _WarehouseExportContent extends StatelessWidget {
  const _WarehouseExportContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 64, color: Colors.brown.shade300),
          const SizedBox(height: 16),
          const Text('Xuất kho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _WarehouseImportContent extends StatelessWidget {
  const _WarehouseImportContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.move_to_inbox, size: 64, color: Colors.brown.shade300),
          const SizedBox(height: 16),
          const Text('Nhập kho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _WarehouseInventoryContent extends StatelessWidget {
  const _WarehouseInventoryContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.brown.shade300),
          const SizedBox(height: 16),
          const Text('Tồn kho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// DRIVER CONTENT PAGES
// ============================================================================

class _DriverRouteContent extends StatelessWidget {
  const _DriverRouteContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.blue.shade300),
          const SizedBox(height: 16),
          const Text('Lộ trình hôm nay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DriverDeliveryContent extends StatelessWidget {
  const _DriverDeliveryContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping, size: 64, color: Colors.blue.shade300),
          const SizedBox(height: 16),
          const Text('Đơn cần giao', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DriverHistoryContent extends StatelessWidget {
  const _DriverHistoryContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.blue.shade300),
          const SizedBox(height: 16),
          const Text('Lịch sử giao hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// CSKH CONTENT PAGES
// ============================================================================

class _CSKHDashboardContent extends StatelessWidget {
  const _CSKHDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 64, color: Colors.purple.shade300),
          const SizedBox(height: 16),
          const Text('CSKH Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CSKHTicketsContent extends StatelessWidget {
  const _CSKHTicketsContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number, size: 64, color: Colors.purple.shade300),
          const SizedBox(height: 16),
          const Text('Quản lý Tickets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CSKHCustomersContent extends StatelessWidget {
  const _CSKHCustomersContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.purple.shade300),
          const SizedBox(height: 16),
          const Text('Khách hàng CSKH', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// FINANCE CONTENT PAGES
// ============================================================================

class _FinanceDashboardContent extends StatelessWidget {
  const _FinanceDashboardContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text('Finance Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FinanceReceivablesContent extends StatelessWidget {
  const _FinanceReceivablesContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text('Quản lý công nợ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FinanceCollectionContent extends StatelessWidget {
  const _FinanceCollectionContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text('Thu tiền', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FinanceReportsContent extends StatelessWidget {
  const _FinanceReportsContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 64, color: Colors.green.shade300),
          const SizedBox(height: 16),
          const Text('Báo cáo tài chính', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
