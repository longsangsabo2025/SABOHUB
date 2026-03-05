import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/notification_center.dart';
import '../../../widgets/bug_report_dialog.dart';
import '../services/odori_notification_service.dart';
// Extracted pages
import '../pages/manager/orders_management_page.dart';
import '../pages/manager/customers_page.dart';
import '../pages/manager/inventory_page.dart';
import '../pages/manager/reports_page.dart';
import '../pages/manager/referrers_page.dart';
import '../../../utils/app_logger.dart';
// Distribution-specific layouts
import 'distribution_warehouse_layout.dart';
import 'distribution_finance_layout.dart';
import '../pages/driver/distribution_driver_layout_refactored.dart';
// Extracted sub-pages
import 'manager/manager_dashboard_page.dart';
// Quick Actions navigation targets
import '../../../pages/manager/manager_tasks_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

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
  bool _showQuickActions = false; // Tạm tắt — dùng cho ServiceManagerLayout (SABO)

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.name ?? 'Quản lý';
    final companyName = currentUser?.companyName ?? 'Odori';

    final pages = <Widget>[
      const ManagerDashboardPage(),
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
      child: Stack(
        children: [
          Scaffold(
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
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
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                          style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 10),
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
          // Quick Actions Overlay
          if (_showQuickActions)
            _buildQuickActionsOverlay(context, userName),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // QUICK ACTIONS OVERLAY — shown once per session on first login
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildQuickActionsOverlay(BuildContext context, String userName) {
    return Material(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $userName! 👋',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bạn muốn làm gì đầu tiên hôm nay?',
                          style: TextStyle(color: Theme.of(context).colorScheme.surface60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.surface54),
                    tooltip: 'Đóng',
                    onPressed: () => setState(() => _showQuickActions = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Divider line
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.transparent],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 2x2 action grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.9,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildActionCard(
                      context,
                      icon: Icons.fingerprint_rounded,
                      title: 'Check in/out',
                      subtitle: 'Chấm công hôm nay',
                      gradientColors: [AppColors.successDark, Color(0xFF34D399)],
                      onTap: () {
                        setState(() => _showQuickActions = false);
                        context.push(AppRoutes.staffCheckin);
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.task_alt_rounded,
                      title: 'Nhiệm Vụ',
                      subtitle: 'Công việc từ CEO & team',
                      gradientColors: [AppColors.infoDark, Color(0xFF60A5FA)],
                      onTap: () {
                        setState(() => _showQuickActions = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManagerTasksPage(),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.assessment_rounded,
                      title: 'Báo cáo cuối ngày',
                      subtitle: 'Doanh thu & tổng kết',
                      gradientColors: [AppColors.warningDark, Color(0xFFFBBF24)],
                      onTap: () {
                        setState(() {
                          _showQuickActions = false;
                          _currentIndex = 4; // Reports tab
                        });
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Quản lý nhân viên',
                      subtitle: 'Danh sách & phân công',
                      gradientColors: [AppColors.primary, Color(0xFFA78BFA)],
                      onTap: () {
                        setState(() => _showQuickActions = false);
                        context.push('/employees/list');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Skip button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xFF334155)),
                    foregroundColor: Theme.of(context).colorScheme.surface60,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => setState(() => _showQuickActions = false),
                  child: const Text('Vào Dashboard →', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon badge
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 26),
              ),
              // Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
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
            // Cài đặt - chỉ CEO mới cần
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

  /// Switch to employee role — navigate to that role's layout
  /// Manager has full access so they can view any role's interface
  void _switchToRole(BuildContext context, WidgetRef ref, String role) {
    AppLogger.data('[SWITCH ROLE]', {'status': 'Starting', 'role': role});

    Widget? targetLayout;
    switch (role) {
      case 'driver':
        targetLayout = const DistributionDriverLayout();
        break;
      case 'finance':
        targetLayout = const DistributionFinanceLayout();
        break;
      case 'warehouse':
        targetLayout = const DistributionWarehouseLayout();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vai trò "$role" chưa được hỗ trợ')),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => targetLayout!),
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
                  backgroundColor: Theme.of(context).colorScheme.surface,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '👔 MANAGER - Full Access',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.surface),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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

                // Warehouse
                _buildRoleSection(
                  icon: Icons.warehouse,
                  title: 'Kho (Warehouse)',
                  subtitle: 'Xuất kho, tồn kho, nhập hàng',
                  color: Colors.brown,
                  isActive: false,
                  onTap: () {
                    Navigator.pop(context);
                    _switchToRole(context, ref, 'warehouse');
                  },
                ),

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
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Theme.of(context).colorScheme.surface : color,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? color : Theme.of(context).colorScheme.onSurface87,
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

