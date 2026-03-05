import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/referral_model.dart';
import '../../providers/referral_provider.dart';

class ReferralPage extends ConsumerStatefulWidget {
  const ReferralPage({super.key});

  @override
  ConsumerState<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends ConsumerState<ReferralPage> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(referralListProvider.notifier).loadReferrals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(referralListProvider);
    final statsAsync = ref.watch(referralStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giới Thiệu Nhân Sự'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              ref.read(referralListProvider.notifier).loadReferrals();
              ref.invalidate(referralStatsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateReferralSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Giới thiệu'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: listState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : listState.error != null
              ? _buildError(listState.error!)
              : Column(
                  children: [
                    // Stats header
                    statsAsync.when(
                      data: (stats) => _buildStatsHeader(stats),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const Divider(height: 1),
                    // Referral list
                    Expanded(
                      child: listState.referrals.isEmpty
                          ? _buildEmpty()
                          : _buildReferralList(listState.referrals),
                    ),
                  ],
                ),
    );
  }

  // ─── Stats Header ──────────────────────────────────────────────────────────

  Widget _buildStatsHeader(ReferralStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          _statCard(
            'Tổng',
            stats.total.toString(),
            Icons.people_outline,
            AppColors.info,
          ),
          _statCard(
            'Chấp nhận',
            stats.accepted.toString(),
            Icons.check_circle_outline,
            AppColors.success,
          ),
          _statCard(
            'Đang chờ',
            stats.pending.toString(),
            Icons.hourglass_empty,
            AppColors.warning,
          ),
          _statCard(
            'SABO',
            '${stats.totalRewards}',
            Icons.toll,
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Referral List ─────────────────────────────────────────────────────────

  Widget _buildReferralList(List<Referral> referrals) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(referralListProvider.notifier).loadReferrals();
        ref.invalidate(referralStatsProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: referrals.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final r = referrals[index];
          return _referralTile(r);
        },
      ),
    );
  }

  Widget _referralTile(Referral r) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: r.status.color.withValues(alpha: 0.15),
        child: Icon(r.status.icon, color: r.status.color, size: 22),
      ),
      title: Text(
        r.refereeName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.position != null && r.position!.isNotEmpty)
            Text(
              r.position!,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          Row(
            children: [
              Text(
                _dateFmt.format(r.createdAt),
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: r.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  r.status.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: r.status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '+${r.rewardAmount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: r.status == ReferralStatus.accepted
                  ? AppColors.success
                  : AppColors.textTertiary,
            ),
          ),
          const Text('SABO', style: TextStyle(fontSize: 10)),
        ],
      ),
      isThreeLine: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có giới thiệu nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Giới thiệu bạn bè, người thân vào làm việc\nvà nhận thưởng SABO token!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateReferralSheet(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Giới thiệu ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  ref.read(referralListProvider.notifier).loadReferrals(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create Referral Bottom Sheet ──────────────────────────────────────────

  void _showCreateReferralSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Giới thiệu nhân sự mới',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Điền thông tin người được giới thiệu',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập họ tên'
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập số điện thoại'
                            : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Position
                      TextFormField(
                        controller: positionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Vị trí ứng tuyển',
                          prefixIcon: Icon(Icons.work_outline),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      // Note
                      TextFormField(
                        controller: noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú',
                          prefixIcon: Icon(Icons.note_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 20),

                      // Reward info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.toll,
                              color: AppColors.warningDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Bạn sẽ nhận được 50 SABO token khi người được giới thiệu được chấp nhận.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      FilledButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSubmitting = true);

                                final success = await ref
                                    .read(referralListProvider.notifier)
                                    .createReferral(
                                      refereeName: nameCtrl.text.trim(),
                                      refereePhone: phoneCtrl.text.trim(),
                                      refereeEmail: emailCtrl.text.trim(),
                                      position: positionCtrl.text.trim().isEmpty
                                          ? null
                                          : positionCtrl.text.trim(),
                                      note: noteCtrl.text.trim().isEmpty
                                          ? null
                                          : noteCtrl.text.trim(),
                                    );

                                setSheetState(() => isSubmitting = false);

                                if (success && ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ref.invalidate(referralStatsProvider);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Đã gửi giới thiệu thành công! 🎉',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } else if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Không thể gửi giới thiệu. Vui lòng thử lại.',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.surface,
                                ),
                              )
                            : const Text(
                                'Gửi giới thiệu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
