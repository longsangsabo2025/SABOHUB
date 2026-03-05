import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/odori_providers.dart';
import '../../models/odori_sales_order.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Manager Dashboard Page with Role Switcher
/// Dashboard tổng quan cho Manager với khả năng chuyển đổi vai trò
class ManagerDashboardPage extends ConsumerWidget {
  const ManagerDashboardPage({super.key});

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
              data: (stats) => _buildQuickStats(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorWidget(context, 
                'Lỗi tải thống kê',
                '$e',
                () {
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(recentOrdersProvider);
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Revenue Summary
            statsAsync.when(
              data: (stats) => _buildRevenueSummary(context, stats, currencyFormat),
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
              data: (orders) => _buildRecentOrders(context, orders, currencyFormat),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorWidget(context, 
                'Lỗi tải đơn hàng',
                '$e',
                () {
                  ref.invalidate(recentOrdersProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, OdoriDashboardStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(context, 'Đơn chờ xử lý', '${stats.pendingOrders}', Icons.shopping_cart, Colors.blue),
        _buildStatCard(context, 'Đang giao', '${stats.inProgressDeliveries}', Icons.local_shipping, Colors.orange),
        _buildStatCard(context, 'Hoàn thành', '${stats.completedOrdersToday}', Icons.check_circle, Colors.green),
        _buildStatCard(context, 'Khách hàng', '${stats.totalCustomers}', Icons.people, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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

  Widget _buildRevenueSummary(BuildContext context, OdoriDashboardStats stats, NumberFormat currencyFormat) {
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
              Icon(Icons.trending_up, color: Theme.of(context).colorScheme.surface, size: 20),
              SizedBox(width: 8),
              Text('Doanh số hôm nay', style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(stats.todaySales),
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
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
                        SizedBox(width: 4),
                        Text('Đã thu', style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11)),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      currencyFormat.format(stats.todayRevenue),
                      style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 14, fontWeight: FontWeight.w600),
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
                        SizedBox(width: 4),
                        Text('Chưa thu', style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 11)),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      currencyFormat.format(unpaidToday),
                      style: TextStyle(
                        color: unpaidToday > 0 ? Colors.orange.shade200 : Theme.of(context).colorScheme.surface,
                        fontSize: 14, 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          // Divider
          Container(
            height: 1,
            color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          
          // Month summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tháng này: ${currencyFormat.format(stats.monthSales)}',
                style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 12),
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

  Widget _buildRecentOrders(BuildContext context, List<OdoriSalesOrder> orders, NumberFormat currencyFormat) {
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
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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

  Widget _buildErrorWidget(BuildContext context, String title, String detail, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
