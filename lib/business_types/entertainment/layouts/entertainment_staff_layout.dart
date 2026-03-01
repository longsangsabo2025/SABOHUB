import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
import '../../../pages/staff/staff_checkin_page.dart';
import '../pages/tables/table_list_page.dart';
import '../pages/sessions/session_list_page.dart';
import '../pages/sessions/session_form_page.dart';
import '../providers/table_provider.dart';
import '../providers/session_provider.dart';

class EntertainmentStaffLayout extends ConsumerStatefulWidget {
  const EntertainmentStaffLayout({super.key});

  @override
  ConsumerState<EntertainmentStaffLayout> createState() =>
      _EntertainmentStaffLayoutState();
}

class _EntertainmentStaffLayoutState
    extends ConsumerState<EntertainmentStaffLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Nhân viên';
    final companyName = authState.user?.companyName ?? 'Sabo Billiard';

    final pages = <Widget>[
      const _StaffOverviewPage(),
      const TableListPage(),
      const SessionListPage(),
      const StaffCheckinPage(),
    ];

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sports_bar, color: Colors.teal.shade700, size: 20),
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
                      '🎱 $userName',
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
                ref.invalidate(tablesProvider);
                ref.invalidate(tableStatsProvider);
                ref.invalidate(allSessionsProvider);
                ref.invalidate(sessionStatsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã làm mới'), duration: Duration(seconds: 1)),
                );
              },
            ),
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
              icon: Icon(Icons.table_bar_outlined),
              selectedIcon: Icon(Icons.table_bar),
              label: 'Bàn',
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
          ],
        ),
        floatingActionButton: _currentIndex == 0 || _currentIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SessionFormPage()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mở bàn'),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
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

class _StaffOverviewPage extends ConsumerWidget {
  const _StaffOverviewPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableStats = ref.watch(tableStatsProvider);
    final sessionStats = ref.watch(sessionStatsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tableStatsProvider);
        ref.invalidate(sessionStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade700, Colors.teal.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎱 Sabo Billiard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hôm nay ${DateTime.now().day}/${DateTime.now().month}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _quickStatCard(
                    icon: Icons.table_bar,
                    label: 'Đang chơi',
                    value: tableStats.when(
                      data: (s) => '${s['occupied'] ?? 0}',
                      loading: () => '...',
                      error: (_, __) => '—',
                    ),
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickStatCard(
                    icon: Icons.check_circle,
                    label: 'Bàn trống',
                    value: tableStats.when(
                      data: (s) => '${s['available'] ?? 0}',
                      loading: () => '...',
                      error: (_, __) => '—',
                    ),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickStatCard(
                    icon: Icons.done_all,
                    label: 'Xong hôm nay',
                    value: sessionStats.when(
                      data: (s) => '${s['completedToday'] ?? 0}',
                      loading: () => '...',
                      error: (_, __) => '—',
                    ),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickStatCard(
                    icon: Icons.attach_money,
                    label: 'Doanh thu',
                    value: sessionStats.when(
                      data: (s) {
                        final rev = (s['todayRevenue'] as num?)?.toDouble() ?? 0;
                        if (rev >= 1000000) return '${(rev / 1000000).toStringAsFixed(1)}M';
                        if (rev >= 1000) return '${(rev / 1000).toStringAsFixed(0)}K';
                        return '${rev.toStringAsFixed(0)}đ';
                      },
                      loading: () => '...',
                      error: (_, __) => '—',
                    ),
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Phiên đang hoạt động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ActiveSessionsList(),
          ],
        ),
      ),
    );
  }

  Widget _quickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ActiveSessionsList extends ConsumerWidget {
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
                  Text('Chưa có phiên nào đang chơi', style: TextStyle(color: Colors.grey)),
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
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.sports_esports, color: Colors.teal.shade700),
                ),
                title: Text(session.tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        color: Colors.teal.shade700,
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
