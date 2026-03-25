import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/theme/app_colors.dart';
import '../../../../pages/ceo/ceo_profile_page.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/screen_perf_tracker.dart';
import '../../providers/media_channel_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/service_number_formatters.dart';

class ManagerOverviewTab extends ConsumerStatefulWidget {
  final void Function(int) onSwitchTab;
  const ManagerOverviewTab({super.key, required this.onSwitchTab});

  @override
  ConsumerState<ManagerOverviewTab> createState() =>
      ManagerOverviewTabState();
}

class ManagerOverviewTabState extends ConsumerState<ManagerOverviewTab> {
  final ScreenPerfTracker _perf = ScreenPerfTracker('ServiceManagerOverview');
  bool _isLoading = true;
  int _totalEmployees = 0;
  int _activeEmployees = 0;
  double _todayRevenue = 0;
  double _weekRevenue = 0;
  int _pendingTasks = 0;

  @override
  void initState() {
    super.initState();
    _perf.start();
    _loadOverview();
  }

  @override
  void dispose() {
    _perf.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    final stopwatch = Stopwatch()..start();
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final sb = Supabase.instance.client;
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0];

      final results = await Future.wait([
        // Employees
        sb
            .from('employees')
            .select('id, is_active')
            .eq('company_id', companyId),
        // Today revenue
        sb
            .from('daily_revenue')
            .select('total_revenue')
            .eq('company_id', companyId)
            .eq('date', todayStr),
        // Week revenue
        sb
            .from('daily_revenue')
            .select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', weekStartStr)
            .lte('date', todayStr),
        // Tasks
        sb
            .from('tasks')
            .select('id, status')
            .eq('company_id', companyId)
            .inFilter('status', ['pending', 'in_progress']),
      ]);

      final employees = results[0] as List;
      final todayRevList = results[1] as List;
      final weekRevList = results[2] as List;
      final tasks = results[3] as List;

      if (!mounted) return;
      setState(() {
        _totalEmployees = employees.length;
        _activeEmployees =
            employees.where((e) => e['is_active'] == true).length;
        _todayRevenue = todayRevList.fold<double>(
            0, (sum, r) => sum + ((r['total_revenue'] as num?)?.toDouble() ?? 0));
        _weekRevenue = weekRevList.fold<double>(
            0, (sum, r) => sum + ((r['total_revenue'] as num?)?.toDouble() ?? 0));
        _pendingTasks = tasks.length;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _perf.markFirstDataRendered(extra: {
          'company_id': companyId,
          'employees': _totalEmployees,
          'pending_tasks': _pendingTasks,
        });
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    } finally {
      stopwatch.stop();
      _perf.logQueryDuration(
        'load_overview',
        stopwatch.elapsed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionStats = ref.watch(sessionStatsProvider);
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final channelStats = ref.watch(mediaChannelStatsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sessionStatsProvider);
        ref.invalidate(mediaChannelStatsProvider);
        _loadOverview();
      },
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section: Doanh thu ──
                  _sectionHeader('💰 Doanh thu'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniCard(
                        'Hôm nay',
                        formatServiceRevenueCompact(_todayRevenue),
                        Icons.today,
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _miniCard(
                        'Tuần này',
                        formatServiceRevenueCompact(_weekRevenue),
                        Icons.date_range,
                        AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section: Vận hành ──
                  _sectionHeader('🎱 Vận hành'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniCard(
                        'Bàn đang chơi',
                        sessionStats.when(
                          data: (s) => '${s['activeSessions'] ?? 0}',
                          loading: () => '...',
                          error: (_, __) => '—',
                        ),
                        Icons.table_bar,
                        Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _miniCard(
                        'Tạm dừng',
                        sessionStats.when(
                          data: (s) => '${s['pausedSessions'] ?? 0}',
                          loading: () => '...',
                          error: (_, __) => '—',
                        ),
                        Icons.pause_circle,
                        Colors.deepOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniCard(
                        'Hoàn thành',
                        sessionStats.when(
                          data: (s) => '${s['completedToday'] ?? 0}',
                          loading: () => '...',
                          error: (_, __) => '—',
                        ),
                        Icons.check_circle_outline,
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _miniCard(
                        'Doanh thu phiên',
                        sessionStats.when(
                          data: (s) {
                            final rev =
                                (s['todayRevenue'] as num?)?.toDouble() ?? 0;
                            return formatServiceRevenueCompact(rev);
                          },
                          loading: () => '...',
                          error: (_, __) => '—',
                        ),
                        Icons.attach_money,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section: Đội ngũ & Công việc ──
                  _sectionHeader('👥 Đội ngũ & Công việc'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniCard(
                        'Nhân viên',
                        '$_activeEmployees/$_totalEmployees',
                        Icons.people,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _miniCard(
                        'Chờ xử lý',
                        '$_pendingTasks',
                        Icons.pending_actions,
                        AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Section: Media ──
                  _sectionHeader('📺 Media'),
                  const SizedBox(height: 8),
                  channelStats.when(
                    data: (stats) {
                      final totalSubs =
                          (stats['total_subscribers'] as num?)?.toInt() ?? 0;
                      final channelCount =
                          (stats['channel_count'] as num?)?.toInt() ?? 0;
                      return Row(
                        children: [
                          _miniCard(
                            'Kênh',
                            '$channelCount',
                            Icons.play_circle,
                            Colors.red,
                          ),
                          const SizedBox(width: 10),
                          _miniCard(
                            'Subscribers',
                            formatServiceCountCompact(totalSubs),
                            Icons.group,
                            AppColors.info,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Table Status Breakdown ──
                  sessionStats.when(
                    data: (s) {
                      final hasTableMetrics =
                          s.containsKey('available') ||
                          s.containsKey('availableTables') ||
                          s.containsKey('reserved') ||
                          s.containsKey('reservedTables') ||
                          s.containsKey('maintenance') ||
                          s.containsKey('maintenanceTables');
                      if (!hasTableMetrics) {
                        return const SizedBox.shrink();
                      }

                      final available =
                          (s['available'] ?? s['availableTables'] ?? 0)
                              as int;
                      final occupied =
                          (s['occupied'] ?? s['activeSessions'] ?? 0) as int;
                      final reserved =
                          (s['reserved'] ?? s['reservedTables'] ?? 0) as int;
                      final maintenance =
                          (s['maintenance'] ?? s['maintenanceTables'] ?? 0)
                              as int;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Trạng thái bàn',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 10),
                              _statusRow(
                                  'Trống', available, AppColors.success),
                              _statusRow(
                                  'Đang chơi', occupied, Colors.red),
                              _statusRow(
                                  'Đã đặt', reserved, AppColors.warning),
                              _statusRow(
                                  'Bảo trì', maintenance, Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Actions ──
                  _sectionHeader('⚡ Truy cập nhanh'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAction(
                          '🎱 Vận hành', () => widget.onSwitchTab(1)),
                      _quickAction(
                          '📋 Công việc', () => widget.onSwitchTab(2)),
                      _quickAction(
                          '📺 Media', () => widget.onSwitchTab(3)),
                      _quickAction('👤 Hồ sơ', () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CEOProfilePage()));
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _miniCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: DỰ ÁN — Manager's companies view
// Manager can manage multiple companies (via manager_companies table)
// ═══════════════════════════════════════════════════════════════════
