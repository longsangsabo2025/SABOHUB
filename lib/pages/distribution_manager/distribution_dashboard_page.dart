import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/odori_providers.dart';
import '../../models/odori_sales_order.dart';

/// Distribution Dashboard Page
/// Trang tổng quan cho Manager (không có role switcher)
class DistributionDashboardPage extends ConsumerWidget {
  const DistributionDashboardPage({super.key});

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
            // Welcome Card
            _buildWelcomeCard(context),
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

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_laundry_service, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'ODORI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống quản lý phân phối',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(OdoriDashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Chờ duyệt',
            stats.pendingOrders.toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Đang giao',
            stats.inProgressDeliveries.toString(),
            Icons.local_shipping,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Hoàn thành',
            stats.completedOrdersToday.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary(OdoriDashboardStats stats, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan tháng này', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doanh số', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(format.format(stats.monthSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (stats.monthSales > stats.monthRevenue)
                      Text('Đã thu: ${format.format(stats.monthRevenue)}', 
                        style: TextStyle(color: Colors.green.shade700, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khách hàng', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('${stats.activeCustomers}/${stats.totalCustomers}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sản phẩm', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(stats.totalProducts.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<OdoriSalesOrder> orders, NumberFormat format) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: orders.length.clamp(0, 5),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext ctx, int index) {
          final order = orders[index];
          return ListTile(
            title: Text(order.orderNumber.isNotEmpty ? order.orderNumber : 'Đơn #${order.id.substring(0, 8)}'),
            subtitle: Text(order.customerName ?? 'Khách hàng'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(format.format(order.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusChip(order.status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Đã duyệt';
        break;
      case 'processing':
        color = Colors.blue;
        label = 'Đang xử lý';
        break;
      case 'delivered':
        color = Colors.teal;
        label = 'Đã giao';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}


/// Distribution Dashboard Page with Role Switcher
/// Dashboard có thêm chức năng chuyển đổi giữa các role
class DistributionDashboardPageWithRoleSwitcher extends ConsumerWidget {
  final Function(String) onSwitchRole;
  
  const DistributionDashboardPageWithRoleSwitcher({
    super.key,
    required this.onSwitchRole,
  });

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
            // Quick role access
            _buildQuickRoleAccess(context),
            const SizedBox(height: 16),
            
            // Quick Stats
            statsAsync.when(
              data: (stats) => _buildQuickStats(stats),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
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
        const Text(
          'Truy cập nhanh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildRoleQuickCard(
                icon: Icons.sell,
                label: 'Sales',
                subtitle: 'Bán hàng',
                color: Colors.orange,
                onTap: () => onSwitchRole('sales'),
              ),
              const SizedBox(width: 12),
              _buildRoleQuickCard(
                icon: Icons.warehouse,
                label: 'Warehouse',
                subtitle: 'Kho vận',
                color: Colors.brown,
                onTap: () => onSwitchRole('warehouse'),
              ),
              const SizedBox(width: 12),
              _buildRoleQuickCard(
                icon: Icons.local_shipping,
                label: 'Driver',
                subtitle: 'Giao hàng',
                color: Colors.blue,
                onTap: () => onSwitchRole('driver'),
              ),
              const SizedBox(width: 12),
              _buildRoleQuickCard(
                icon: Icons.support_agent,
                label: 'CSKH',
                subtitle: 'Hỗ trợ',
                color: Colors.purple,
                onTap: () => onSwitchRole('cskh'),
              ),
              const SizedBox(width: 12),
              _buildRoleQuickCard(
                icon: Icons.account_balance_wallet,
                label: 'Finance',
                subtitle: 'Tài chính',
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
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(OdoriDashboardStats stats) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Chờ duyệt', stats.pendingOrders.toString(), Icons.pending_actions, Colors.orange),
        _buildStatCard('Đang giao', stats.inProgressDeliveries.toString(), Icons.local_shipping, Colors.blue),
        _buildStatCard('Hoàn thành', stats.completedOrdersToday.toString(), Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary(OdoriDashboardStats stats, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng quan tháng này', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doanh số', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(currencyFormat.format(stats.monthSales), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (stats.monthSales > stats.monthRevenue)
                      Text('Đã thu: ${currencyFormat.format(stats.monthRevenue)}', 
                        style: TextStyle(color: Colors.green.shade700, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khách hàng', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('${stats.activeCustomers}/${stats.totalCustomers}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(List<OdoriSalesOrder> orders, NumberFormat currencyFormat) {
    if (orders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: orders.take(5).map((order) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
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
            title: Text(
              order.orderNumber.isNotEmpty ? order.orderNumber : '#${order.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              order.customerName ?? 'Khách lẻ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(order.total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval': return Colors.orange;
      case 'approved': return Colors.green;
      case 'processing': return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval': return Icons.pending_actions;
      case 'approved': return Icons.check_circle_outline;
      case 'processing': return Icons.local_shipping;
      case 'delivered': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.receipt;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending_approval': return 'Chờ duyệt';
      case 'approved': return 'Đã duyệt';
      case 'processing': return 'Đang giao';
      case 'delivered': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }
}
