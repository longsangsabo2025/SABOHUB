import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../ceo_profile_page.dart';
import '../ceo_notifications_page.dart';
import '../ceo_reports_settings_page.dart' show CEOSettingsPage;
import '../shared/ceo_more_page.dart';
import '../ceo_tasks_page.dart';
import '../ceo_employees_page.dart';

import '../../../business_types/service/models/media_channel.dart';
import '../../../business_types/service/models/content.dart';
import '../../../business_types/service/providers/media_channel_provider.dart';
import '../../../business_types/service/providers/tournament_provider.dart';
import '../../../business_types/service/providers/event_provider.dart';
import '../../../business_types/service/providers/content_provider.dart';
import '../../../models/company.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/company_alerts_provider.dart';
import '../company_details_page.dart' hide companyStatsProvider;

import 'tournament_form_page.dart';
import 'event_form_page.dart';
import 'content_form_page.dart';
import '../../../business_types/service/pages/cashflow/daily_cashflow_import_page.dart';
import '../../../business_types/service/providers/monthly_pnl_provider.dart';
import '../../../business_types/service/models/monthly_pnl.dart';
import '../../../core/router/app_router.dart';
import '../../../widgets/gamification/ceo_game_summary_card.dart';

/// ═══════════════════════════════════════════════════════
/// SABO Corporation CEO Command Center — Musk Style
/// ═══════════════════════════════════════════════════════
/// 4 tabs: Command | Media | Nhiệm vụ | Tăng trưởng
/// CEO sees STRATEGY across all divisions
class ServiceCEOLayout extends ConsumerStatefulWidget {
  const ServiceCEOLayout({super.key});

  @override
  ConsumerState<ServiceCEOLayout> createState() =>
      _ServiceCEOLayoutState();
}

class _ServiceCEOLayoutState
    extends ConsumerState<ServiceCEOLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyName = user?.companyName ?? 'SABO';

    final pages = <Widget>[
      _CorporationOverviewTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      _MediaProjectsSubTab(),
      _MediaCommandTab(),
      _CEOTeamTab(),
      _CEOGrowthTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        surfaceTintColor: const Color(0xFF0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'CEO Command Center',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          const RealtimeNotificationBell(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
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
                title: Text('Thêm'),
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
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.rocket_launch_outlined),
            selectedIcon: Icon(Icons.rocket_launch, color: AppColors.primary),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: Colors.deepPurple),
            label: 'Dự án',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle, color: Colors.red),
            label: 'Media',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Nhiệm vụ',
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
// TAB 1: CORPORATION OVERVIEW — Strategic Command
// One glance → status of all divisions
// ═══════════════════════════════════════════════════════════════════
class _CorporationOverviewTab extends ConsumerStatefulWidget {
  final void Function(int) onSwitchTab;
  const _CorporationOverviewTab({required this.onSwitchTab});

  @override
  ConsumerState<_CorporationOverviewTab> createState() =>
      _CorporationOverviewTabState();
}

