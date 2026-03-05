import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../../../widgets/bug_report_dialog.dart';

import '../../../pages/ceo/ceo_notifications_page.dart';
import '../../../pages/ceo/shared/ceo_more_page.dart';
import '../../../pages/ceo/ceo_employees_page.dart';
import '../../../pages/ceo/company_details_page.dart' hide companyStatsProvider;
import '../../../pages/manager/manager_tasks_page.dart';
import '../../../pages/manager/manager_attendance_page.dart';
import '../widgets/weekly_insight_widget.dart';

import '../../../core/router/app_router.dart';

import '../providers/session_provider.dart';
import '../providers/media_channel_provider.dart';
import '../widgets/notification_bell_widget.dart';
import '../providers/content_provider.dart';
import '../providers/media_project_provider.dart';
import '../models/media_channel.dart';
import '../models/content.dart';

import '../pages/sessions/session_list_page.dart';
import '../pages/menu/menu_list_page.dart';
import '../pages/reports/manager_approval_page.dart';
import '../pages/cashflow/daily_cashflow_import_page.dart';
import '../pages/manager/staff_performance_page.dart';
import '../pages/reservations/reservation_list_page.dart';

import '../../../models/company.dart';
import '../../../models/project.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/company_alerts_provider.dart';
import '../../../providers/project_provider.dart';
import '../providers/monthly_pnl_provider.dart';
import '../../../pages/schedules/schedule_list_page.dart';
import '../pages/schedule/shift_schedule_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// ═══════════════════════════════════════════════════════
/// SABO Service Manager Command Center — Musk Style
/// ═══════════════════════════════════════════════════════
/// 4 tabs: Command | Dự án | Nhiệm vụ | Media
/// Manager sees STRATEGY across all divisions
class ServiceManagerLayout extends ConsumerStatefulWidget {
  const ServiceManagerLayout({super.key});

  @override
  ConsumerState<ServiceManagerLayout> createState() =>
      _ServiceManagerLayoutState();
}

class _ServiceManagerLayoutState extends ConsumerState<ServiceManagerLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final companyName = user?.companyName ?? 'SABO';
    final userName = user?.name ?? 'Quản lý';

    final pages = <Widget>[
      _ManagerOverviewTab(
        onSwitchTab: (i) => setState(() => _currentIndex = i),
      ),
      _ManagerProjectsTab(),
      _ManagerTeamTab(),
      _ManagerAttendanceTab(),
      _ManagerMediaTab(),
      StaffPerformancePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              companyName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            Text(
              '🎯 Quản lý — $userName',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.surface54),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.surface),
        actions: [
          const NotificationBellWidget(),
          const RealtimeNotificationBell(),
          IconButton(
            tooltip: 'Nhập báo cáo cuối ngày',
            icon: Icon(Icons.upload_file_outlined, color: Color(0xFFFBBF24)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyCashflowImportPage(
                    companyId: user?.companyId ?? '',
                    companyName: user?.companyName ?? 'SABO',
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.surface70),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push(AppRoutes.profile);
                  break;
                case 'notifications':
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const CEONotificationsPage()));
                  break;
                case 'settings':
                  context.push(AppRoutes.ceoSettings);
                  break;
                case 'bug_report':
                  BugReportDialog.show(context);
                  break;
                case 'more':
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CEOMorePage()));
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.person_outline),
                    title: Text('Hồ sơ cá nhân'),
                  )),
              PopupMenuItem(
                  value: 'notifications',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.notifications_outlined),
                    title: Text('Thông báo'),
                  )),
              PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Cài đặt'),
                  )),
              PopupMenuItem(
                  value: 'bug_report',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.bug_report_outlined),
                    title: Text('Báo cáo lỗi'),
                  )),
              PopupMenuItem(
                  value: 'more',
                  child: ListTile(
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: Colors.deepPurple),
            label: 'Dự án',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Nhiệm vụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule, color: Colors.teal),
            label: 'Chấm công',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle, color: Colors.red),
            label: 'Media',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.info),
            label: 'Nhân viên',
          ),
        ],
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════
// TAB 1: MANAGER OVERVIEW — Operational Command
// ═══════════════════════════════════════════════════════════════════
class _ManagerOverviewTab extends ConsumerStatefulWidget {
  final void Function(int) onSwitchTab;
  const _ManagerOverviewTab({required this.onSwitchTab});

