import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/gamification_provider.dart';

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
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚡ x${mult.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white,
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'XP Multiplier Active!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white,
                      ),
                    ),
                    Text(
                      _getMultiplierDescription(mult),
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x${mult.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white,
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
