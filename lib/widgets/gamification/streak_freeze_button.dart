import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/gamification_provider.dart';

class StreakFreezeButton extends ConsumerWidget {
  const StreakFreezeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(ceoProfileProvider);
    final profile = profileState.profile;

    if (profile == null) return const SizedBox();

    final freezeRemaining = profile.streakFreezeRemaining;
    final hasFreeze = freezeRemaining > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasFreeze
                  ? const Color(0xFF00BCD4).withValues(alpha: 0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                hasFreeze ? '🧊' : '💔',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Freeze',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  hasFreeze
                      ? 'Còn $freezeRemaining lượt — bảo vệ streak khi bạn không đăng nhập'
                      : 'Hết lượt — streak sẽ mất nếu không đăng nhập',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: hasFreeze
                ? () => _useFreeze(context, ref)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasFreeze ? const Color(0xFF00BCD4) : Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              hasFreeze ? 'Dùng' : 'Hết',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useFreeze(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Text('🧊 ', style: TextStyle(fontSize: 24)),
            Text('Streak Freeze'),
          ],
        ),
        content: const Text(
          'Kích hoạt Streak Freeze sẽ bảo vệ streak của bạn 1 ngày nếu không đăng nhập.\n\nBạn chắc chắn muốn dùng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final actions = ref.read(gamificationActionsProvider);
    final result = await actions.useStreakFreeze();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
