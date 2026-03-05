import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/gamification_provider.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class XpMultiplierBadge extends ConsumerWidget {
  final bool compact;
  const XpMultiplierBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiplier = ref.watch(currentMultiplierProvider);

    return multiplier.when(
      data: (mult) {
        if (mult <= 1.0) return const SizedBox();

        if (compact) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚡ x${mult.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.surface,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6D00), Color(0xFFFF9100), Color(0xFFFFAB40)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 24)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Multiplier Active!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    Text(
                      _getMultiplierDescription(mult),
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.surface70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x${mult.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _getMultiplierDescription(double mult) {
    final parts = <String>[];
    if (mult >= 1.5) parts.add('Giờ Vàng');
    if (mult >= 1.3) parts.add('Streak bonus');
    if (parts.isEmpty) parts.add('Bonus active');
    return parts.join(' + ');
  }
}