  @override
  ConsumerState<_ManagerOverviewTab> createState() =>
      _ManagerOverviewTabState();
}

class _ManagerOverviewTabState extends ConsumerState<_ManagerOverviewTab> {
  bool _isLoading = true;
  int _totalEmployees = 0;
  int _activeEmployees = 0;
  double _todayRevenue = 0;
  double _weekRevenue = 0;
  int _pendingTasks = 0;

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
                        _formatRevenue(_todayRevenue),
                        Icons.today,
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _miniCard(
                        'Tuần này',
                        _formatRevenue(_weekRevenue),
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
                        'Phiên hoạt động',
                        sessionStats.when(
                          data: (s) => '${s['activeSessions'] ?? 0}',
                          loading: () => '...',
                          error: (_, __) => '—',
                        ),
                        Icons.timer,
                        Colors.orange,
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
                            return _formatRevenue(rev);
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
                            _formatNumber(totalSubs),
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

                  // Weekly insight
                  const WeeklyInsightWidget(),
                  const SizedBox(height: 16),

                  // ── Quick Actions ──
                  _sectionHeader('⚡ Truy cập nhanh'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAction(context, 
                          '🎱 Vận hành', () => widget.onSwitchTab(1)),
                      _quickAction(context, 
                          '📋 Công việc', () => widget.onSwitchTab(2)),
                      _quickAction(context, 
                          '⏱️ Chấm công', () => widget.onSwitchTab(3)),
                      _quickAction(context, 
                          '📺 Media', () => widget.onSwitchTab(4)),
                      _quickAction(context, '🗓️ Đặt bàn', () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReservationListPage()));
                      }),
                      _quickAction(context, '✅ Duyệt báo cáo', () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ManagerApprovalPage()));
                      }),
                      _quickAction(context, '📅 Chia ca', () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShiftSchedulePage()));
                      }),
                      _quickAction(context, '�👤 Hồ sơ', () {
                        context.push(AppRoutes.profile);
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
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _miniCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
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

  Widget _quickAction(BuildContext context, String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  String _formatRevenue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: DỰ ÁN — Manager's companies view
// Manager can manage multiple companies (via manager_companies table)
// ═══════════════════════════════════════════════════════════════════
class _ManagerProjectsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManagerProjectsTab> createState() => _ManagerProjectsTabState();
}

class _ManagerProjectsTabState extends ConsumerState<_ManagerProjectsTab> {
  List<String> _assignedCompanyIds = [];
  String? _primaryCompanyId;
  bool _isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedCompanies();
  }

  Future<void> _loadAssignedCompanies() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoadingAssignments = false);
      return;
    }
    
    try {
      final response = await Supabase.instance.client
          .from('manager_companies')
          .select()
          .eq('manager_id', user.id);
      
      final List<String> ids = [];
      String? primary;
      for (final row in response as List) {
        ids.add(row['company_id'] as String);
        if (row['is_primary'] == true) {
          primary = row['company_id'] as String;
        }
      }
      
      if (mounted) {
        setState(() {
          _assignedCompanyIds = ids;
          _primaryCompanyId = primary;
          _isLoadingAssignments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssignments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use allCompaniesAdminProvider instead of companiesProvider
    // companiesProvider filters by ownership (CEO), but manager needs assigned companies
    final companiesAsync = ref.watch(allCompaniesAdminProvider);

    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (allCompanies) {
        // Filter to only show manager's assigned companies
        final myCompanies = allCompanies
            .where((c) => _assignedCompanyIds.contains(c.id))
            .toList();
        
        if (myCompanies.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Chưa được gán công ty',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Liên hệ CEO để được phân quyền',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        // Single company view
        if (myCompanies.length == 1) {
          final company = myCompanies.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text('Công ty của tôi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCompanyCard(context, company),
                const SizedBox(height: 20),
                _buildQuickStats(context, company.id),
                const SizedBox(height: 20),
                _buildProjectsSection(context, company.id),
                const SizedBox(height: 20),
                _buildFinancialDashboard(context, company.id),
              ],
            ),
          );
        }

        // Multiple companies view
        return Column(
          children: [
            // Stats bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Icon(Icons.business, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text('Công ty quản lý: ${myCompanies.length}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // Company list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: myCompanies.length,
                itemBuilder: (context, index) {
                  final c = myCompanies[index];
                  final isPrimary = c.id == _primaryCompanyId;
                  return Stack(
                    children: [
                      _buildCompanyCard(context, c),
                      if (isPrimary)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text('Chính', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context, String companyId) {
    return Consumer(builder: (context, ref, _) {
      final statsAsync = ref.watch(companyStatsProvider(companyId));
      return statsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (stats) => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Thống kê nhanh',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statItem('Nhân viên', '${stats['employees'] ?? 0}', Icons.people_outline, AppColors.info),
                  _statItem('Chi nhánh', '${stats['branches'] ?? 0}', Icons.store_outlined, AppColors.warning),
                  _statItem('Bàn', '${stats['tables'] ?? 0}', Icons.table_bar, AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  /// Projects section showing projects and sub-projects
  Widget _buildProjectsSection(BuildContext context, String companyId) {
    return Consumer(builder: (context, ref, _) {
      final projectsAsync = ref.watch(companyProjectsProvider(companyId));
      
      return projectsAsync.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Lỗi: $e', style: TextStyle(color: Colors.red.shade400)),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có dự án',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text('Tạo dự án mới để quản lý công việc',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.folder_special, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Dự án',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${projects.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Project list
                ...projects.map((project) => _buildProjectTile(project)),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildProjectTile(Project project) {
    return InkWell(
      onTap: () => _showProjectDetail(context, project),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project name + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: project.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(project.status.icon, size: 12, color: project.status.color),
                      const SizedBox(width: 4),
                      Text(
                        project.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: project.status.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        project.progress >= 100 
                            ? AppColors.success 
                            : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${project.progress}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: project.progress >= 100 
                        ? AppColors.success 
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            // Priority badge
            if (project.priority != ProjectPriority.medium) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: project.priority.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.priority.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: project.priority.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showProjectDetail(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectDetailSheet(project: project),
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

  // ── Navigate to full Company Details Page ──
  void _showCompanyDetail(BuildContext context, Company c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: c.id),
      ),
    );
  }

  // ── Company Detail Bottom Sheet (legacy, kept for reference) ──
  // ignore: unused_element
  void _showCompanyDetailBottomSheet(BuildContext context, Company c) {
    final typeColor = c.type.color;
    final isActive = c.status == 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(builder: (context, ref, _) {
        final statsAsync = ref.watch(companyStatsProvider(c.id));
        return DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(c.type.icon, size: 24, color: typeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(c.type.label,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isActive ? AppColors.success : Colors.grey).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Tạm ngưng',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Stats from provider
                    statsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stats) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _statItem('Nhân viên', '${stats['employees'] ?? 0}', Icons.people_outline, AppColors.info),
                            _statItem('Chi nhánh', '${stats['branches'] ?? 0}', Icons.store_outlined, AppColors.warning),
                            _statItem('Bàn', '${stats['tables'] ?? 0}', Icons.table_bar, AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Info grid
                    if (c.address.isNotEmpty)
                      _infoRow(Icons.location_on_outlined, 'Địa chỉ', c.address),
                    if (c.phone != null && c.phone!.isNotEmpty)
                      _infoRow(Icons.phone_outlined, 'Điện thoại', c.phone!),
                    if (c.email != null && c.email!.isNotEmpty)
                      _infoRow(Icons.email_outlined, 'Email', c.email!),
                    if (c.createdAt != null)
                      _infoRow(Icons.calendar_today_outlined, 'Ngày tạo',
                          DateFormat('dd/MM/yyyy').format(c.createdAt!)),
                    // Bank info
                    if (c.activeBankNameValue != null && c.activeBankNameValue!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance, size: 16, color: Colors.blue.shade700),
                                const SizedBox(width: 6),
                                Text('Tài khoản ngân hàng',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${c.activeBankNameValue}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            if (c.activeBankAccountNumberValue != null)
                              Text(c.activeBankAccountNumberValue!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            if (c.activeBankAccountNameValue != null)
                              Text(c.activeBankAccountNameValue!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                    // ── Import Báo Cáo button ──
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyCashflowImportPage(
                                companyId: c.id,
                                companyName: c.name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('Import Báo Cáo Cuối Ngày'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    // ── Financial Dashboard ──
                    const SizedBox(height: 20),
                    _buildFinancialDashboard(context, c.id),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Financial Dashboard Widget ──
  Widget _buildFinancialDashboard(BuildContext context, String companyId) {
    return Consumer(builder: (context, ref, _) {
    final summaryAsync = ref.watch(financialSummaryProvider(companyId));

    return summaryAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (summary) {
        if (summary['hasData'] != true) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, size: 24, color: Colors.grey.shade400),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Chưa có dữ liệu tài chính',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ),
              ],
            ),
          );
        }

        final latestRevenue = summary['latestNetRevenue'] as double;
        final latestProfit = summary['latestNetProfit'] as double;
        final latestMargin = summary['latestNetMargin'] as double;
        final growthPct = summary['revenueGrowthPct'] as double;
        final totalRevenue12m = summary['totalRevenue12m'] as double;
        final totalProfit12m = summary['totalProfit12m'] as double;
        final latestMonth = summary['latestMonth'] as String;
        final isProfitable = summary['isProfitable'] as bool;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(Icons.analytics, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Text('Báo cáo tài chính',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Live',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Latest month summary card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isProfitable
                      ? [Colors.green.shade50, Colors.green.shade100]
                      : [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isProfitable ? Colors.green.shade200 : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tháng $latestMonth',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700)),
                      const Spacer(),
                      if (growthPct != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: growthPct > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${growthPct > 0 ? '+' : ''}${growthPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _financialMetric(
                          'Doanh thu',
                          _formatCurrency(latestRevenue),
                          Icons.trending_up,
                          Colors.blue.shade700,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Expanded(
                        child: _financialMetric(
                          'Lợi nhuận',
                          _formatCurrency(latestProfit),
                          isProfitable ? Icons.arrow_upward : Icons.arrow_downward,
                          isProfitable ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.grey.shade300),
                      Expanded(
                        child: _financialMetric(
                          'Biên LN',
                          '${latestMargin.toStringAsFixed(1)}%',
                          Icons.percent,
                          Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 12-month totals
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng 12 tháng gần nhất',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Doanh thu',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text(_formatCurrency(totalRevenue12m),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lợi nhuận',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            Text(_formatCurrency(totalProfit12m),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: totalProfit12m >= 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    });
  }

  Widget _financialMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(1)}B';
    }
    if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(value);
  }
}

// ═══════════════════════════════════════════════════════════════════
// [DEPRECATED] TAB 2: VẬN HÀNH — Operations Command (replaced by Dự án)
// Sub-tabs: Bàn | Phiên | Thực đơn
// ═══════════════════════════════════════════════════════════════════
class _OperationsCommandTab extends StatefulWidget {
  @override
  State<_OperationsCommandTab> createState() => _OperationsCommandTabState();
}

class _OperationsCommandTabState extends State<_OperationsCommandTab>
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
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                  icon: Icon(Icons.timer_rounded, size: 18),
                  text: 'Phiên'),
              Tab(
                  icon: Icon(Icons.restaurant_menu_rounded, size: 18),
                  text: 'Thực đơn'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              SessionListPage(),
              MenuListPage(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3: NHIỆM VỤ — Tasks + Employees
// Sub-tabs: Công việc | Nhân viên
// ═══════════════════════════════════════════════════════════════════
class _ManagerTeamTab extends StatefulWidget {
  @override
  State<_ManagerTeamTab> createState() => _ManagerTeamTabState();
}

class _ManagerTeamTabState extends State<_ManagerTeamTab>
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
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(
                  icon: Icon(Icons.assignment_rounded, size: 18),
                  text: 'Công việc'),
              Tab(
                  icon: Icon(Icons.people_rounded, size: 18),
                  text: 'Nhân viên'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ManagerTasksPage(),
              CEOEmployeesPage(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4: CHẤM CÔNG — Attendance & Work Schedule
// Sub-tabs: Chấm công | Lịch làm việc
// ═══════════════════════════════════════════════════════════════════
class _ManagerAttendanceTab extends StatefulWidget {
  @override
  State<_ManagerAttendanceTab> createState() => _ManagerAttendanceTabState();
}

class _ManagerAttendanceTabState extends State<_ManagerAttendanceTab>
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
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: const [
              Tab(
                icon: Icon(Icons.access_time_rounded, size: 18),
                text: 'Chấm công',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_rounded, size: 18),
                text: 'Lịch làm việc',
              ),
              Tab(
                icon: Icon(Icons.event_note_rounded, size: 18),
                text: 'Chia ca',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ManagerAttendancePage(),
              ScheduleListPage(),
              ShiftSchedulePage(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 5: MEDIA — Channels / Projects / Content
// Sub-tabs: Kênh | Dự án | Nội dung
// ═══════════════════════════════════════════════════════════════════
class _ManagerMediaTab extends StatefulWidget {
  @override
  State<_ManagerMediaTab> createState() => _ManagerMediaTabState();
}

class _ManagerMediaTabState extends State<_ManagerMediaTab>
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
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(
                  icon: Icon(Icons.play_circle_outline, size: 18),
                  text: 'Kênh'),
              Tab(
                  icon: Icon(Icons.folder_special_rounded, size: 18),
                  text: 'Dự án'),
              Tab(
                  icon: Icon(Icons.calendar_month, size: 18),
                  text: 'Nội dung'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ManagerChannelsSubTab(),
              _ManagerProjectsSubTab(),
              _ManagerContentSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// MEDIA SUB-TAB 1: Kênh
// ─────────────────────────────────────────────────
class _ManagerChannelsSubTab extends ConsumerWidget {
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
                  Icon(Icons.play_circle_outline,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Chưa có kênh nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Group by platform
          final grouped = <String, List<MediaChannel>>{};
          for (final ch in list) {
            grouped.putIfAbsent(ch.platform, () => []).add(ch);
          }
          final platformOrder = [
            'youtube',
            'tiktok',
            'facebook',
            'instagram'
          ];
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              final ia = platformOrder.indexOf(a);
              final ib = platformOrder.indexOf(b);
              return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final platform = sortedKeys[index];
              final items = grouped[platform]!;
              final platformIcons = {
                'youtube': '🔴 YouTube',
                'tiktok': '🎵 TikTok',
                'facebook': '🔵 Facebook',
                'instagram': '📸 Instagram',
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      platformIcons[platform] ?? '📱 $platform',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...items.map((ch) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                                color: Colors.grey.shade200)),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade100,
                            child: Text(
                              ch.name.isNotEmpty
                                  ? ch.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          title: Text(ch.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${NumberFormat.compact().format(ch.followersCount)} subs · ${NumberFormat.compact().format(ch.viewsCount)} views',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                          trailing: Icon(Icons.chevron_right,
                              size: 18, color: Colors.grey.shade400),
                        ),
                      )),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// MEDIA SUB-TAB 2: Dự án
// ─────────────────────────────────────────────────
class _ManagerProjectsSubTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final projectsAsync = ref.watch(mediaProjectsProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(mediaProjectsProvider),
      child: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off_rounded,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Chưa có dự án nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final p = projects[index];
              Color projectColor;
              try {
                projectColor = Color(
                    int.parse(p.color.replaceFirst('#', '0xFF')));
              } catch (_) {
                projectColor = AppColors.primary;
              }

              final statusColors = {
                'active': AppColors.success,
                'planning': AppColors.info,
                'paused': AppColors.warning,
                'completed': AppColors.primary,
                'cancelled': AppColors.error,
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                        left: BorderSide(
                            color: projectColor, width: 4)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (statusColors[p.status] ??
                                      Colors.grey)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p.statusLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: statusColors[p.status] ??
                                        Colors.grey)),
                          ),
                        ],
                      ),
                      if (p.description != null &&
                          p.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(p.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...p.platformIcons.map((icon) => Padding(
                                padding:
                                    const EdgeInsets.only(right: 4),
                                child: Text(icon,
                                    style: const TextStyle(
                                        fontSize: 14)),
                              )),
                          const Spacer(),
                          Text(
                              '${p.completedCount}/${p.contentCount} nội dung',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.progress,
                          backgroundColor: Colors.grey.shade200,
                          color: AppColors.success,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// MEDIA SUB-TAB 3: Nội dung
// ─────────────────────────────────────────────────
class _ManagerContentSubTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final companyId = user?.companyId ?? '';
    final contentAsync = ref.watch(allContentProvider(companyId));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allContentProvider),
      child: contentAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Chưa có nội dung nào',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Pipeline stats
          final statusCounts = <String, int>{};
          for (final c in list) {
            statusCounts[c.status.name] =
                (statusCounts[c.status.name] ?? 0) + 1;
          }

          return Column(
            children: [
              // Pipeline summary
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                color: Theme.of(context).colorScheme.surface,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _pipelineChip('Tổng', list.length, Colors.grey),
                      _pipelineChip(
                          'Draft',
                          statusCounts['draft'] ?? 0,
                          Colors.grey.shade600),
                      _pipelineChip(
                          'Review',
                          statusCounts['in_review'] ?? 0,
                          AppColors.warning),
                      _pipelineChip(
                          'Approved',
                          statusCounts['approved'] ?? 0,
                          AppColors.info),
                      _pipelineChip(
                          'Published',
                          statusCounts['published'] ?? 0,
                          AppColors.success),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final c = list[index];
                    final statusColors = {
                      ContentStatus.idea: Colors.grey,
                      ContentStatus.planned: AppColors.info,
                      ContentStatus.scripting: AppColors.info,
                      ContentStatus.filming: AppColors.warning,
                      ContentStatus.editing: AppColors.warning,
                      ContentStatus.review: Colors.blue,
                      ContentStatus.scheduled: Colors.purple,
                      ContentStatus.published: AppColors.success,
                      ContentStatus.cancelled: Colors.grey,
                    };
                    final color =
                        statusColors[c.status] ?? Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: Colors.grey.shade200)),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_contentTypeIcon(c.contentType),
                              size: 18, color: color),
                        ),
                        title: Text(c.title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.status.name.replaceAll('_', ' '),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: color),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (c.platform != null)
                              Text(c.platform!,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500)),
                          ],
                        ),
                        trailing: c.deadline != null
                            ? Text(
                                DateFormat('dd/MM')
                                    .format(c.deadline!),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  static Widget _pipelineChip(
      String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text('$label $count',
            style: TextStyle(fontSize: 10, color: color)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        backgroundColor: color.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 2),
      ),
    );
  }

  static IconData _contentTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.videocam;
      case ContentType.short:
        return Icons.play_arrow;
      case ContentType.livestream:
        return Icons.live_tv;
      case ContentType.post:
        return Icons.article;
      case ContentType.story:
        return Icons.auto_stories;
      case ContentType.reel:
        return Icons.movie;
      case ContentType.podcast:
        return Icons.podcasts;
      case ContentType.article:
        return Icons.text_snippet;
      case ContentType.other:
        return Icons.extension;
    }
  }
}

/// Bottom sheet showing project detail with sub-projects
class _ProjectDetailSheet extends ConsumerWidget {
  final Project project;
  const _ProjectDetailSheet({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subProjectsAsync = ref.watch(projectWithSubProjectsProvider(project.id));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: project.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_special,
                    color: project.status.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: project.status.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.status.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: project.status.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: project.priority.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              project.priority.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: project.priority.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          // Progress overview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ tổng',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${project.progress}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: project.progress >= 100
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: project.progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.progress >= 100
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    minHeight: 8,
                  ),
                ),
                if (project.startDate != null || project.endDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (project.startDate != null) ...[
                        Icon(Icons.play_circle_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(project.startDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (project.startDate != null && project.endDate != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward,
                              size: 12, color: Colors.grey.shade400),
                        ),
                      if (project.endDate != null) ...[
                        Icon(
                          project.isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.flag_outlined,
                          size: 14,
                          color: project.isOverdue
                              ? Colors.red
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(project.endDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: project.isOverdue
                                ? Colors.red
                                : Colors.grey.shade600,
                            fontWeight:
                                project.isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                        if (project.isOverdue) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(Quá hạn)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Description
          if (project.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                project.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Sub-projects header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.account_tree, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Công việc con',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Sub-projects list
          Expanded(
            child: subProjectsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Text('Lỗi: $e',
                    style: TextStyle(color: Colors.red.shade400)),
              ),
              data: (projectWithSubs) {
                final subProjects = projectWithSubs.subProjects;
                if (subProjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Chưa có công việc con',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            )),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: subProjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final sub = subProjects[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: sub.status.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: sub.status.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  sub.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sub.status.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(sub.status.icon,
                                        size: 10, color: sub.status.color),
                                    const SizedBox(width: 3),
                                    Text(
                                      sub.status.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: sub.status.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (sub.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              sub.description!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: sub.progress / 100,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      sub.progress >= 100
                                          ? AppColors.success
                                          : sub.status.color,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${sub.progress}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: sub.progress >= 100
                                      ? AppColors.success
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
