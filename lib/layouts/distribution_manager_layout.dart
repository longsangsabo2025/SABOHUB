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
import '../services/employee_auth_service.dart';
// Extracted pages
import '../pages/distribution_manager/orders_management_page.dart';
import '../pages/distribution_manager/customers_page.dart';
import '../pages/distribution_manager/inventory_page.dart';
import '../pages/distribution_manager/reports_page.dart';
import '../pages/distribution_manager/referrers_page.dart';
// Distribution-specific layouts
import 'distribution_warehouse_layout.dart';
import '../pages/driver/distribution_driver_layout_refactored.dart';
import 'distribution_finance_layout.dart';
import 'distribution_customer_service_layout.dart';

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Quản lý';
    final companyName = authState.user?.companyName ?? 'Odori';

    final pages = <Widget>[
      const _DistributionDashboardPageWithRoleSwitcher(),
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
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                setState(() {});
                // Refresh current page data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã làm mới dữ liệu'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
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
            // Profile menu with simple approach
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showProfileMenu(context, ref);
              },
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

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => Container(
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
            // TODO: Tạm ẩn Cài đặt - uncomment khi cần
            // ListTile(
            //   leading: const Icon(Icons.settings_outlined),
            //   title: const Text('Cài đặt'),
            //   onTap: () {
            //     Navigator.pop(ctx);
            //     context.push('/company/settings');
            //   },
            // ),
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

  /// Switch to employee role by auto-login and navigate to their layout
  /// Hardcoded accounts: driver1, ketoan1
  Future<void> _switchToRole(BuildContext context, WidgetRef ref, String role) async {
    debugPrint('🔄 [SWITCH ROLE] Starting switch to role: $role');
    
    // Hardcoded accounts with passwords for testing
    // Employee login uses: companyName, username, password
    final accountMap = {
      'driver': {
        'company': 'Odori',
        'username': 'driver1',
        'password': 'Odori@2026',
      },
      'finance': {
        'company': 'Odori', 
        'username': 'ketoan1',
        'password': 'Odori@2026',
      },
    };

    final account = accountMap[role];
    if (account == null) {
      debugPrint('❌ [SWITCH ROLE] Account not found for role: $role');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy tài khoản cho role "$role"')),
      );
      return;
    }

    debugPrint('📧 [SWITCH ROLE] Will login with: ${account['username']}@${account['company']}');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Đang chuyển sang ${role == 'driver' ? 'Tài xế' : 'Kế toán'}...'),
            ],
          ),
        ),
      ),
    );

    try {
      debugPrint('🔐 [SWITCH ROLE] Calling EmployeeAuthService.login()...');
      
      // Use EmployeeAuthService for employee login
      final employeeAuthService = EmployeeAuthService();
      final result = await employeeAuthService.login(
        companyName: account['company']!,
        username: account['username']!,
        password: account['password']!,
      );

      debugPrint('✅ [SWITCH ROLE] Login result: success=${result.success}, error=${result.error}');

      if (!context.mounted) {
        debugPrint('⚠️ [SWITCH ROLE] Context not mounted after login');
        return;
      }
      Navigator.of(context).pop(); // Close loading dialog

      if (result.success && result.employee != null) {
        debugPrint('👤 [SWITCH ROLE] Employee: ${result.employee!.fullName}, role: ${result.employee!.role}');
        
        // Convert to User and update auth state
        final user = result.employee!.toUser();
        debugPrint('🔄 [SWITCH ROLE] Calling loginWithUser...');
        await ref.read(authProvider.notifier).loginWithUser(user);
        debugPrint('✅ [SWITCH ROLE] Auth state updated!');
        
        // Navigate directly to the appropriate layout
        if (role == 'driver') {
          debugPrint('🚚 [SWITCH ROLE] Navigating to DistributionDriverLayout...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DistributionDriverLayout()),
          );
        } else if (role == 'finance') {
          debugPrint('💰 [SWITCH ROLE] Navigating to DistributionFinanceLayout...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DistributionFinanceLayout()),
          );
        }
      } else {
        debugPrint('❌ [SWITCH ROLE] Login failed: ${result.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${result.error ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('💥 [SWITCH ROLE] Exception: $e');
      debugPrint('💥 [SWITCH ROLE] Stack: $stack');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                  isActive: true,
                  onTap: () {
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

                // Warehouse - TẠM ẨN
                // _buildRoleSection(
                //   icon: Icons.warehouse,
                //   title: 'Kho (Warehouse)',
                //   subtitle: 'Xuất kho, tồn kho, nhập hàng',
                //   color: Colors.brown,
                //   isActive: false,
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => const DistributionWarehouseLayout(),
                //       ),
                //     );
                //   },
                // ),

                // Driver - Login vào tài khoản driver
                _buildRoleSection(
                  icon: Icons.local_shipping,
                  title: 'Giao hàng (Driver)',
                  subtitle: 'Lộ trình, giao hàng, COD',
                  color: Colors.blue,
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    _switchToRole(context, ref, 'driver');
                  },
                ),

                // Customer Service - TẠM ẨN
                // _buildRoleSection(
                //   icon: Icons.support_agent,
                //   title: 'CSKH (Support)',
                //   subtitle: 'Ticket, phản hồi, hỗ trợ',
                //   color: Colors.purple,
                //   isActive: false,
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => const DistributionCustomerServiceLayout(),
                //       ),
                //     );
                //   },
                // ),

                // Finance - Login vào tài khoản finance
                _buildRoleSection(
                  icon: Icons.account_balance_wallet,
                  title: 'Tài chính (Finance)',
                  subtitle: 'Công nợ, thu chi, báo cáo',
                  color: Colors.green,
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    _switchToRole(context, ref, 'finance');
                  },
                ),

                const Divider(height: 1),
                
                // Section header - Quản lý khác
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'QUẢN LÝ KHÁC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Referrers - Người giới thiệu
                _buildRoleSection(
                  icon: Icons.person_add_alt_1,
                  title: 'Người giới thiệu',
                  subtitle: 'Hoa hồng, CTV giới thiệu',
                  color: Colors.orange,
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReferrersPage(),
                      ),
                    );
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
}

