import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BusinessHealthBar extends StatelessWidget {
  final double score;
  final bool showLabel;
  final bool compact;

  const BusinessHealthBar({
    super.key,
    required this.score,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 100.0);
    final info = _healthInfo(clampedScore);
    final height = compact ? 8.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(info.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Sức khỏe doanh nghiệp',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${clampedScore.toInt()}/100 — ${info.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: info.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: Colors.grey.shade100),
                FractionallySizedBox(
                  widthFactor: clampedScore / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: info.gradient),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _HealthInfo _healthInfo(double score) {
    if (score >= 80) {
      return _HealthInfo(
        'Tuyệt vời', '💚', AppColors.success,
        [Color(0xFF43A047), Color(0xFF66BB6A)],
      );
    }
    if (score >= 60) {
      return _HealthInfo(
        'Khá tốt', '💛', AppColors.warning,
        [Color(0xFFFFA726), Color(0xFFFFCA28)],
      );
    }
    if (score >= 30) {
      return _HealthInfo(
        'Cần cải thiện', '🟠', Color(0xFFE65100),
        [Color(0xFFE65100), Color(0xFFFF6D00)],
      );
    }
    return _HealthInfo(
      'Nguy hiểm', '❤️‍🩹', AppColors.error,
      [Color(0xFFC62828), Color(0xFFE53935)],
    );
  }
}

class _HealthInfo {
  final String label;
  final String emoji;
  final Color color;
  final List<Color> gradient;
  const _HealthInfo(this.label, this.emoji, this.color, this.gradient);
}
