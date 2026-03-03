import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/ceo/ai_briefing_widgets.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../ceo_profile_page.dart';
import '../ceo_notifications_page.dart';
import '../ceo_reports_settings_page.dart' show CEOSettingsPage;
import '../shared/ceo_more_page.dart';

// Shared CEO pages
import '../ceo_tasks_page.dart';
import '../ceo_employees_page.dart';

/// Vận Hành CEO Layout — Musk-style Command Center
/// 4 tabs: Tổng quan | Đội ngũ | Vấn đề | Tăng trưởng
/// CEO sees STRATEGY, not POS operations (tables/menu/sessions → Manager only)
class EntertainmentCEOLayout extends ConsumerStatefulWidget {
  const EntertainmentCEOLayout({super.key});

  @override
  ConsumerState<EntertainmentCEOLayout> createState() =>
      _EntertainmentCEOLayoutState();
}

class _EntertainmentCEOLayoutState
    extends ConsumerState<EntertainmentCEOLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyName = user?.companyName ?? 'Công ty';
    final businessLabel = user?.businessType?.ceoLabel ?? 'Vận Hành';

    final pages = <Widget>[
      CEOAICommandCenter(businessLabel: businessLabel),
      _CEOTeamTab(),
      _CEOIssuesTab(),
      _CEOGrowthTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'CEO · $businessLabel',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          const RealtimeNotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOProfilePage()));
                  break;
                case 'notifications':
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CEONotificationsPage()));
                  break;
                case 'settings':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOSettingsPage()));
                  break;
                case 'more':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOMorePage()));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: ListTile(
                dense: true,
                leading: Icon(Icons.person_outline),
                title: Text('Hồ sơ cá nhân'),
              )),
              PopupMenuItem(value: 'notifications', child: ListTile(
                dense: true,
                leading: Icon(Icons.notifications_outlined),
                title: Text('Thông báo'),
              )),
              PopupMenuItem(value: 'settings', child: ListTile(
                dense: true,
                leading: Icon(Icons.settings_outlined),
                title: Text('Cài đặt'),
              )),
              PopupMenuItem(value: 'more', child: ListTile(
                dense: true,
                leading: Icon(Icons.apps),
                title: Text('Thêm (Công ty, Tài liệu, AI...)'),
              )),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          HapticFeedback.lightImpact();
          setState(() => _currentIndex = index);
        },
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch, color: AppColors.primary),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Đội ngũ',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber, color: Colors.orange),
            label: 'Vấn đề',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up, color: AppColors.success),
            label: 'Tăng trưởng',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: ĐỘI NGŨ — "People are everything"
// Who's working, tasks running, who needs praise/reminder
// ═══════════════════════════════════════════════════════════════════
class _CEOTeamTab extends StatefulWidget {
  @override
  State<_CEOTeamTab> createState() => _CEOTeamTabState();
}