// ==================== DASHBOARD WITH ROLE SWITCHER ====================
class _DistributionDashboardPageWithRoleSwitcher extends ConsumerWidget {
  const _DistributionDashboardPageWithRoleSwitcher();

  void _switchRole(BuildContext context, String role) {
    debugPrint('🔄 [ROLE SWITCH] _switchRole called with role: $role');
    debugPrint('🔄 [ROLE SWITCH] Context mounted: ${context.mounted}');
    
    try {
      switch (role) {
        case 'warehouse':
          debugPrint('🔄 [ROLE SWITCH] Navigating to /warehouse via GoRouter...');
          context.go('/warehouse');
          break;
        case 'driver':
          debugPrint('🔄 [ROLE SWITCH] Navigating to /driver via GoRouter...');
          context.go('/driver');
          break;
        case 'finance':
          debugPrint('🔄 [ROLE SWITCH] Navigating to /finance via GoRouter...');
          context.go('/finance');
          break;
        case 'support':
          debugPrint('🔄 [ROLE SWITCH] Navigating to /support via GoRouter...');
          context.go('/support');
          break;
        default:
          debugPrint('❌ [ROLE SWITCH] Unknown role: $role');
      }
      debugPrint('🔄 [ROLE SWITCH] Navigation completed');
    } catch (e, stackTrace) {
      debugPrint('❌ [ROLE SWITCH] Error: $e');
      debugPrint('❌ [ROLE SWITCH] StackTrace: $stackTrace');
    }
  }

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
            // TODO: Tính năng chuyển role - tạm ẩn, sẽ bật sau
            // Quick Role Access Cards
            // _buildQuickRoleAccess(context),
            // const SizedBox(height: 16),
            
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
                icon: Icons.warehouse,
                label: 'Kho',
                subtitle: 'Warehouse',
                color: Colors.brown,
                onTap: () => _switchRole(context, 'warehouse'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.local_shipping,
                label: 'Giao hàng',
                subtitle: 'Driver',
                color: Colors.blue,
                onTap: () => _switchRole(context, 'driver'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.support_agent,
                label: 'CSKH',
                subtitle: 'Support',
                color: Colors.purple,
                onTap: () => _switchRole(context, 'support'),
              ),
              const SizedBox(width: 10),
              _buildRoleQuickCard(
                icon: Icons.account_balance_wallet,
                label: 'Tài chính',
                subtitle: 'Finance',
                color: Colors.green,
                onTap: () => _switchRole(context, 'finance'),
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
        onTap: () {
          debugPrint('👆 [TAP] Role card tapped: $label ($subtitle)');
          onTap();
        },
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
    final unpaidToday = stats.todaySales - stats.todayRevenue;
    final unpaidMonth = stats.monthSales - stats.monthRevenue;
    
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
          // Main: Total Sales Today
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Doanh số hôm nay', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(stats.todaySales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Row: Collected + Pending
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade200, size: 14),
                        const SizedBox(width: 4),
                        const Text('Đã thu', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(stats.todayRevenue),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange.shade200, size: 14),
                        const SizedBox(width: 4),
                        const Text('Chưa thu', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(unpaidToday),
                      style: TextStyle(
                        color: unpaidToday > 0 ? Colors.orange.shade200 : Colors.white,
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          
          // Month summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tháng này: ${currencyFormat.format(stats.monthSales)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (unpaidMonth > 0)
                Text(
                  '(chưa thu: ${currencyFormat.format(unpaidMonth)})',
                  style: TextStyle(color: Colors.orange.shade200, fontSize: 11),
                ),
            ],
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
                      order.orderNumber,
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