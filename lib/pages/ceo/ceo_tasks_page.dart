import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/management_task.dart';
import '../../providers/cached_providers.dart'
    show
        managementTaskServiceProvider,
        cachedPendingApprovalsProvider,
        refreshAllManagementTasks;
import '../../core/theme/app_colors.dart';
import '../../widgets/task/task_board.dart';
import '../../providers/auth_provider.dart';

// =============================================================================
// CEO TASKS PAGE — Lean, 2-tab design (Nhiệm vụ | Phê duyệt)
// Elon Musk mode: no bloat, no navigation links filler, no duplicated widgets
// All task management through unified TaskBoard widget
// =============================================================================

class CEOTasksPage extends ConsumerStatefulWidget {
  const CEOTasksPage({super.key});

  @override
  ConsumerState<CEOTasksPage> createState() => _CEOTasksPageState();
}

class _CEOTasksPageState extends ConsumerState<CEOTasksPage>
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
    final approvalsAsync = ref.watch(cachedPendingApprovalsProvider);
    final approvalCount = approvalsAsync.whenOrNull(data: (a) => a.length) ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Công việc',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Làm mới',
            onPressed: () {
              refreshAllManagementTasks(ref);
              ref.invalidate(cachedPendingApprovalsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2.5,
          tabs: [
            const Tab(text: 'Nhiệm vụ'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Phê duyệt'),
                  if (approvalCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$approvalCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tasks — powered by unified TaskBoard
          TaskBoard(
            config: TaskBoardConfig.ceo(
              loadAssignees: () async {
                final service = ref.read(managementTaskServiceProvider);
                return service.getManagers();
              },
              loadCompanies: () async {
                final service = ref.read(managementTaskServiceProvider);
                return service.getCompanies();
              },
              loadMediaChannels: () async {
                try {
                  final companyId = ref.read(authProvider).user?.companyId;
                  if (companyId == null) return [];
                  final data = await Supabase.instance.client
                      .from('media_channels')
                      .select('id, name, platform, status')
                      .eq('company_id', companyId)
                      .neq('status', 'archived')
                      .order('name');
                  return List<Map<String, dynamic>>.from(data);
                } catch (_) {
                  return [];
                }
              },
            ),
          ),
          // Tab 2: Approvals
          const _ApprovalsTab(),
        ],
      ),
    );
  }

}

// =============================================================================
// APPROVALS TAB
// =============================================================================

class _ApprovalsTab extends ConsumerWidget {
  const _ApprovalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(cachedPendingApprovalsProvider);

    return approvalsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text('Lỗi: $e', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      ),
      data: (approvals) {
        if (approvals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Không có yêu cầu chờ phê duyệt',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: approvals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _ApprovalCard(
            approval: approvals[i],
            onApprove: () => _handleApproval(context, ref, approvals[i], true),
            onReject: () => _handleApproval(context, ref, approvals[i], false),
          ),
        );
      },
    );
  }

  Future<void> _handleApproval(
    BuildContext context,
    WidgetRef ref,
    TaskApproval item,
    bool isApproved,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          isApproved ? 'Phê duyệt?' : 'Từ chối?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '"${item.title}"',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isApproved ? AppColors.success : AppColors.error,
            ),
            child: Text(isApproved ? 'Phê duyệt' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(managementTaskServiceProvider);
      if (isApproved) {
        await service.approveTaskApproval(item.id);
      } else {
        await service.rejectTaskApproval(item.id, reason: 'Từ chối bởi CEO');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? 'Đã phê duyệt' : 'Đã từ chối'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        ref.invalidate(cachedPendingApprovalsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// =============================================================================
// APPROVAL CARD
// =============================================================================

class _ApprovalCard extends StatelessWidget {
  final TaskApproval approval;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.approval,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    approval.type.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(approval.submittedAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              approval.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (approval.description != null && approval.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                approval.description!,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Text(
                  approval.submittedByName ?? approval.submittedBy,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                if (approval.companyName != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.business_rounded, size: 14, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 4),
                  Text(
                    approval.companyName!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Từ chối', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Phê duyệt', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _typeColor => switch (approval.type) {
    ApprovalType.report   => AppColors.info,
    ApprovalType.budget   => AppColors.primary,
    ApprovalType.proposal => const Color(0xFF0D9488),
    ApprovalType.other    => const Color(0xFF6B7280),
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d trước';
    if (diff.inHours > 0) return '${diff.inHours}h trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m trước';
    return 'Vừa xong';
  }
}
