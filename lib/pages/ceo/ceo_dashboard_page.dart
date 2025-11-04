import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/ceo_dashboard_provider.dart';
import '../../providers/ceo_tab_provider.dart';
import 'ceo_main_layout.dart';
import 'ceo_notifications_page.dart';
import 'ceo_profile_page.dart';

/// CEO Dashboard Page
/// Main overview dashboard for CEO with key metrics and KPIs
import '../../widgets/multi_account_switcher.dart';

class CEODashboardPage extends ConsumerStatefulWidget {
  const CEODashboardPage({super.key});

  @override
  ConsumerState<CEODashboardPage> createState() => _CEODashboardPageState();
}

class _CEODashboardPageState extends ConsumerState<CEODashboardPage> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    // � Use real data from database via provider
    final kpisAsync = ref.watch(ceoDashboardKPIProvider);
    final activitiesAsync = ref.watch(ceoDashboardActivitiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data from provider
          ref.invalidate(ceoDashboardKPIProvider);
          ref.invalidate(ceoDashboardActivitiesProvider);

          // Show refresh feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dữ liệu đã được làm mới'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: kpisAsync.when(
          data: (kpis) => SingleChildScrollView(
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
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(ceoDashboardKPIProvider);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Remove old mock data methods - no longer needed
  /*
  // 📊 Mock KPIs data to avoid database errors
  // ✅ Default to 0 for new users - no fake data
  Map<String, dynamic> _getMockKPIs() {
    return {
      'monthlyRevenue': 0.0,
      'revenueGrowth': 0.0,
      'totalCompanies': 0,
      'totalEmployees': 0,
      'totalTables': 0,
      'activeOrders': 0,
      'todayRevenue': 0.0,
      'todayGrowth': 0.0,
    };
  }

  // 📝 Mock activities data - empty for new users
  AsyncValue<dynamic> _getMockActivities() {
    final mockActivities = <Map<String, dynamic>>[];
    return AsyncValue.data(mockActivities);
  }
  */

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
        // Multi-Account Switcher - Google/Facebook Style
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEONotificationsPage(),
              ),
            );
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, color: Colors.black54),
              // Notification badge
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CEOProfilePage(),
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
                  _navigateToTab(CEOTabs.reports);
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
                  _navigateToTab(CEOTabs.analytics);
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
                  // Navigate to Companies tab (where you manage employees)
                  _navigateToTab(CEOTabs.companies);
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
                  // Navigate to AI Management tab (settings)
                  _navigateToTab(CEOTabs.ai);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Navigate to a specific tab in CEO Main Layout
  void _navigateToTab(int tabIndex) {
    // Use GlobalKey to access CEOMainLayout state
    ceoMainLayoutKey.currentState?.navigateToTab(tabIndex);
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

  Widget _buildRecentActivitiesSection(AsyncValue<dynamic> activitiesAsync) {
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
            data: (activities) {
              // Mock data is already a list
              final activitiesList = activities as List;

              if (activitiesList.isEmpty) {
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
                children: activitiesList.map((activity) {
                  final action = activity['action'] as String;
                  final details = activity['details'] as String;
                  final timestamp = activity['timestamp'] as DateTime;
                  final timeAgo = _getTimeAgo(timestamp);

                  // Create title from action and details
                  final title = '$action - $details';

                  IconData icon;
                  Color color;

                  // Determine icon based on action type
                  if (action.contains('Tạo')) {
                    icon = Icons.add_circle;
                    color = Colors.green;
                  } else if (action.contains('Cập nhật')) {
                    icon = Icons.edit;
                    color = Colors.blue;
                  } else if (action.contains('Thêm')) {
                    icon = Icons.person_add;
                    color = Colors.orange;
                  } else {
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
