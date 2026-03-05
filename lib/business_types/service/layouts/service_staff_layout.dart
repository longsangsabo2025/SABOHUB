import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/error_boundary.dart';
import '../../../widgets/bug_report_dialog.dart';
import '../../../widgets/realtime_notification_widgets.dart';
import '../../../pages/staff/staff_checkin_page.dart';
import '../pages/sessions/session_list_page.dart';
import '../pages/sessions/session_form_page.dart';
import '../pages/reports/staff_daily_report_page.dart';
import '../../../providers/schedule_provider.dart';
import '../widgets/daily_checklist_widget.dart';
import '../../../pages/schedules/schedule_list_page.dart';
import '../providers/session_provider.dart';
import '../pages/learning/staff_learning_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class ServiceStaffLayout extends ConsumerStatefulWidget {
  const ServiceStaffLayout({super.key});

  @override
  ConsumerState<ServiceStaffLayout> createState() =>
      _ServiceStaffLayoutState();
}

class _ServiceStaffLayoutState
    extends ConsumerState<ServiceStaffLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? 'Nhân viên';
    final companyName = user?.companyName ?? 'Sabo Billiard';

    final pages = <Widget>[
      const _StaffOverviewPage(),
      const SessionListPage(),
      const StaffDailyReportPage(),
      const StaffCheckinPage(),
      const StaffLearningPage(),
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
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Báo cáo',
            ),
            NavigationDestination(
              icon: Icon(Icons.fingerprint_outlined),
              selectedIcon: Icon(Icons.fingerprint),
              label: 'Check-in',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Học',
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
                backgroundColor: Colors.teal,
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
                  Text(
                    '🎱 Sabo Billiard',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hôm nay ${DateTime.now().day}/${DateTime.now().month}',
                    style: TextStyle(color: Theme.of(context).colorScheme.surface70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _quickStatCard(
                    context,
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
                    context,
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

            // Daily checklist
            const DailyChecklistWidget(),
            const SizedBox(height: 24),

            // Lịch làm việc tuần này
            _MyScheduleSection(),
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

  Widget _quickStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.onSurface.withAlpha(13), blurRadius: 6, offset: Offset(0, 2)),
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

/// My Schedule Section - Shows this week's upcoming shifts
class _MyScheduleSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.companyId == null) return const SizedBox.shrink();

    final schedulesAsync = ref.watch(schedulesByEmployeeProvider({
      'companyId': user.companyId!,
      'employeeId': user.id,
    }));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lịch làm việc tuần này',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleListPage()),
                );
              },
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        schedulesAsync.when(
          data: (schedules) {
            // Filter for upcoming schedules (today and next 7 days)
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final nextWeek = today.add(const Duration(days: 7));
            
            final upcoming = schedules.where((s) {
              return !s.date.isBefore(today) && s.date.isBefore(nextWeek);
            }).toList();
            
            upcoming.sort((a, b) => a.date.compareTo(b.date));

            if (upcoming.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Chưa có lịch làm việc tuần này',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                children: upcoming.take(5).map((schedule) {
                  final isToday = schedule.date.day == now.day &&
                      schedule.date.month == now.month &&
                      schedule.date.year == now.year;
                  final dateStr = isToday
                      ? 'Hôm nay'
                      : '${schedule.date.day}/${schedule.date.month}';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isToday ? Colors.teal.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? Colors.teal.shade700 : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: schedule.shiftType.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          schedule.shiftType.label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          schedule.shiftType.timeRange,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
        ),
      ],
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
