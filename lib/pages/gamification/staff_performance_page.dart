import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/gamification/staff_leaderboard.dart';
import '../../widgets/gamification/staff_performance_card.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

class StaffPerformancePage extends ConsumerWidget {
  const StaffPerformancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffProfiles = ref.watch(staffProfilesProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Team Performance'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tính lại điểm',
            onPressed: () async {
              final actions = ref.read(gamificationActionsProvider);
              await actions.recalculateStaffScores();
              ref.invalidate(staffProfilesProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã cập nhật điểm nhân viên'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(gamificationActionsProvider).recalculateStaffScores();
          ref.invalidate(staffProfilesProvider);
          ref.invalidate(staffLeaderboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryHeader(context, ref),
            const SizedBox(height: 16),
            const StaffLeaderboard(),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text('📊', style: TextStyle(fontSize: 18)),
                SizedBox(width: 6),
                Text(
                  'Chi tiết nhân viên',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            staffProfiles.when(
              data: (profiles) {
                if (profiles.isEmpty) {
                  return _emptyState();
                }
                return Column(
                  children: profiles
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: StaffPerformanceCard(
                              profile: p,
                              onTap: () => _showStaffDetail(context, p),
                            ),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Lỗi: $e', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, WidgetRef ref) {
    final staffProfiles = ref.watch(staffProfilesProvider);

    return staffProfiles.when(
      data: (profiles) {
        if (profiles.isEmpty) return const SizedBox();

        final avgRating = profiles.fold<double>(0, (s, p) => s + p.overallRating) / profiles.length;
        final avgLevel = profiles.fold<int>(0, (s, p) => s + p.level) / profiles.length;
        final totalXp = profiles.fold<int>(0, (s, p) => s + p.totalXp);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _summaryItem(context, '👥', '${profiles.length}', 'Nhân viên'),
              _summaryItem(context, '⭐', avgRating.toStringAsFixed(0), 'Điểm TB'),
              _summaryItem(context, '📈', avgLevel.toStringAsFixed(1), 'Level TB'),
              _summaryItem(context, '⚡', _formatXp(totalXp), 'Tổng XP'),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _summaryItem(BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.surface70),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Text('🎮', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Chưa có dữ liệu performance',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Nhân viên sẽ tự động được chấm điểm khi có dữ liệu attendance & tasks.\n'
            'Kéo refresh hoặc nhấn nút tính lại để cập nhật.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000000) return '${(xp / 1000000).toStringAsFixed(1)}M';
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '$xp';
  }

  void _showStaffDetail(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            StaffPerformanceCard(profile: profile),
            const SizedBox(height: 16),
            if (profile.badges.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Badges', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: (profile.badges as List<String>).map((b) => Chip(
                  label: Text(b, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
