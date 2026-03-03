import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Company Alerts Model
/// Shows notification counts for each company
class CompanyAlerts {
  final String companyId;
  final int overdueTasksCount;      // Tasks past deadline
  final int pendingApprovalCount;   // Tasks waiting for manager approval
  final int newReportsCount;        // New financial reports this month
  final int unreadMessagesCount;    // Unread task comments

  const CompanyAlerts({
    required this.companyId,
    this.overdueTasksCount = 0,
    this.pendingApprovalCount = 0,
    this.newReportsCount = 0,
    this.unreadMessagesCount = 0,
  });

  /// Total urgent alerts (overdue + pending)
  int get urgentCount => overdueTasksCount + pendingApprovalCount;

  /// Total all alerts
  int get totalCount => overdueTasksCount + pendingApprovalCount + newReportsCount + unreadMessagesCount;

  /// Has any alerts
  bool get hasAlerts => totalCount > 0;

  /// Has urgent alerts
  bool get hasUrgent => urgentCount > 0;
}

/// Provider to fetch alerts for a specific company
final companyAlertsProvider = FutureProvider.family<CompanyAlerts, String>((ref, companyId) async {
  final sb = Supabase.instance.client;
  final now = DateTime.now();
  
  int overdueCount = 0;
  int pendingCount = 0;
  int reportsCount = 0;
  int unreadCount = 0;

  try {
    // 1. Overdue tasks: tasks with deadline < now and status not completed
    final overdueRes = await sb
        .from('tasks')
        .select('id')
        .eq('company_id', companyId)
        .lt('deadline', now.toIso8601String())
        .neq('status', 'completed')
        .neq('status', 'cancelled');
    overdueCount = (overdueRes as List).length;
  } catch (_) {}

  try {
    // 2. Pending approval: tasks with status = 'pending_approval' or 'review'
    final pendingRes = await sb
        .from('tasks')
        .select('id')
        .eq('company_id', companyId)
        .or('status.eq.pending_approval,status.eq.review');
    pendingCount = (pendingRes as List).length;
  } catch (_) {}

  try {
    // 3. New reports: financial reports (monthly_pnl) created this month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final reportsRes = await sb
        .from('monthly_pnl')
        .select('id')
        .eq('company_id', companyId)
        .gte('created_at', startOfMonth.toIso8601String());
    reportsCount = (reportsRes as List).length;
  } catch (_) {}

  try {
    // 4. Unread messages: task_comments not yet read (simplified: count all comments today)
    // Note: A proper implementation would track read status per user
    final today = DateTime(now.year, now.month, now.day);
    final commentsRes = await sb
        .from('task_comments')
        .select('id, tasks!inner(company_id)')
        .eq('tasks.company_id', companyId)
        .gte('created_at', today.toIso8601String());
    unreadCount = (commentsRes as List).length;
  } catch (_) {}

  return CompanyAlerts(
    companyId: companyId,
    overdueTasksCount: overdueCount,
    pendingApprovalCount: pendingCount,
    newReportsCount: reportsCount,
    unreadMessagesCount: unreadCount,
  );
});

/// Provider to fetch alerts for multiple companies at once
final multiCompanyAlertsProvider = FutureProvider.family<Map<String, CompanyAlerts>, List<String>>((ref, companyIds) async {
  final results = <String, CompanyAlerts>{};
  
  for (final id in companyIds) {
    try {
      final alerts = await ref.read(companyAlertsProvider(id).future);
      results[id] = alerts;
    } catch (_) {
      results[id] = CompanyAlerts(companyId: id);
    }
  }
  
  return results;
});
