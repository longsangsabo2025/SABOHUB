import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/cache/cached_provider.dart';
import '../../providers/analytics_provider_cached.dart';

/// CEO Dashboard Page
/// Main overview dashboard for CEO with key metrics and KPIs
class CEODashboardPage extends ConsumerStatefulWidget {
  const CEODashboardPage({super.key});

  @override
  ConsumerState<CEODashboardPage> createState() => _CEODashboardPageState();
}

class _CEODashboardPageState extends ConsumerState<CEODashboardPage> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    // ✅ Use cached providers - persist across tab switches
    final kpisAsync = ref.watch(cachedDashboardKPIsProvider);
    final activitiesAsync = ref.watch(cachedActivityLogProvider(10));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: kpisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Lỗi tải dữ liệu: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // ✅ Refresh cached providers
                  ref.read(cachedDashboardKPIsProvider.notifier).refresh();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (cachedKpis) {
          // Unwrap cached data
          final kpis = cachedKpis.data;

          return RefreshIndicator(
            // ✅ Pull-to-refresh support
            onRefresh: () async {
              await Future.wait([
                ref.read(cachedDashboardKPIsProvider.notifier).refresh(),
                ref.read(cachedActivityLogProvider(10).notifier).refresh(),
              ]);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(kpis),
                  const SizedBox(height: 24),
                  _buildKPISection(kpis),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 24),
                  _buildRecentActivitiesSection(activitiesAsync),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'CEO Dashboard',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thông báo sẽ được triển khai'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trang cá nhân sẽ được triển khai'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.person_outline, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> kpis) {
    final revenue = kpis['monthlyRevenue'] as double;
    final growth = kpis['revenueGrowth'] as double;
    final companies = kpis['totalCompanies'] as int;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chào mừng trở lại!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tổng quan hoạt động kinh doanh hôm nay',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Tổng doanh thu',
                  currencyFormat.format(revenue),
                  Icons.trending_up,
                  '+${growth.toStringAsFixed(1)}%',
                  Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Số công ty',
                  companies.toString(),
                  Icons.business,
                  companies > 0 ? '+$companies' : '0',
                  Colors.blue.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      String change, Color changeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: changeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(Map<String, dynamic> kpis) {
    final totalEmployees = (kpis['totalEmployees'] ?? 0) as int;
    final totalTables = (kpis['totalTables'] ?? 0) as int;
    final revenue = (kpis['monthlyRevenue'] ?? 0.0) as double;
    final netProfit = revenue * 0.36; // Mock: 36% profit margin
    final roi = 18.5; // Mock ROI

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chỉ số kinh doanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Lợi nhuận ròng',
                currencyFormat.format(netProfit),
                Icons.account_balance_wallet,
                const Color(0xFF4CAF50),
                '+8.2%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'ROI trung bình',
                '${roi.toStringAsFixed(1)}%',
                Icons.trending_up,
                const Color(0xFF2196F3),
                '+2.1%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Nhân viên',
                totalEmployees.toString(),
                Icons.group,
                const Color(0xFF9C27B0),
                totalEmployees > 0 ? '+15' : '0',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Bàn bi-a',
                totalTables.toString(),
                Icons.table_restaurant,
                const Color(0xFFFF9800),
                totalTables > 0 ? '+${(totalTables * 0.1).toInt()}' : '0',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Báo cáo tài chính',
                Icons.assessment,
                const Color(0xFF1976D2),
                () {
                  // Navigate to Reports tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chuyển sang tab Báo cáo'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Phân tích KPI',
                Icons.analytics,
                const Color(0xFF388E3C),
                () {
                  // Navigate to Analytics tab
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chuyển sang tab Phân tích'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Quản lý nhân sự',
                Icons.people,
                const Color(0xFFD32F2F),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quản lý nhân sự đang phát triển'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Cài đặt hệ thống',
                Icons.settings,
                const Color(0xFF7B1FA2),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cài đặt hệ thống đang phát triển'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(
      AsyncValue<CachedData<List<Map<String, dynamic>>>> activitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: activitiesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Lỗi tải hoạt động: $error'),
            ),
            data: (cachedActivities) {
              // Unwrap cached data
              final activities = cachedActivities.data;

              if (activities.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Chưa có hoạt động nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: activities.map((activity) {
                  final title = activity['title'] as String;
                  final status = activity['status'] as String;
                  final timestamp =
                      DateTime.parse(activity['timestamp'] as String);
                  final timeAgo = _getTimeAgo(timestamp);

                  IconData icon;
                  Color color;

                  switch (status) {
                    case 'completed':
                      icon = Icons.check_circle;
                      color = Colors.green;
                      break;
                    case 'in_progress':
                      icon = Icons.pending;
                      color = Colors.orange;
                      break;
                    case 'pending':
                      icon = Icons.schedule;
                      color = Colors.blue;
                      break;
                    default:
                      icon = Icons.task_alt;
                      color = Colors.grey;
                  }

                  return _buildActivityItem(title, timeAgo, icon, color);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
