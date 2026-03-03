import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/gamification/employee_game_profile.dart';

class StaffPerformanceCard extends StatelessWidget {
  final EmployeeGameProfile profile;
  final VoidCallback? onTap;

  const StaffPerformanceCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(profile.level);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _levelBadge(tierColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.employeeName ?? 'Nhân viên',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${profile.currentTitle} • Lv.${profile.level}',
                          style: TextStyle(fontSize: 12, color: tierColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${profile.totalXp} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                      if (profile.streakDays > 0)
                        Text('🔥 ${profile.streakDays}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // XP Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.levelProgress,
                  minHeight: 6,
                  backgroundColor: tierColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(tierColor),
                ),
              ),
              const SizedBox(height: 10),
              // Score bars
              Row(
                children: [
                  _scorePill('📋', 'Chuyên cần', profile.attendanceScore, AppColors.info),
                  const SizedBox(width: 6),
                  _scorePill('✅', 'Tasks', profile.taskScore, AppColors.success),
                  const SizedBox(width: 6),
                  _scorePill('⏰', 'Đúng giờ', profile.punctualityScore, AppColors.warning),
                ],
              ),
              const SizedBox(height: 8),
              // Overall rating bar
              Row(
                children: [
                  const Text('Tổng', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: profile.overallRating / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(_ratingColor(profile.overallRating)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.overallRating.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _ratingColor(profile.overallRating),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelBadge(Color tierColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tierColor, tierColor.withValues(alpha: 0.7)],
        ),
      ),
      child: Center(
        child: Text(
          '${profile.level}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _scorePill(String emoji, String label, double score, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text('$emoji ${score.toInt()}%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Color _tierColor(int level) {
    if (level >= 50) return const Color(0xFFC62828);
    if (level >= 40) return const Color(0xFF00BCD4);
    if (level >= 30) return const Color(0xFF9C27B0);
    if (level >= 20) return const Color(0xFFFFD700);
    if (level >= 15) return const Color(0xFFC0C0C0);
    if (level >= 10) return const Color(0xFFCD7F32);
    if (level >= 5) return const Color(0xFF607D8B);
    return const Color(0xFF9E9E9E);
  }

  Color _ratingColor(double rating) {
    if (rating >= 80) return AppColors.success;
    if (rating >= 60) return AppColors.warning;
    if (rating >= 40) return const Color(0xFFFF9800);
    return AppColors.error;
  }
}
