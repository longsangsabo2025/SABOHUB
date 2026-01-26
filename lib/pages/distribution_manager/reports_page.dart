// Extracted from distribution_manager_layout.dart
// Reports Page with revenue overview and quick reports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/odori_providers.dart';

// ==================== REPORTS PAGE ====================
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue overview
          const Text('Doanh thu tháng này', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng doanh thu', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(stats.monthRevenue),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hôm nay: ${currencyFormat.format(stats.todayRevenue)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
          ),
          const SizedBox(height: 24),
          
          // Quick reports
          const Text('Tổng quan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildReportCard('Khách hàng', '${stats.activeCustomers}', Icons.people, Colors.blue),
                _buildReportCard('Sản phẩm', '${stats.totalProducts}', Icons.inventory, Colors.orange),
                _buildReportCard('Công nợ', currencyFormat.format(stats.totalReceivables), Icons.account_balance_wallet, Colors.purple),
                _buildReportCard('Quá hạn', currencyFormat.format(stats.overdueReceivables), Icons.warning, Colors.red),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi: $e'),
          ),
          
          const SizedBox(height: 24),
          
          // Additional Reports Section
          const Text('Báo cáo chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildReportOption(
            context,
            'Báo cáo doanh thu',
            'Phân tích doanh thu theo ngày/tuần/tháng',
            Icons.trending_up,
            Colors.green,
            () => _showComingSoon(context),
          ),
          _buildReportOption(
            context,
            'Báo cáo công nợ',
            'Chi tiết công nợ theo khách hàng',
            Icons.account_balance,
            Colors.orange,
            () => _showComingSoon(context),
          ),
          _buildReportOption(
            context,
            'Báo cáo tồn kho',
            'Tồn kho và xuất nhập',
            Icons.inventory_2,
            Colors.blue,
            () => _showComingSoon(context),
          ),
          _buildReportOption(
            context,
            'Báo cáo đơn hàng',
            'Thống kê đơn hàng theo trạng thái',
            Icons.receipt_long,
            Colors.purple,
            () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang được phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
