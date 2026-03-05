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
final companyAlertsProvider = FutureProvider.autoDispose.family<CompanyAlerts, String>((ref, companyId) async {
  final sb = Supabase.instance.client;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);

  Future<int> safeCount(Future<dynamic> query) async {
    try {
      final res = await query;
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // Run all 4 queries in parallel instead of sequentially
  final results = await Future.wait([
    // 1. Overdue tasks: tasks with deadline < now and status not completed
    safeCount(sb
        .from('tasks')
        .select('id')
        .eq('company_id', companyId)
        .lt('deadline', now.toIso8601String())
        .neq('status', 'completed')
        .neq('status', 'cancelled')),
    // 2. Pending approval: tasks with status = 'pending_approval' or 'review'
    safeCount(sb
        .from('tasks')
        .select('id')
        .eq('company_id', companyId)
        .or('status.eq.pending_approval,status.eq.review')),
    // 3. New reports: financial reports (monthly_pnl) created this month
    safeCount(sb
        .from('monthly_pnl')
        .select('id')
        .eq('company_id', companyId)
        .gte('created_at', startOfMonth.toIso8601String())),
    // 4. Unread messages: task_comments not yet read (simplified: count all comments today)
    safeCount(sb
        .from('task_comments')
        .select('id, tasks!inner(company_id)')
        .eq('tasks.company_id', companyId)
        .gte('created_at', today.toIso8601String())),
  ]);

  return CompanyAlerts(
    companyId: companyId,
    overdueTasksCount: results[0],
    pendingApprovalCount: results[1],
    newReportsCount: results[2],
    unreadMessagesCount: results[3],
  );
});

/// Provider to fetch alerts for multiple companies at once
final multiCompanyAlertsProvider = FutureProvider.autoDispose.family<Map<String, CompanyAlerts>, List<String>>((ref, companyIds) async {
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