class _CorporationOverviewTabState
    extends ConsumerState<_CorporationOverviewTab> {
  bool _isLoading = true;
  int _totalEmployees = 0;
  int _activeEmployees = 0;
  double _todayRevenue = 0;
  double _monthRevenue = 0;
  int _pendingTasks = 0;
  int _overdueTasks = 0;
  int _totalTables = 0;
  int _activeSessions = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) return;

      final sb = supabase.client;
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      final monthStart =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];

      final results = await Future.wait([
        // Employees
        sb.from('employees').select('id, is_active').eq('company_id', companyId),
        // Today revenue
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .eq('date', todayStr),
        // Month revenue
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', monthStart),
        // Tasks
        sb.from('tasks').select('id, status, due_date')
            .eq('company_id', companyId)
            .inFilter('status', ['pending', 'in_progress']),
        // Tables
        sb.from('tables').select('id, status').eq('company_id', companyId),
        // Active sessions
        sb.from('table_sessions').select('id')
            .eq('company_id', companyId)
            .eq('status', 'active'),
      ]);

      final employees = List<Map<String, dynamic>>.from(results[0] as List);
      final todayRev = List<Map<String, dynamic>>.from(results[1] as List);
      final monthRev = List<Map<String, dynamic>>.from(results[2] as List);
      final tasks = List<Map<String, dynamic>>.from(results[3] as List);
      final tables = List<Map<String, dynamic>>.from(results[4] as List);
      final sessions = results[5] as List;

      if (mounted) {
        setState(() {
          _totalEmployees = employees.length;
          _activeEmployees = employees.where((e) => e['is_active'] == true).length;
          _todayRevenue = todayRev.fold(0.0, (s, r) =>
              s + ((r['total_revenue'] as num?)?.toDouble() ?? 0));
          _monthRevenue = monthRev.fold(0.0, (s, r) =>
              s + ((r['total_revenue'] as num?)?.toDouble() ?? 0));
          _pendingTasks = tasks.length;
          _overdueTasks = tasks.where((t) {
            final due = t['due_date']?.toString();
            if (due == null) return false;
            return DateTime.tryParse(due)?.isBefore(now) == true;
          }).length;
          _totalTables = tables.length;
          _activeSessions = sessions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Watch module providers
    final mediaStats = ref.watch(mediaChannelStatsProvider(companyId));
    final tournamentStats = ref.watch(tournamentStatsProvider(companyId));
    final upcomingEvents = ref.watch(upcomingEventsProvider(companyId));
    final contentPipeline = ref.watch(contentPipelineStatsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        ref.invalidate(mediaChannelStatsProvider);
        ref.invalidate(tournamentStatsProvider);
        ref.invalidate(upcomingEventsProvider);
        ref.invalidate(contentPipelineStatsProvider);
        await _loadOverview();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Chào, ${user?.name?.split(' ').last ?? 'CEO'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            // ═══ GAMIFICATION CARD ═══
            CeoGameSummaryCard(
              onTap: () => context.push(AppRoutes.questHub),
            ),
            const SizedBox(height: 16),

            // ═══ CORE METRICS ═══
            _sectionTitle('Tổng quan nhanh'),
            const SizedBox(height: 8),
            Row(
              children: [
                _metricCard('Doanh thu hôm nay', _fmt(_todayRevenue),
                    Icons.payments, const Color(0xFF10B981),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const CEOSettingsPage()))),
                const SizedBox(width: 8),
                _metricCard('Doanh thu tháng', _fmt(_monthRevenue),
                    Icons.account_balance_wallet, const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const CEOSettingsPage()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _metricCard('Nhân viên', '$_activeEmployees/$_totalEmployees',
                    Icons.people, const Color(0xFF8B5CF6),
                    onTap: () => widget.onSwitchTab(3)),
                const SizedBox(width: 8),
                _metricCard(
                  'Tasks',
                  '$_pendingTasks đang${_overdueTasks > 0 ? ' · $_overdueTasks trễ' : ''}',
                  Icons.assignment,
                  _overdueTasks > 0 ? Colors.orange : const Color(0xFF06B6D4),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CEOTasksPage())),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ═══ DIVISION 1: MEDIA ═══
            _sectionTitleWithAction('Media & Content', 'Quản lý ›', () => widget.onSwitchTab(2)),
            const SizedBox(height: 8),
            mediaStats.when(
              data: (stats) => _buildMediaOverview(stats),
              loading: () => _loadingCard(),
              error: (_, __) => _errorCard('Không thể tải dữ liệu media'),
            ),
            const SizedBox(height: 8),
            contentPipeline.when(
              data: (stats) => _buildContentPipeline(stats),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // ═══ DIVISION 2: TOURNAMENTS ═══
            _sectionTitleWithAction('Giải đấu & Sự kiện', 'Quản lý ›', () => widget.onSwitchTab(1)),
            const SizedBox(height: 8),
            tournamentStats.when(
              data: (stats) => _buildTournamentOverview(stats),
              loading: () => _loadingCard(),
              error: (_, __) => _emptyDivisionCard(
                'Giải đấu',
                'Chưa có giải đấu nào. Tạo giải đấu đầu tiên!',
                Icons.emoji_events,
              ),
            ),
            const SizedBox(height: 8),
            upcomingEvents.when(
              data: (events) => events.isEmpty
                  ? const SizedBox()
                  : _buildUpcomingEvents(events),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 20),

            // ═══ DIVISION 3: VENUE ═══
            _sectionTitle('Venue Operations'),
            const SizedBox(height: 8),
            _buildVenueOverview(context),
            const SizedBox(height: 20),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '"If you\'re not growing, you\'re dying."',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SABO — Media · Tournaments · Technology',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── BUILD HELPERS ───

  Widget _buildMediaOverview(Map<String, dynamic> stats) {
    final totalChannels = stats['total_channels'] ?? 0;
    final activeChannels = stats['active_channels'] ?? 0;
    final totalFollowers = stats['total_followers'] ?? 0;
    final totalViews = stats['total_views'] ?? 0;
    final totalRevenue = (stats['total_revenue'] ?? 0).toDouble();

    if (totalChannels == 0) {
      return _emptyDivisionCard(
        'Media',
        'Chưa có kênh nào. Thêm kênh YouTube/TikTok!',
        Icons.play_circle,
        onTap: () => widget.onSwitchTab(2),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniStat('$activeChannels', 'Kênh', Colors.green),
              _miniStat(_fmtCompact(totalFollowers), 'Followers', Colors.blue),
              _miniStat(_fmtCompact(totalViews), 'Views', Colors.purple),
              _miniStat(_fmt(totalRevenue), 'Doanh thu', Colors.orange),
            ],
          ),
          // Channel list
          if (stats['channels'] != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...((stats['channels'] as List).take(5).map((ch) => GestureDetector(
                  onTap: () => widget.onSwitchTab(2),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(ch.platformIcon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(ch.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                        Text('${_fmtCompact(ch.followersCount)} followers',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ))),
          ],
        ],
      ),
    );
  }

  Widget _buildContentPipeline(Map<String, int> stats) {
    final total = stats['total'] ?? 0;
    final overdue = stats['overdue'] ?? 0;
    if (total == 0) return const SizedBox();

    final inProduction = (stats['scripting'] ?? 0) +
        (stats['filming'] ?? 0) +
        (stats['editing'] ?? 0);
    final published = stats['published'] ?? 0;
    final planned = (stats['idea'] ?? 0) + (stats['planned'] ?? 0);

    return GestureDetector(
      onTap: () => widget.onSwitchTab(2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Content Pipeline',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _pipelineChip('Ý tưởng', planned, Colors.blue),
                _pipelineChip('Sản xuất', inProduction, Colors.orange),
                _pipelineChip('Đã đăng', published, Colors.green),
                if (overdue > 0)
                  _pipelineChip('Trễ hạn', overdue, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentOverview(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    if (total == 0) {
      return _emptyDivisionCard(
        'Giải đấu',
        'Chưa có giải đấu nào. Tạo giải đấu billiard đầu tiên!',
        Icons.emoji_events,
        onTap: () => widget.onSwitchTab(1),
      );
    }

    return GestureDetector(
      onTap: () => widget.onSwitchTab(1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            _miniStat('${stats['active'] ?? 0}', 'Đang diễn ra', Colors.green),
            _miniStat('${stats['upcoming'] ?? 0}', 'Sắp tới', Colors.blue),
            _miniStat('${stats['completed'] ?? 0}', 'Hoàn thành', Colors.grey),
            _miniStat(
                '${stats['total_players'] ?? 0}', 'Tổng VĐV', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(List events) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Sự kiện sắp tới',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onSwitchTab(1),
                child: const Text('Xem tất cả ›',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...events.take(3).map((event) => GestureDetector(
                onTap: () => widget.onSwitchTab(1),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(
                              event.startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(event.startDate!)
                                  : 'Chưa xác định',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.eventType.label,
                          style: TextStyle(
                              fontSize: 10, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildVenueOverview(BuildContext context) {
    if (_totalTables == 0) {
      return _emptyDivisionCard(
        'Venue',
        'Chưa có bàn bida nào. Thêm bàn để bắt đầu!',
        Icons.sports_bar,
        onTap: () => context.go('/tables'),
      );
    }

    return GestureDetector(
      onTap: () => context.go('/tables'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            _miniStat('$_totalTables', 'Tổng bàn', Colors.blue),
            _miniStat('$_activeSessions', 'Đang chơi', Colors.green),
            _miniStat(
                '${_totalTables > 0 ? ((_activeSessions / _totalTables) * 100).toInt() : 0}%',
                'Utilization',
                Colors.orange),
            _miniStat(_fmt(_todayRevenue), 'Hôm nay', Colors.purple),
          ],
        ),
      ),
    );
  }

  // ─── REUSABLE WIDGETS ───

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _sectionTitleWithAction(String title, String actionLabel, VoidCallback onAction) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel,
              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _metricCard(
      String label, String value, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(label,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _pipelineChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(fontSize: 9, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _emptyDivisionCard(String name, String message, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            if (onTap != null) ...[
              const SizedBox(height: 10),
              Text('Bấm để bắt đầu ›',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg,
          style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      );

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}tỷ';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}đ';
  }

  String _fmtCompact(int v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return '$v';
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: MEDIA COMMAND CENTER — 3 sub-tabs
// Tổng quan | Kênh | Nội dung
// ═══════════════════════════════════════════════════════════════════
class _MediaCommandTab extends StatefulWidget {
  @override
  State<_MediaCommandTab> createState() => _MediaCommandTabState();
}

class _MediaCommandTabState extends State<_MediaCommandTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_rounded, size: 18), text: 'Tổng quan'),
              Tab(icon: Icon(Icons.play_circle_outline, size: 18), text: 'Kênh'),
              Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Nội dung'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MediaOverviewSubTab(onSwitchTab: (i) => _tabController.animateTo(i)),
              _MediaChannelsSubTab(),
              _MediaContentSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// SUB-TAB 1: TỔNG QUAN — Dashboard overview
// ─────────────────────────────────────────────────
class _MediaOverviewSubTab extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const _MediaOverviewSubTab({this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final channels = ref.watch(mediaChannelsProvider(companyId));
    final pipeline = ref.watch(contentPipelineStatsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mediaChannelsProvider);
        ref.invalidate(contentPipelineStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Media Command',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Tổng quan hệ thống truyền thông',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Aggregate metric cards
            channels.when(
              data: (list) {
                int totalFollowers = 0, totalVideos = 0, totalViews = 0;
                double totalRevenue = 0;
                for (final ch in list) {
                  totalFollowers += ch.followersCount;
                  totalVideos += ch.videosCount;
                  totalViews += ch.viewsCount;
                  totalRevenue += ch.revenue;
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _metricCard('Followers', _fmtCompact(totalFollowers), Icons.people, const Color(0xFF3B82F6))),
                        const SizedBox(width: 10),
                        Expanded(child: _metricCard('Videos', '$totalVideos', Icons.videocam, const Color(0xFF8B5CF6))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _metricCard('Views', _fmtCompact(totalViews), Icons.visibility, const Color(0xFFF59E0B))),
                        const SizedBox(width: 10),
                        Expanded(child: _metricCard('Doanh thu', _fmtMoney(totalRevenue), Icons.attach_money, const Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Platform breakdown
                    _sectionHeader('Theo nền tảng', '${list.length} kênh', () => onSwitchTab?.call(1)),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      _emptyState('Chưa có kênh nào', 'Vào tab Kênh để thêm kênh mới.', Icons.play_circle_outline)
                    else
                      ..._buildPlatformBreakdown(list),
                  ],
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Lỗi: $e'),
            ),

            const SizedBox(height: 16),

            // Content pipeline summary
            pipeline.when(
              data: (stats) {
                final total = stats['total'] ?? 0;
                final overdue = stats['overdue'] ?? 0;
                final inProgress = (stats['scripting'] ?? 0) + (stats['filming'] ?? 0) + (stats['editing'] ?? 0);
                final pending = (stats['review'] ?? 0) + (stats['scheduled'] ?? 0);
                final published = stats['published'] ?? 0;

                return Column(
                  children: [
                    _sectionHeader('Content Pipeline', '$total items', () => onSwitchTab?.call(2)),
                    const SizedBox(height: 8),
                    if (total == 0)
                      _emptyState('Chưa có content', 'Vào tab Nội dung để tạo content mới.', Icons.calendar_month)
                    else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _pipelineStat('Đang SX', '$inProgress', Colors.orange),
                                _pipelineStat('Chờ duyệt', '$pending', Colors.teal),
                                _pipelineStat('Đã đăng', '$published', Colors.green),
                              ],
                            ),
                            if (overdue > 0) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, size: 15, color: Colors.red.shade700),
                                    const SizedBox(width: 6),
                                    Text('$overdue content đang trễ hạn!',
                                        style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),

            const SizedBox(height: 20),

            // Quick actions
            const Text('Thao tác nhanh',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _quickAction(context, '+ Thêm kênh', Icons.play_circle_outline, AppColors.primary, () => onSwitchTab?.call(1))),
                const SizedBox(width: 10),
                Expanded(child: _quickAction(context, '+ Tạo content', Icons.calendar_month, Colors.purple, () => onSwitchTab?.call(2))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value  , style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const Spacer(),
          Text('Xem ›', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformBreakdown(List<dynamic> channels) {
    // Group by platform
    final platformGroups = <String, List<dynamic>>{};
    for (final ch in channels) {
      final key = ch.platform as String;
      platformGroups.putIfAbsent(key, () => []).add(ch);
    }

    // Define platform display info
    const platformInfo = <String, (String, String, Color)>{
      'youtube': ('🔴', 'YouTube', Color(0xFFFF0000)),
      'tiktok': ('🎵', 'TikTok', Color(0xFF000000)),
      'facebook': ('🔵', 'Facebook', Color(0xFF1877F2)),
      'instagram': ('📸', 'Instagram', Color(0xFFE4405F)),
      'twitter': ('🐦', 'Twitter/X', Color(0xFF1DA1F2)),
      'linkedin': ('💼', 'LinkedIn', Color(0xFF0A66C2)),
    };

    // Sort: platforms with most followers first
    final sortedKeys = platformGroups.keys.toList()
      ..sort((a, b) {
        final aF = platformGroups[a]!.fold<int>(0, (s, c) => s + c.followersCount as int);
        final bF = platformGroups[b]!.fold<int>(0, (s, c) => s + c.followersCount as int);
        return bF.compareTo(aF);
      });

    return sortedKeys.map((platform) {
      final chs = platformGroups[platform]!;
      final info = platformInfo[platform] ?? ('📱', platform, Colors.grey);
      int followers = 0, videos = 0, views = 0;
      double revenue = 0;
      for (final c in chs) {
        followers += c.followersCount as int;
        videos += c.videosCount as int;
        views += c.viewsCount as int;
        revenue += c.revenue as double;
      }
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(info.$1, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: info.$3)),
                      Text('${chs.length} kênh', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtCompact(followers), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('followers', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('Videos', '$videos'),
                _miniStat('Views', _fmtCompact(views)),
                _miniStat('DT', _fmtMoney(revenue)),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _pipelineStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  String _fmtCompact(int v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return '$v';
  }

  String _fmtMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}đ';
  }
}

// ─────────────────────────────────────────────────
// SUB-TAB 2: KÊNH — Channel management (improved)
// ─────────────────────────────────────────────────
class _MediaChannelsSubTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final channels = ref.watch(mediaChannelsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mediaChannelsProvider),
      child: channels.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Chưa có kênh nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Thêm kênh YouTube, TikTok, Facebook...', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCreateChannelDialog(context, ref, companyId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm kênh'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            );
          }
          // Group by platform
          final grouped = <String, List<dynamic>>{};
          for (final ch in list) {
            grouped.putIfAbsent(ch.platform as String, () => []).add(ch);
          }
          const platformOrder = ['youtube', 'tiktok', 'facebook', 'instagram', 'twitter', 'linkedin'];
          final sortedPlatforms = grouped.keys.toList()
            ..sort((a, b) => (platformOrder.indexOf(a) < 0 ? 99 : platformOrder.indexOf(a))
                .compareTo(platformOrder.indexOf(b) < 0 ? 99 : platformOrder.indexOf(b)));

          const platformLabels = <String, (String, String)>{
            'youtube': ('🔴', 'YouTube'),
            'tiktok': ('🎵', 'TikTok'),
            'facebook': ('🔵', 'Facebook'),
            'instagram': ('📸', 'Instagram'),
            'twitter': ('🐦', 'Twitter/X'),
            'linkedin': ('💼', 'LinkedIn'),
          };

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                children: [
                  const Text('Kênh truyền thông', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCreateChannelDialog(context, ref, companyId),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Thêm kênh', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Grouped by platform
              for (final platform in sortedPlatforms) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 6),
                  child: Row(
                    children: [
                      Text(platformLabels[platform]?.$1 ?? '📱', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(platformLabels[platform]?.$2 ?? platform, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                        child: Text('${grouped[platform]!.length}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ),
                    ],
                  ),
                ),
                ...grouped[platform]!.map((ch) => _buildChannelCard(context, ref, ch, companyId)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildChannelCard(BuildContext context, WidgetRef ref, dynamic ch, String companyId) {
    return GestureDetector(
      onTap: () => _showChannelDetailSheet(context, ref, ch, companyId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ch.platformIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ch.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(ch.platform.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ch.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ch.status == 'active' ? 'Hoạt động' : ch.status == 'paused' ? 'Tạm dừng' : ch.status,
                    style: TextStyle(fontSize: 10, color: ch.status == 'active' ? Colors.green.shade700 : Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onSelected: (action) {
                    switch (action) {
                      case 'edit': _showEditChannelDialog(context, ref, ch, companyId);
                      case 'metrics': _showUpdateMetricsDialog(context, ref, ch, companyId);
                      case 'delete': _confirmDeleteChannel(context, ref, ch, companyId);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit, size: 18), title: Text('Sửa kênh', style: TextStyle(fontSize: 13)))),
                    const PopupMenuItem(value: 'metrics', child: ListTile(dense: true, leading: Icon(Icons.trending_up, size: 18), title: Text('Cập nhật số liệu', style: TextStyle(fontSize: 13)))),
                    const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, size: 18, color: Colors.red), title: Text('Xóa kênh', style: TextStyle(fontSize: 13, color: Colors.red)))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _channelStat(Icons.people, _fmtCompact(ch.followersCount), 'Followers'),
                _channelStat(Icons.videocam, '${ch.videosCount}', 'Videos'),
                _channelStat(Icons.visibility, _fmtCompact(ch.viewsCount), 'Views'),
                _channelStat(Icons.attach_money, _fmtMoney(ch.revenue), 'Doanh thu'),
              ],
            ),
            if (ch.targetFollowers != null && ch.targetFollowers > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ch.followerProgress,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(ch.followerProgress >= 1.0 ? Colors.green : Colors.blue),
                ),
              ),
              const SizedBox(height: 4),
              Text('${ch.followersCount}/${ch.targetFollowers} followers target', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _channelStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  String _fmtCompact(int v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return '$v';
  }

  String _fmtMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}đ';
  }

  // ==================== CHANNEL DIALOGS ====================

  void _showChannelDetailSheet(BuildContext context, WidgetRef ref, dynamic ch, String companyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(ch.platformIcon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ch.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(ch.platform.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ch.status == 'active' ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(ch.status == 'active' ? 'Hoạt động' : ch.status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: ch.status == 'active' ? Colors.green.shade700 : Colors.grey.shade600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _detailStat('Followers', _fmtCompact(ch.followersCount), Icons.people)),
                    Expanded(child: _detailStat('Videos', '${ch.videosCount}', Icons.videocam)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _detailStat('Views', _fmtCompact(ch.viewsCount), Icons.visibility)),
                    Expanded(child: _detailStat('Doanh thu', _fmtMoney(ch.revenue), Icons.attach_money)),
                  ]),
                ],
              ),
            ),
            if (ch.targetFollowers != null && ch.targetFollowers > 0) ...[
              const SizedBox(height: 14),
              Text('Mục tiêu Followers', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: ch.followerProgress, minHeight: 8, backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(ch.followerProgress >= 1.0 ? Colors.green : AppColors.primary),
              )),
              const SizedBox(height: 4),
              Text('${ch.followersCount} / ${ch.targetFollowers}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
            if (ch.targetVideos != null && ch.targetVideos > 0) ...[
              const SizedBox(height: 14),
              Text('Mục tiêu Videos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
                value: ch.videoProgress, minHeight: 8, backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(ch.videoProgress >= 1.0 ? Colors.green : Colors.orange),
              )),
              const SizedBox(height: 4),
              Text('${ch.videosCount} / ${ch.targetVideos}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
            if (ch.channelUrl != null && ch.channelUrl!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(children: [
                Icon(Icons.link, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Expanded(child: Text(ch.channelUrl!, style: TextStyle(fontSize: 12, color: AppColors.primary), overflow: TextOverflow.ellipsis)),
              ]),
            ],
            if (ch.notes != null && ch.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Ghi chú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(ch.notes!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(ctx); _showEditChannelDialog(context, ref, ch, companyId); },
                icon: const Icon(Icons.edit, size: 16), label: const Text('Sửa', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: () { Navigator.pop(ctx); _showUpdateMetricsDialog(context, ref, ch, companyId); },
                icon: const Icon(Icons.trending_up, size: 16), label: const Text('Cập nhật số liệu', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade500),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ]),
    ]);
  }

  void _showCreateChannelDialog(BuildContext context, WidgetRef ref, String companyId) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final targetFollowersCtrl = TextEditingController();
    final targetVideosCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String platform = 'youtube';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('Thêm kênh mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên kênh *', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: platform,
              decoration: const InputDecoration(labelText: 'Nền tảng', border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                DropdownMenuItem(value: 'tiktok', child: Text('TikTok')),
                DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                DropdownMenuItem(value: 'twitter', child: Text('Twitter/X')),
                DropdownMenuItem(value: 'linkedin', child: Text('LinkedIn')),
              ],
              onChanged: (v) => setDialogState(() => platform = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL kênh', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: targetFollowersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mục tiêu followers', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: targetVideosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mục tiêu videos', border: OutlineInputBorder(), isDense: true))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder(), isDense: true)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  final actions = ref.read(mediaChannelActionsProvider);
                  final channel = MediaChannel(
                    id: '', companyId: companyId, name: nameCtrl.text.trim(), platform: platform,
                    channelUrl: urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                    targetFollowers: int.tryParse(targetFollowersCtrl.text),
                    targetVideos: int.tryParse(targetVideosCtrl.text),
                    notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  );
                  await actions.createChannel(channel);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã thêm kênh mới'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChannelDialog(BuildContext context, WidgetRef ref, dynamic ch, String companyId) {
    final nameCtrl = TextEditingController(text: ch.name);
    final urlCtrl = TextEditingController(text: ch.channelUrl ?? '');
    final targetFollowersCtrl = TextEditingController(text: ch.targetFollowers?.toString() ?? '');
    final targetVideosCtrl = TextEditingController(text: ch.targetVideos?.toString() ?? '');
    final notesCtrl = TextEditingController(text: ch.notes ?? '');
    String status = ch.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Sửa ${ch.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên kênh', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                DropdownMenuItem(value: 'paused', child: Text('Tạm dừng')),
                DropdownMenuItem(value: 'planning', child: Text('Đang lên kế hoạch')),
                DropdownMenuItem(value: 'archived', child: Text('Lưu trữ')),
              ],
              onChanged: (v) => setDialogState(() => status = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL kênh', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: targetFollowersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mục tiêu followers', border: OutlineInputBorder(), isDense: true))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: targetVideosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mục tiêu videos', border: OutlineInputBorder(), isDense: true))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder(), isDense: true)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton(
              onPressed: () async {
                try {
                  final actions = ref.read(mediaChannelActionsProvider);
                  await actions.updateChannel(ch.id, {
                    'name': nameCtrl.text.trim(), 'status': status,
                    'channel_url': urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                    'target_followers': int.tryParse(targetFollowersCtrl.text),
                    'target_videos': int.tryParse(targetVideosCtrl.text),
                    'notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật kênh'), behavior: SnackBarBehavior.floating));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateMetricsDialog(BuildContext context, WidgetRef ref, dynamic ch, String companyId) {
    final followersCtrl = TextEditingController(text: '${ch.followersCount}');
    final videosCtrl = TextEditingController(text: '${ch.videosCount}');
    final viewsCtrl = TextEditingController(text: '${ch.viewsCount}');
    final revenueCtrl = TextEditingController(text: '${ch.revenue.toInt()}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Text(ch.platformIcon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text('Cập nhật ${ch.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: followersCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Followers', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.people, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: videosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Videos', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.videocam, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: viewsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Views', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.visibility, size: 18))),
          const SizedBox(height: 10),
          TextField(controller: revenueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Doanh thu (VNĐ)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.attach_money, size: 18))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              try {
                final actions = ref.read(mediaChannelActionsProvider);
                await actions.updateMetrics(ch.id,
                  followersCount: int.tryParse(followersCtrl.text), videosCount: int.tryParse(videosCtrl.text),
                  viewsCount: int.tryParse(viewsCtrl.text), revenue: double.tryParse(revenueCtrl.text),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã cập nhật số liệu'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChannel(BuildContext context, WidgetRef ref, dynamic ch, String companyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa kênh?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bạn có chắc muốn xóa "${ch.name}"?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              try {
                final actions = ref.read(mediaChannelActionsProvider);
                await actions.deleteChannel(ch.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa kênh'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// SUB-TAB 3: DỰ ÁN — Company subsidiaries of SABO
// Each "project" = a SABO company (SABO Billiards, SABO Media, Odori, etc.)
// ─────────────────────────────────────────────────
class _MediaProjectsSubTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MediaProjectsSubTab> createState() => _MediaProjectsSubTabState();
}

class _MediaProjectsSubTabState extends ConsumerState<_MediaProjectsSubTab> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (companies) {
        final filtered = _filterType == 'all'
            ? companies
            : companies.where((c) => c.type.toString().split('.').last == _filterType).toList();

        // Stats
        final totalCount = companies.length;
        final activeCount = companies.where((c) => c.status == 'active').length;
        final serviceCount = companies.where((c) => c.type.isEntertainment && !c.type.isCorporation).length;
        final distributionCount = companies.where((c) => c.type.isDistribution).length;

        return Column(
          children: [
            // ── Stats bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  _projectStat('Tổng', totalCount, Colors.grey),
                  _projectStat('Hoạt động', activeCount, AppColors.success),
                  _projectStat('Dịch vụ', serviceCount, AppColors.info),
                  _projectStat('Phân phối', distributionCount, AppColors.primary),
                ],
              ),
            ),
            // ── Filter bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade50,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _typeChip('all', 'Tất cả'),
                    _typeChip('corporation', '🏢 Tổng Công Ty'),
                    _typeChip('billiards', '🎱 Bida'),
                    _typeChip('restaurant', '🍽️ Nhà hàng'),
                    _typeChip('cafe', '☕ Cafe'),
                    _typeChip('distribution', '🚚 Phân phối'),
                    _typeChip('manufacturing', '🏭 Sản xuất'),
                    _typeChip('hotel', '🏨 Khách sạn'),
                    _typeChip('retail', '🛒 Bán lẻ'),
                  ],
                ),
              ),
            ),
            // ── Company list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Chưa có dự án nào',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildCompanyCard(context, filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _projectStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label) {
    final isSelected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey.shade700)),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterType = type),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, Company c) {
    final typeColor = c.type.color;
    final typeIcon = c.type.icon;
    final isActive = c.status == 'active';
    final alertsAsync = ref.watch(companyAlertsProvider(c.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCompanyDetail(context, c),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: typeColor, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Icon + Name + Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 20, color: typeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Text(c.type.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Tạm ngưng',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              // Row 2: Alerts badges
              alertsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (alerts) {
                  if (!alerts.hasAlerts) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (alerts.overdueTasksCount > 0)
                          _alertBadge(
                            icon: Icons.warning_amber_rounded,
                            count: alerts.overdueTasksCount,
                            label: 'Quá hạn',
                            color: Colors.red,
                          ),
                        if (alerts.pendingApprovalCount > 0)
                          _alertBadge(
                            icon: Icons.pending_actions,
                            count: alerts.pendingApprovalCount,
                            label: 'Chờ duyệt',
                            color: Colors.orange,
                          ),
                        if (alerts.newReportsCount > 0)
                          _alertBadge(
                            icon: Icons.analytics_outlined,
                            count: alerts.newReportsCount,
                            label: 'Báo cáo',
                            color: Colors.blue,
                          ),
                        if (alerts.unreadMessagesCount > 0)
                          _alertBadge(
                            icon: Icons.message_outlined,
                            count: alerts.unreadMessagesCount,
                            label: 'Tin nhắn',
                            color: Colors.purple,
                          ),
                      ],
                    ),
                  );
                },
              ),
              // Row 3: Address
              if (c.address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(c.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ],
              // Row 3: Contact info
              const SizedBox(height: 6),
              Row(
                children: [
                  if (c.phone != null && c.phone!.isNotEmpty) ...[
                    Icon(Icons.phone_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(c.phone!, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                  ],
                  if (c.email != null && c.email!.isNotEmpty) ...[
                    Icon(Icons.email_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(c.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ),
                  ],
                  if (c.createdAt != null) ...[
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(c.createdAt!),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Alert badge widget for company notifications
  Widget _alertBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigate to Company Details Page ──
  void _showCompanyDetail(BuildContext context, Company c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: c.id),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// SUB-TAB 4: NỘI DUNG — Content pipeline + list
// ─────────────────────────────────────────────────
class _MediaContentSubTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MediaContentSubTab> createState() => _MediaContentSubTabState();
}

class _MediaContentSubTabState extends ConsumerState<_MediaContentSubTab> {
  String? _filterPlatform; // null = all

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final content = ref.watch(allContentProvider(companyId));
    final pipeline = ref.watch(contentPipelineStatsProvider(companyId));
    final channels = ref.watch(mediaChannelsProvider(companyId));

    // Build channel maps for filtering & display
    final channelMap = <String, String>{};
    final channelPlatformMap = <String, String>{};
    channels.whenData((chs) {
      for (final c in chs) {
        channelMap[c.id] = '${c.platformIcon} ${c.name}';
        channelPlatformMap[c.id] = c.platform;
      }
    });

    // Get unique platforms from channels
    final platforms = <String>[];
    channels.whenData((chs) {
      final seen = <String>{};
      for (final c in chs) {
        if (seen.add(c.platform)) platforms.add(c.platform);
      }
    });

    const platformLabels = <String, (String, String)>{
      'youtube': ('🔴', 'YouTube'),
      'tiktok': ('🎵', 'TikTok'),
      'facebook': ('🔵', 'Facebook'),
      'instagram': ('📸', 'Instagram'),
      'twitter': ('🐦', 'Twitter/X'),
      'linkedin': ('💼', 'LinkedIn'),
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allContentProvider);
        ref.invalidate(contentPipelineStatsProvider);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text('Nội dung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const ContentFormPage()),
                          );
                          if (result == true) {
                            ref.invalidate(contentCalendarProvider);
                            ref.invalidate(allContentProvider);
                            ref.invalidate(contentPipelineStatsProvider);
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Tạo content', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Platform filter chips
                  if (platforms.isNotEmpty)
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip(null, '📋 Tất cả', platformLabels),
                          ...platforms.map((p) => _filterChip(p, null, platformLabels)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Pipeline stages bar
                  pipeline.when(
                    data: (stats) {
                      final total = stats['total'] ?? 0;
                      if (total == 0) return const SizedBox();
                      final stages = [
                        ('Ý tưởng', (stats['idea'] ?? 0) + (stats['planned'] ?? 0), Colors.blue),
                        ('Kịch bản', stats['scripting'] ?? 0, Colors.indigo),
                        ('Quay', stats['filming'] ?? 0, Colors.orange),
                        ('Dựng', stats['editing'] ?? 0, Colors.purple),
                        ('Duyệt', (stats['review'] ?? 0) + (stats['scheduled'] ?? 0), Colors.teal),
                        ('Đã đăng', stats['published'] ?? 0, Colors.green),
                      ];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Column(
                          children: stages.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              SizedBox(width: 60, child: Text(s.$1, style: const TextStyle(fontSize: 11))),
                              Expanded(child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? s.$2 / total : 0, minHeight: 14,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation((s.$3 as Color).withValues(alpha: 0.7)),
                                ),
                              )),
                              const SizedBox(width: 8),
                              SizedBox(width: 20, child: Text('${s.$2}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                            ]),
                          )).toList(),
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Content list (filtered by platform)
          content.when(
            data: (list) {
              // Apply platform filter
              final filtered = _filterPlatform == null
                  ? list
                  : list.where((item) {
                      if (item.channelId == null) return false;
                      return channelPlatformMap[item.channelId!] == _filterPlatform;
                    }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _filterPlatform != null ? 'Không có content cho nền tảng này' : 'Chưa có content',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Tạo content đầu tiên để quản lý pipeline sản xuất.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildContentCard(context, ref, filtered[i], channelMap, companyId),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Lỗi: $e'))),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, WidgetRef ref, ContentCalendar item, Map<String, String> channelMap, String companyId) {
    final statusColor = _statusColor(item.status);
    final channelLabel = item.channelId != null ? channelMap[item.channelId!] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.isOverdue ? Border.all(color: Colors.red.shade300, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Content type icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(_contentTypeIcon(item.contentType), size: 16, color: statusColor),
              ),
              const SizedBox(width: 10),
              // Title + channel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (channelLabel != null)
                      Text(channelLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              // Action menu
              PopupMenuButton<String>(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => ContentFormPage(content: item)),
                      );
                      if (result == true) {
                        ref.invalidate(allContentProvider);
                        ref.invalidate(contentPipelineStatsProvider);
                      }
                    case 'next_status':
                      _advanceStatus(context, ref, item);
                    case 'delete':
                      _confirmDeleteContent(context, ref, item);
                  }
                },
                itemBuilder: (_) => [
                  if (_nextStatus(item.status) != null)
                    PopupMenuItem(value: 'next_status', child: ListTile(
                      dense: true, leading: const Icon(Icons.arrow_forward, size: 18, color: Colors.blue),
                      title: Text('→ ${_nextStatus(item.status)!.label}', style: const TextStyle(fontSize: 13)),
                    )),
                  const PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit, size: 18), title: Text('Chỉnh sửa', style: TextStyle(fontSize: 13)))),
                  const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, size: 18, color: Colors.red), title: Text('Xóa', style: TextStyle(fontSize: 13, color: Colors.red)))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom row: type + date + progress
          Row(
            children: [
              Text(item.contentType.label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(width: 8),
              if (item.deadline != null) ...[
                Icon(Icons.event, size: 12, color: item.isOverdue ? Colors.red : Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  DateFormat('dd/MM').format(item.deadline!),
                  style: TextStyle(fontSize: 10, color: item.isOverdue ? Colors.red : Colors.grey.shade500,
                    fontWeight: item.isOverdue ? FontWeight.w600 : FontWeight.normal),
                ),
              ],
              if (item.assignedToName != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Expanded(child: Text(item.assignedToName!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
              ] else
                const Spacer(),
              // Progress pill
              Container(
                width: 50, height: 4,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: Colors.grey.shade200),
                child: FractionallySizedBox(
                  widthFactor: item.pipelineProgress,
                  alignment: Alignment.centerLeft,
                  child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: statusColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ContentStatus s) {
    switch (s) {
      case ContentStatus.idea: case ContentStatus.planned: return Colors.blue;
      case ContentStatus.scripting: return Colors.indigo;
      case ContentStatus.filming: return Colors.orange;
      case ContentStatus.editing: return Colors.purple;
      case ContentStatus.review: case ContentStatus.scheduled: return Colors.teal;
      case ContentStatus.published: return Colors.green;
      case ContentStatus.cancelled: return Colors.grey;
    }
  }

  IconData _contentTypeIcon(ContentType t) {
    switch (t) {
      case ContentType.video: return Icons.videocam;
      case ContentType.short: case ContentType.reel: return Icons.movie;
      case ContentType.story: return Icons.amp_stories;
      case ContentType.article: case ContentType.post: return Icons.article;
      case ContentType.livestream: return Icons.live_tv;
      case ContentType.podcast: return Icons.podcasts;
      case ContentType.other: return Icons.content_paste;
    }
  }

  ContentStatus? _nextStatus(ContentStatus current) {
    const flow = [
      ContentStatus.idea, ContentStatus.planned, ContentStatus.scripting,
      ContentStatus.filming, ContentStatus.editing, ContentStatus.review,
      ContentStatus.scheduled, ContentStatus.published,
    ];
    final idx = flow.indexOf(current);
    if (idx < 0 || idx >= flow.length - 1) return null;
    return flow[idx + 1];
  }

  void _advanceStatus(BuildContext context, WidgetRef ref, ContentCalendar item) async {
    final next = _nextStatus(item.status);
    if (next == null) return;
    try {
      final actions = ref.read(contentActionsProvider);
      await actions.updateStatus(item.id, next);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${item.title} → ${next.label}'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmDeleteContent(BuildContext context, WidgetRef ref, ContentCalendar item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa content?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('Bạn có chắc muốn xóa "${item.title}"?', style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () async {
              try {
                final actions = ref.read(contentActionsProvider);
                await actions.deleteContent(item.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa content'), behavior: SnackBarBehavior.floating));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? platform, String? label, Map<String, (String, String)> platformLabels) {
    final isSelected = _filterPlatform == platform;
    final displayLabel = label ?? '${platformLabels[platform]?.$1 ?? ''} ${platformLabels[platform]?.$2 ?? platform}';
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(displayLabel, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _filterPlatform = platform),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3: TOURNAMENT COMMAND — "Compete or Die"
// ═══════════════════════════════════════════════════════════════════
class _TournamentCommandTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final tournaments = ref.watch(tournamentsProvider(companyId));
    final events = ref.watch(eventsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tournamentsProvider);
        ref.invalidate(eventsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tournament Command',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Giải đấu billiard & Sự kiện',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // Tournaments
            tournaments.when(
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyTournament(context, ref, companyId);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Giải đấu',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${list.length} giải',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.amber, size: 28),
                          tooltip: 'Tạo giải đấu',
                          onPressed: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TournamentFormPage()),
                            );
                            if (result == true) {
                              ref.invalidate(tournamentsProvider);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...list.map((t) => _buildTournamentCard(t, context, ref)),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildEmptyTournament(context, ref, companyId),
            ),

            const SizedBox(height: 20),

            // Events
            events.when(
              data: (list) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Sự kiện',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (list.isNotEmpty)
                          Text('${list.length} sự kiện',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                          tooltip: 'Tạo sự kiện',
                          onPressed: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EventFormPage()),
                            );
                            if (result == true) {
                              ref.invalidate(eventsProvider);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (list.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Chưa có sự kiện nào',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ),
                      )
                    else
                      ...list.map((e) => _buildEventCard(e, context, ref)),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTournament(
      BuildContext context, WidgetRef ref, String companyId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
          const SizedBox(height: 12),
          const Text('Chưa có giải đấu nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Tạo giải đấu billiard đầu tiên cho SABO!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => const TournamentFormPage()),
              );
              if (result == true) {
                ref.invalidate(tournamentsProvider);
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo giải đấu'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard(dynamic t, [BuildContext? ctx, WidgetRef? wRef]) {
    Color statusColor;
    switch (t.status.value) {
      case 'in_progress':
        statusColor = Colors.green;
        break;
      case 'registration_open':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.status.label,
                  style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tournamentInfo(Icons.sports, t.gameType.label),
              const SizedBox(width: 16),
              _tournamentInfo(
                  Icons.people, '${t.currentParticipants}/${t.maxParticipants}'),
              const SizedBox(width: 16),
              if (t.prizePool > 0)
                _tournamentInfo(Icons.monetization_on, _fmtMoney(t.prizePool)),
            ],
          ),
          if (ctx != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => TournamentFormPage(tournament: t)),
                    );
                    if (result == true) {
                      wRef?.invalidate(tournamentsProvider);
                    }
                  },
                ),
              ],
            ),
          if (t.startDate != null) ...[
            const SizedBox(height: 6),
            Text(
              '${DateFormat('dd/MM/yyyy').format(t.startDate!)}${t.endDate != null ? ' → ${DateFormat('dd/MM/yyyy').format(t.endDate!)}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(dynamic e, [BuildContext? ctx, WidgetRef? wRef]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              e.isOnline ? Icons.videocam : Icons.location_on,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${e.eventType.label} · ${e.status.label}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (e.startDate != null)
            Text(
              DateFormat('dd/MM').format(e.startDate!),
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            ),
          if (ctx != null) ...[            const SizedBox(width: 4),
            InkWell(
              onTap: () async {
                final result = await Navigator.push<bool>(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => EventFormPage(event: e)),
                );
                if (result == true) {
                  wRef?.invalidate(eventsProvider);
                }
              },
              child: const Icon(Icons.edit, size: 16, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tournamentInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  String _fmtMoney(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return '${v.toInt()}đ';
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4: NHIỆM VỤ — Task Management
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
// TAB 5: TĂNG TRƯỞNG — Growth Metrics
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
      final thisMonthStart =
          DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
      final lastMonthStart = DateTime(now.year, now.month - 1, 1)
          .toIso8601String()
          .split('T')[0];
      final thirtyDaysAgo = now
          .subtract(const Duration(days: 30))
          .toIso8601String()
          .split('T')[0];

      final results = await Future.wait([
        sb.from('daily_revenue').select('date, total_revenue')
            .eq('company_id', companyId)
            .gte('date', thirtyDaysAgo)
            .order('date'),
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', thisMonthStart),
        sb.from('daily_revenue').select('total_revenue')
            .eq('company_id', companyId)
            .gte('date', lastMonthStart)
            .lt('date', thisMonthStart),
        sb.from('table_sessions').select('id')
            .eq('company_id', companyId)
            .gte('start_time', '${thisMonthStart}T00:00:00'),
        sb.from('table_sessions').select('id')
            .eq('company_id', companyId)
            .gte('start_time', '${lastMonthStart}T00:00:00')
            .lt('start_time', '${thisMonthStart}T00:00:00'),
      ]);

      if (mounted) {
        setState(() {
          _last30DaysRevenue =
              List<Map<String, dynamic>>.from(results[0] as List);
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
    return '${v.toInt()}đ';
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
            const Text('Tăng trưởng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('So sánh tháng này vs tháng trước',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // MoM cards
            Row(
              children: [
                _buildGrowthCard('Doanh thu tháng', _fmt(_thisMonthTotal),
                    revenueGrowth, isRevenueUp, Icons.payments),
                const SizedBox(width: 12),
                _buildGrowthCard('Phiên chơi', '$_thisMonthSessions',
                    sessionGrowth, isSessionsUp, Icons.receipt_long),
              ],
            ),
            const SizedBox(height: 20),

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
                    Icon(Icons.bar_chart,
                        size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text('Chưa có dữ liệu doanh thu',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            else
              _buildSimpleTrendChart(),

            const SizedBox(height: 20),

            if (_last30DaysRevenue.isNotEmpty) _buildInsightRow(),

            const SizedBox(height: 16),

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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic)),
                  SizedBox(height: 4),
                  Text(
                      'Ra quyết định dựa trên data, không phải cảm xúc.',
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
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        isUp ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    growth,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isUp
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTrendChart() {
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
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
    var bestDay = _last30DaysRevenue[0];
    var worstDay = _last30DaysRevenue[0];
    for (final d in _last30DaysRevenue) {
      final v = (d['total_revenue'] as num?)?.toDouble() ?? 0;
      if (v > ((bestDay['total_revenue'] as num?)?.toDouble() ?? 0)) {
        bestDay = d;
      }
      if (v < ((worstDay['total_revenue'] as num?)?.toDouble() ?? 0)) {
        worstDay = d;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildInsightCard(
            'Ngày tốt nhất',
            bestDay['date']?.toString().substring(5) ?? '?',
            _fmt((bestDay['total_revenue'] as num?)?.toDouble() ?? 0),
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInsightCard(
            'Ngày yếu nhất',
            worstDay['date']?.toString().substring(5) ?? '?',
            _fmt((worstDay['total_revenue'] as num?)?.toDouble() ?? 0),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
      String title, String date, String revenue, Color color) {
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
          Text(title,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(revenue,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