class _CEOTeamTabState extends State<_CEOTeamTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.assignment, size: 18), text: 'Công việc'),
              Tab(icon: Icon(Icons.people, size: 18), text: 'Nhân viên'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CEOTasksPage(),
              CEOEmployeesPage(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3: VẤN ĐỀ — "Fix the bottleneck"
// Alerts needing CEO decision: overdue tasks, anomalies, issues
// ═══════════════════════════════════════════════════════════════════
class _CEOIssuesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CEOIssuesTab> createState() => _CEOIssuesTabState();
}

class _CEOIssuesTabState extends ConsumerState<_CEOIssuesTab> {
  List<Map<String, dynamic>> _overdueTasks = [];
  List<Map<String, dynamic>> _lowRevenueDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final sb = supabase.client;
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final weekAgo = now.subtract(const Duration(days: 7)).toIso8601String().split('T')[0];

      final results = await Future.wait([
        // Overdue tasks (due_date < today, not completed)
        sb.from('tasks').select('id, title, due_date, assigned_to')
            .eq('company_id', companyId)
            .eq('status', 'pending')
            .lt('due_date', '${todayStr}T00:00:00'),
        // Revenue last 7 days (to detect low days)
        sb.from('daily_revenue').select('date, total_revenue')
            .eq('company_id', companyId)
            .gte('date', weekAgo)
            .order('date'),
      ]);

      final overdue = List<Map<String, dynamic>>.from(results[0] as List);
      final revenueData = List<Map<String, dynamic>>.from(results[1] as List);

      // Find days with revenue significantly below average
      List<Map<String, dynamic>> lowDays = [];
      if (revenueData.length > 2) {
        final avg = revenueData.fold<double>(0, (s, r) =>
            s + ((r['total_revenue'] as num?)?.toDouble() ?? 0)) / revenueData.length;
        lowDays = revenueData.where((r) {
          final rev = (r['total_revenue'] as num?)?.toDouble() ?? 0;
          return rev < avg * 0.5 && rev > 0; // Less than 50% of average
        }).toList();
      }

      if (mounted) {
        setState(() {
          _overdueTasks = overdue;
          _lowRevenueDays = lowDays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final totalIssues = _overdueTasks.length + _lowRevenueDays.length;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadIssues();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: totalIssues == 0
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: totalIssues == 0
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    totalIssues == 0 ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: totalIssues == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      totalIssues == 0
                          ? 'Mọi thứ OK. Không có vấn đề cần xử lý.'
                          : '$totalIssues vấn đề cần CEO xử lý',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: totalIssues == 0
                            ? const Color(0xFF10B981) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Overdue tasks
            if (_overdueTasks.isNotEmpty) ...[
              _sectionHeader('⏰ Công việc quá hạn', _overdueTasks.length),
              const SizedBox(height: 8),
              ..._overdueTasks.map((task) => _buildIssueCard(
                icon: Icons.assignment_late,
                color: Colors.red,
                title: task['title'] ?? 'Không có tiêu đề',
                subtitle: 'Hạn: ${task['due_date']?.toString().split('T')[0] ?? '?'}',
              )),
              const SizedBox(height: 16),
            ],

            // Low revenue alerts
            if (_lowRevenueDays.isNotEmpty) ...[
              _sectionHeader('📉 Ngày doanh thu thấp bất thường', _lowRevenueDays.length),
              const SizedBox(height: 8),
              ..._lowRevenueDays.map((day) {
                final rev = (day['total_revenue'] as num?)?.toDouble() ?? 0;
                return _buildIssueCard(
                  icon: Icons.trending_down,
                  color: Colors.orange,
                  title: day['date']?.toString() ?? '?',
                  subtitle: 'Chỉ ${_fmtShort(rev)} — dưới 50% trung bình tuần',
                );
              }),
              const SizedBox(height: 16),
            ],

            // Empty state
            if (totalIssues == 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.verified, size: 48, color: Colors.green.shade300),
                      const SizedBox(height: 12),
                      const Text('Hệ thống ổn định',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Không có task quá hạn, doanh thu đều đặn.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtShort(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}₫';
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
        ),
      ],
    );
  }

  Widget _buildIssueCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4: TĂNG TRƯỞNG — "Growth or die"
// Revenue trends, peak hours, performance insights
// ═══════════════════════════════════════════════════════════════════
class _CEOGrowthTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CEOGrowthTab> createState() => _CEOGrowthTabState();
}

class _CEOGrowthTabState extends ConsumerState<_CEOGrowthTab> {
  List<Map<String, dynamic>> _last30DaysRevenue = [];
  double _thisMonthTotal = 0;
  double _lastMonthTotal = 0;
  int _thisMonthSessions = 0;
  int _lastMonthSessions = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrowthData();
  }

  Future<void> _loadGrowthData() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final sb = supabase.client;
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastMonthStart = DateTime(now.year, now.month - 1, 1).toIso8601String().split('T')[0];
      final thirtyDaysAgo = now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];

      final results = await Future.wait([
        // Last 30 days revenue (for trend)
        sb.from('daily_revenue').select('date, total_revenue')
            .eq('company_id', companyId)
            .gte('date', thirtyDaysAgo)
            .order('date'),
        // This month revenue
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', thisMonthStart),
        // Last month revenue
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', lastMonthStart)
            .lt('date', thisMonthStart),
        // This month sessions
        sb.from('table_sessions').select('id')
            .eq('company_id', companyId)
            .gte('start_time', '${thisMonthStart}T00:00:00'),
        // Last month sessions
        sb.from('table_sessions').select('id')
            .eq('company_id', companyId)
            .gte('start_time', '${lastMonthStart}T00:00:00')
            .lt('start_time', '${thisMonthStart}T00:00:00'),
      ]);

      if (mounted) {
        setState(() {
          _last30DaysRevenue = List<Map<String, dynamic>>.from(results[0] as List);
          _thisMonthTotal = _sumRev(results[1] as List);
          _lastMonthTotal = _sumRev(results[2] as List);
          _thisMonthSessions = (results[3] as List).length;
          _lastMonthSessions = (results[4] as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _sumRev(List data) => data.fold<double>(
      0, (s, r) => s + ((r['total_revenue'] as num?)?.toDouble() ?? 0));

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}tỷ';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}₫';
  }

  String _growthPct(double current, double previous) {
    if (previous == 0) return current > 0 ? '+∞' : '—';
    final pct = ((current - previous) / previous * 100).toStringAsFixed(0);
    return current >= previous ? '+$pct%' : '$pct%';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final revenueGrowth = _growthPct(_thisMonthTotal, _lastMonthTotal);
    final sessionGrowth = _growthPct(
        _thisMonthSessions.toDouble(), _lastMonthSessions.toDouble());
    final isRevenueUp = _thisMonthTotal >= _lastMonthTotal;
    final isSessionsUp = _thisMonthSessions >= _lastMonthSessions;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadGrowthData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📈 Tăng trưởng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('So sánh tháng này vs tháng trước',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Month-over-month comparison cards
            Row(
              children: [
                _buildGrowthCard(
                  'Doanh thu tháng',
                  _fmt(_thisMonthTotal),
                  revenueGrowth,
                  isRevenueUp,
                  Icons.payments,
                ),
                const SizedBox(width: 12),
                _buildGrowthCard(
                  'Lượt phiên',
                  '$_thisMonthSessions',
                  sessionGrowth,
                  isSessionsUp,
                  Icons.receipt_long,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Revenue trend (simple bar chart using containers)
            const Text('Xu hướng 30 ngày',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_last30DaysRevenue.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Chưa có dữ liệu doanh thu',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            else
              _buildSimpleTrendChart(),

            const SizedBox(height: 20),

            // Best/worst day
            if (_last30DaysRevenue.isNotEmpty) ...[
              _buildInsightRow(),
            ],

            const SizedBox(height: 16),

            // Musk quote
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"Growth or die."',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  SizedBox(height: 4),
                  Text('Theo dõi xu hướng. Ra quyết định dựa trên data, không phải cảm xúc.',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(String label, String value, String growth,
      bool isUp, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade500),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUp ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTrendChart() {
    // Find max for scaling
    double maxRev = 0;
    for (final d in _last30DaysRevenue) {
      final v = (d['total_revenue'] as num?)?.toDouble() ?? 0;
      if (v > maxRev) maxRev = v;
    }
    if (maxRev == 0) maxRev = 1;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _last30DaysRevenue.map((d) {
          final v = (d['total_revenue'] as num?)?.toDouble() ?? 0;
          final ratio = v / maxRev;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Tooltip(
                message: '${d['date']}: ${_fmt(v)}',
                child: Container(
                  height: (ratio * 80).clamp(2.0, 80.0),
                  decoration: BoxDecoration(
                    color: ratio > 0.7
                        ? const Color(0xFF10B981)
                        : ratio > 0.4
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightRow() {
    // Best day
    var bestDay = _last30DaysRevenue[0];
    var worstDay = _last30DaysRevenue[0];
    for (final d in _last30DaysRevenue) {
      final v = (d['total_revenue'] as num?)?.toDouble() ?? 0;
      if (v > ((bestDay['total_revenue'] as num?)?.toDouble() ?? 0)) bestDay = d;
      if (v < ((worstDay['total_revenue'] as num?)?.toDouble() ?? 0)) worstDay = d;
    }

    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            '🏆 Ngày tốt nhất',
            bestDay['date']?.toString().substring(5) ?? '?',
            _fmt((bestDay['total_revenue'] as num?)?.toDouble() ?? 0),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInsightCard(
            '📉 Ngày yếu nhất',
            worstDay['date']?.toString().substring(5) ?? '?',
            _fmt((worstDay['total_revenue'] as num?)?.toDouble() ?? 0),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String date, String revenue, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          Text(revenue, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
