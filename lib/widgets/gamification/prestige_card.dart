import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/gamification_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class PrestigeCard extends ConsumerWidget {
  PrestigeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prestigeAsync = ref.watch(prestigeInfoProvider);
    final theme = Theme.of(context);

    return prestigeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (info == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: info.prestigeLevel > 0
                    ? [Colors.purple.shade800, Colors.deepPurple.shade900]
                    : [theme.colorScheme.surfaceContainerHigh, theme.colorScheme.surfaceContainerHighest],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: info.prestigeLevel > 0 ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      info.prestigeLevel > 0
                          ? 'Prestige ${info.prestigeLevel}'
                          : 'Prestige',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: info.prestigeLevel > 0 ? Theme.of(context).colorScheme.surface : null,
                      ),
                    ),
                    Spacer(),
                    if (info.prestigeLevel > 0)
                      ...List.generate(
                        info.prestigeLevel.clamp(0, 5),
                        (_) => const Text('★', style: TextStyle(color: Colors.amber, fontSize: 16)),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                if (info.prestigeLevel > 0) ...[
                  _BonusRow(
                    label: 'XP Bonus',
                    value: '+${info.xpBonusPercent}%',
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  _BonusRow(
                    label: 'Uy Tín Bonus',
                    value: '+${info.reputationBonusPercent}%',
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  _BonusRow(
                    label: 'Max Streak Freeze',
                    value: '${info.maxStreakFreeze}',
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kỷ lục Level: ${info.highestLevelEver}',
                    style: TextStyle(color: Theme.of(context).colorScheme.surface60, fontSize: 12),
                  ),
                ] else
                  Text(
                    'Đạt Level 50 để mở khóa Prestige.\nReset level, nhận bonus vĩnh viễn!',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: info.canPrestige
                      ? FilledButton.icon(
                          onPressed: () => _confirmPrestige(context, ref),
                          icon: Icon(Icons.replay),
                          label: Text('PRESTIGE'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.lock),
                          label: Text('Cần Level 50'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: info.prestigeLevel > 0 ? Theme.of(context).colorScheme.surface54 : null,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmPrestige(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận Prestige?'),
        content: const Text(
          'Level, XP và Skill Tree sẽ được reset.\n'
          'Bạn sẽ nhận bonus vĩnh viễn:\n'
          '• +5% XP bonus\n'
          '• +3% Uy Tín bonus\n'
          '• +1 Streak Freeze\n'
          '• Badge + Title Prestige\n\n'
          'Không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('PRESTIGE!'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final actions = ref.read(gamificationActionsProvider);
    final result = await actions.doPrestige();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.purple : Colors.orange,
        ),
      );
    }
  }
}

class _BonusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BonusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.withAlpha(179), fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
