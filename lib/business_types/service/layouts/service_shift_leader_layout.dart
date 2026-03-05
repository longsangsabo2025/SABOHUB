import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../../../pages/staff/staff_checkin_page.dart';
import '../../../pages/shift_leader/shift_leader_reports_page.dart';
import '../pages/sessions/session_list_page.dart';
import '../pages/sessions/session_form_page.dart';
import '../pages/reports/shift_leader_review_page.dart';
import '../../../pages/schedules/schedule_list_page.dart';
import '../providers/session_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Service Shift Leader Layout — Billiards / F&B / Cafe / Hotel / Retail
/// 5 tabs: Tổng quan | Bàn | Phiên | Nhân viên | Báo cáo
class ServiceShiftLeaderLayout extends ConsumerStatefulWidget {
  const ServiceShiftLeaderLayout({super.key});

  @override
  ConsumerState<ServiceShiftLeaderLayout> createState() =>
      _ServiceShiftLeaderLayoutState();
}

class _ServiceShiftLeaderLayoutState
    extends ConsumerState<ServiceShiftLeaderLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Tổ trưởng';
    final companyName = user?.companyName ?? 'Sabo';

    final pages = <Widget>[
      const _ShiftLeaderOverviewPage(),
      const SessionListPage(),
      const StaffCheckinPage(),
      const ScheduleListPage(),
      const ShiftLeaderReviewPage(),
      ShiftLeaderReportsPage(),
    ];

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.manage_accounts, color: Colors.indigo.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '⭐ $userName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                ref.invalidate(allSessionsProvider);
                ref.invalidate(sessionStatsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã làm mới'), duration: Duration(seconds: 1)),
                );
              },
            ),
            const RealtimeNotificationBell(),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMenu(context),
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Phiên',
            ),
            NavigationDestination(
              icon: Icon(Icons.fingerprint_outlined),
              selectedIcon: Icon(Icons.fingerprint),
              label: 'Check-in',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Lịch ca',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Duyệt',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Báo cáo',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SessionFormPage()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('Mở phiên'),
                backgroundColor: Colors.indigo,
                foregroundColor: Theme.of(context).colorScheme.surface,
              )
            : null,
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.people_outline, color: Colors.indigo.shade400),
              title: const Text('Quản lý nhóm'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Hồ sơ cá nhân'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.bug_report_outlined, color: Colors.red.shade400),
              title: const Text('Báo cáo lỗi'),
              onTap: () {
                Navigator.pop(ctx);
                BugReportDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────────────────
class _ShiftLeaderOverviewPage extends ConsumerWidget {
  const _ShiftLeaderOverviewPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sessionStats = ref.watch(sessionStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sessionStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade700, Colors.indigo.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.companyName ?? 'Sabo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '⭐ Tổ trưởng: ${user?.name ?? ''}  •  ${_todayLabel()}',
                    style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    icon: Icons.done_all,
                    label: 'Xong hôm nay',
                    valueAsync: sessionStats,
                    valueKey: 'completedToday',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _revenueCard(context, sessionStats),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick actions
            Row(
              children: [
                const Text(
                  'Phiên đang hoạt động',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Làm mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ActiveSessions(),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Widget _statCard(BuildContext context, {
    required IconData icon,
    required String label,
    required AsyncValue<Map<String, dynamic>> valueAsync,
    required String valueKey,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valueAsync.when(
              data: (s) => '${s[valueKey] ?? 0}',
              loading: () => '…',
              error: (_, __) => '—',
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _revenueCard(BuildContext context, AsyncValue<Map<String, dynamic>> sessionStats) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.attach_money, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(
            sessionStats.when(
              data: (s) {
                final rev = (s['todayRevenue'] as num?)?.toDouble() ?? 0;
                if (rev >= 1000000) return '${(rev / 1000000).toStringAsFixed(1)}M';
                if (rev >= 1000) return '${(rev / 1000).toStringAsFixed(0)}K';
                return '${rev.toStringAsFixed(0)}đ';
              },
              loading: () => '…',
              error: (_, __) => '—',
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text('Doanh thu', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ActiveSessions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = ref.watch(activeSessionsProvider);

    return activeSessions.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.table_bar, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có phiên nào đang chơi',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: sessions.map((session) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Icon(Icons.sports_esports, color: Colors.indigo.shade700),
                ),
                title: Text(
                  session.tableName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${session.customerName ?? 'Khách vãng lai'} · ${session.playingTimeFormatted}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(session.calculateTableAmount() / 1000).toStringAsFixed(0)}K',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: session.status.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        session.status.label,
                        style: TextStyle(fontSize: 10, color: session.status.color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
    );
  }
}
