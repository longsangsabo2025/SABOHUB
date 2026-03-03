import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/company.dart';
import '../../../providers/cached_data_providers.dart';
import '../../../business_types/service/providers/monthly_pnl_provider.dart';
import '../../../business_types/service/models/monthly_pnl.dart';
import 'widgets/stat_card.dart';

/// Overview Tab - Hiển thị thông tin tổng quan về công ty
class OverviewTab extends ConsumerWidget {
  final Company company;
  final String companyId;

  const OverviewTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedCompanyStatsProvider(companyId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'Thống kê',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _buildStatsCards(stats),
          ),
          const SizedBox(height: 32),

          // Financial Dashboard
          _buildFinancialDashboard(ref),
          const SizedBox(height: 32),

          // Company Information
          const Text(
            'Thông tin công ty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(company),
          const SizedBox(height: 32),

          // Contact Information
          const Text(
            'Thông tin liên hệ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContactCard(context, company),
          const SizedBox(height: 32),

          // Timeline
          const Text(
            'Thời gian',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTimelineCard(company),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.people,
                label: 'Nhân viên',
                value: '${stats['employeeCount'] ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.store,
                label: 'Chi nhánh',
                value: '${stats['branchCount'] ?? 0}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.table_restaurant,
                label: 'Bàn chơi',
                value: '${stats['tableCount'] ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                icon: Icons.attach_money,
                label: 'Doanh thu/tháng',
                value: _formatCurrency(stats['monthlyRevenue'] ?? 0.0),
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(Company company) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.business,
              label: 'Tên công ty',
              value: company.name,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.category,
              label: 'Loại hình',
              value: company.type.label,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Địa chỉ',
              value: company.address.isNotEmpty
                  ? company.address
                  : 'Chưa cập nhật',
            ),
            if (company.phone != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Điện thoại',
                value: company.phone!,
              ),
            ],
            if (company.email != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: company.email!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, Company company) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (company.phone != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.green[50],
                  child: Icon(Icons.phone, color: Colors.green[700]),
                ),
                title: const Text('Gọi điện'),
                subtitle: Text(company.phone!),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _launchPhone(context, company.phone!),
                ),
              ),
            if (company.phone != null && company.email != null)
              const Divider(height: 24),
            if (company.email != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.email, color: Colors.blue[700]),
                ),
                title: const Text('Gửi email'),
                subtitle: Text(company.email!),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _launchEmail(context, company.email!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Company company) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Ngày tạo',
              value: company.createdAt != null
                  ? dateFormat.format(company.createdAt!)
                  : 'N/A',
            ),
            if (company.updatedAt != null) ...[
              const Divider(height: 32),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Cập nhật cuối',
                value: dateFormat.format(company.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String _formatCompactCurrency(double amount) {
    if (amount.abs() >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}tỷ';
    } else if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  // ── Financial Dashboard Widget ──
  Widget _buildFinancialDashboard(WidgetRef ref) {
    final summaryAsync = ref.watch(financialSummaryProvider(companyId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, size: 20, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              'Báo cáo tài chính',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Live',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        summaryAsync.when(
          loading: () => Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (e, _) => Card(
            elevation: 0,
            color: Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400]),
                  const SizedBox(width: 12),
                  Text('Lỗi tải dữ liệu tài chính', style: TextStyle(color: Colors.red[700])),
                ],
              ),
            ),
          ),
          data: (summary) {
            if (summary['hasData'] != true) {
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, size: 32, color: Colors.grey[400]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Chưa có dữ liệu tài chính',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final records = summary['records'] as List<MonthlyPnl>;
            final latestRevenue = summary['latestNetRevenue'] as double;
            final latestProfit = summary['latestNetProfit'] as double;
            final latestMargin = summary['latestNetMargin'] as double;
            final growthPct = summary['revenueGrowthPct'] as double;
            final totalRevenue12m = summary['totalRevenue12m'] as double;
            final totalProfit12m = summary['totalProfit12m'] as double;
            final latestMonth = summary['latestMonth'] as String;
            final isProfitable = summary['isProfitable'] as bool;

            return Column(
              children: [
                // Latest month summary card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isProfitable
                            ? [Colors.green[50]!, Colors.green[100]!]
                            : [Colors.red[50]!, Colors.red[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isProfitable ? Colors.green[200]! : Colors.red[200]!,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Tháng $latestMonth',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Spacer(),
                            if (growthPct != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: growthPct > 0 ? Colors.green[700] : Colors.red[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _financialMetric(
                                'Doanh thu',
                                _formatCompactCurrency(latestRevenue),
                                Icons.trending_up,
                                Colors.blue[700]!,
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey[300]),
                            Expanded(
                              child: _financialMetric(
                                'Lợi nhuận',
                                _formatCompactCurrency(latestProfit),
                                isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                                isProfitable ? Colors.green[700]! : Colors.red[700]!,
                              ),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey[300]),
                            Expanded(
                              child: _financialMetric(
                                'Biên LN',
                                '${latestMargin.toStringAsFixed(1)}%',
                                Icons.percent,
                                Colors.orange[700]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 12-month totals
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng 12 tháng gần nhất',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Doanh thu', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCompactCurrency(totalRevenue12m),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lợi nhuận', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCompactCurrency(totalProfit12m),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: totalProfit12m >= 0 ? Colors.green[700] : Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mini revenue chart
                if (records.length >= 3) ...[
                  Text(
                    'Xu hướng doanh thu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMiniRevenueChart(records.reversed.toList()),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _financialMetric(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMiniRevenueChart(List<MonthlyPnl> records) {
    final data = records.length > 12 ? records.sublist(records.length - 12) : records;
    final maxRevenue = data.fold<double>(0, (max, r) => r.netRevenue > max ? r.netRevenue : max);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((r) {
              final heightPct = maxRevenue > 0 ? r.netRevenue / maxRevenue : 0.0;
              final isProfitable = r.netProfit > 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Profit indicator dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isProfitable ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Bar
                      Flexible(
                        child: Container(
                          width: double.infinity,
                          height: (heightPct * 80).clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: isProfitable ? Colors.green[300] : Colors.red[300],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Month label
                      Text(
                        'T${r.reportMonth.month}',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gọi $phoneNumber')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi email tới $email')),
      );
    }
  }
}
