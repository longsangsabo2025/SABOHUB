import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/odori_providers.dart';
import '../../models/odori_sales_order.dart';

/// Manager Dashboard Page with Role Switcher
/// Dashboard tổng quan cho Manager với khả năng chuyển đổi vai trò
class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

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
