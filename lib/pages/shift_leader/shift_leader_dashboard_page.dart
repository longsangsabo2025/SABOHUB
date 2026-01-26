import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/cached_providers.dart';
import '../../models/staff.dart';
import '../../widgets/multi_account_switcher.dart';

/// Shift Leader Dashboard Page
/// Overview of current shift operations and KPIs
class ShiftLeaderDashboardPage extends ConsumerWidget {
  const ShiftLeaderDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 PHASE 4: Use CACHED providers
    final statsAsync = ref.watch(cachedShiftLeaderDashboardStatsProvider);
    final teamAsync = ref.watch(cachedShiftLeaderTeamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshShiftLeaderData(ref);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) => _buildKPICards(stats, currencyFormat),
                loading: () => _buildLoadingKPIs(),
                error: (e, s) => _buildErrorCard('Lỗi tải KPIs', e.toString()),
              ),
              const SizedBox(height: 24),
              teamAsync.when(
                data: (team) => _buildStaffOverview(_convertTeamToStats(team)),
                loading: () => _buildLoadingCard(height: 150),
                error: (e, s) =>
                    _buildErrorCard('Lỗi tải nhân viên', e.toString()),
              ),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) => _buildShiftSummary(stats, currencyFormat),
                loading: () => _buildLoadingCard(height: 200),
                error: (e, s) =>
                    _buildErrorCard('Lỗi tải ca làm', e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Convert team list to stats map
  Map<String, dynamic> _convertTeamToStats(List<Staff> team) {
    final active = team.where((m) => m.status == 'active').length;
    final onLeave = team.where((m) => m.status == 'on_leave').length;
    return {
      'total': team.length,
      'active': active,
      'onLeave': onLeave,
    };
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: const Text(
        'Dashboard Trưởng Ca',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        // Multi-Account Switcher
        const MultiAccountSwitcher(),
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔔 Thông báo'),
                backgroundColor: Color(0xFF8B5CF6),
              ),
            );
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;

    if (hour < 12) {
      greeting = 'Chào buổi sáng';
      emoji = '☀️';
    } else if (hour < 18) {
      greeting = 'Chào buổi chiều';
      emoji = '🌤️';
    } else {
      greeting = 'Chào buổi tối';
      emoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $greeting',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chúc bạn một ca làm việc hiệu quả!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(
      Map<String, dynamic> kpis, NumberFormat currencyFormat) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Bàn hoạt động',
                '${kpis['activeTables'] ?? 0}/${kpis['totalTables'] ?? 0}',
                Icons.table_restaurant,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                'Đơn hàng',
                '${kpis['totalOrders'] ?? 0}',
                Icons.receipt_long,
                const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Doanh thu ca',
                currencyFormat.format(kpis['revenue'] ?? 0),
                Icons.payments,
                const Color(0xFFFBBF24),
                isLarge: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isLarge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.trending_up, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildStaffOverview(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Text(
                'Nhân viên ca này',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats['active'] ?? 0} online',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStaffStat(
                  'Tổng NV',
                  '${stats['total'] ?? 0}',
                  Icons.people,
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStaffStat(
                  'Đang làm',
                  '${stats['active'] ?? 0}',
                  Icons.work,
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStaffStat(
                  'Nghỉ phép',
                  '${stats['onLeave'] ?? 0}',
                  Icons.event_busy,
                  const Color(0xFFFBBF24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSummary(
      Map<String, dynamic> kpis, NumberFormat currencyFormat) {
    final performance = kpis['performance'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Tổng quan ca làm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Hiệu suất',
              '$performance%',
              performance >= 80
                  ? const Color(0xFF10B981)
                  : const Color(0xFFFBBF24)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Doanh thu',
              currencyFormat.format(kpis['revenue'] ?? 0),
              const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Số đơn', '${kpis['totalOrders'] ?? 0}', const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildSummaryRow(
              'Bàn đang dùng',
              '${kpis['activeTables'] ?? 0}/${kpis['totalTables'] ?? 0}',
              const Color(0xFFFBBF24)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingKPIs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard(height: 100)),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard(height: 100)),
          ],
        ),
        const SizedBox(height: 12),
        _buildLoadingCard(height: 100),
      ],
    );
  }

  Widget _buildLoadingCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
