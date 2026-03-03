import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/gamification/level_badge.dart';
import '../../widgets/gamification/xp_progress_bar.dart';
import '../../widgets/gamification/xp_multiplier_badge.dart';
import '../../widgets/gamification/skill_tree_widget.dart';
import '../../widgets/gamification/streak_counter.dart';
import '../../widgets/gamification/business_health_bar.dart';
import '../../widgets/gamification/prestige_card.dart';

class CeoGameProfilePage extends ConsumerWidget {
  const CeoGameProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(ceoProfileProvider);
    final profile = profileState.profile;

    if (profileState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ CEO')),
        body: const Center(child: Text('Chưa có dữ liệu')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(profile),
          SliverToBoxAdapter(child: _buildProfileHeader(profile)),
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: XpMultiplierBadge(),
          )),
          SliverToBoxAdapter(child: _buildStatsGrid(profile)),
          SliverToBoxAdapter(child: _buildQuickActions(context, profile)),
          SliverToBoxAdapter(child: _buildSocialActions(context)),
          const SliverToBoxAdapter(child: PrestigeCard()),
          const SliverToBoxAdapter(child: SkillTreeWidget()),
          SliverToBoxAdapter(child: _buildXpHistory(ref)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(CeoProfile profile) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _tierColor(profile.level),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _tierGradient(profile.level),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                LevelBadge(level: profile.level, size: 72, showTitle: true),
                const SizedBox(height: 8),
                Text(
                  'Tổng XP: ${profile.totalXp}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(CeoProfile profile) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          XpProgressBar(profile: profile),
          const SizedBox(height: 16),
          StreakCounter(
            streakDays: profile.streakDays,
            longestStreak: profile.longestStreak,
            freezeRemaining: profile.streakFreezeRemaining,
          ),
          const SizedBox(height: 16),
          BusinessHealthBar(score: profile.businessHealthScore),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(CeoProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statTile('⚡', 'Total XP', '${profile.totalXp}', AppColors.warning),
          const SizedBox(width: 8),
          _statTile('⭐', 'Uy Tín', '${profile.reputationPoints}', AppColors.info),
          const SizedBox(width: 8),
          _statTile('🎯', 'Skill Points', '${profile.skillPoints}', AppColors.success),
          const SizedBox(width: 8),
          _statTile('🔥', 'Streak', '${profile.streakDays}d', const Color(0xFFFF6D00)),
        ],
      ),
    );
  }

  Widget _statTile(String emoji, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, CeoProfile profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              '⭐ Uy Tín Store',
              '${profile.reputationPoints} pts',
              const Color(0xFF6A1B9A),
              () => context.push(AppRoutes.uytinStore),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '👥 Team',
              'Xem staff',
              const Color(0xFF1565C0),
              () => context.push(AppRoutes.staffPerformance),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String title, String subtitle, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              '🏆 Leaderboard',
              'Xếp hạng CEO',
              const Color(0xFFE65100),
              () => context.push(AppRoutes.leaderboard),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '🎖️ Season Pass',
              'Mùa giải',
              const Color(0xFF00838F),
              () => context.push(AppRoutes.seasonPass),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionButton(
              '⚔️ Guild War',
              'Xếp hạng công ty',
              const Color(0xFF880E4F),
              () => context.push(AppRoutes.companyRanking),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpHistory(WidgetRef ref) {
    final history = ref.watch(xpHistoryProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📜', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Lịch sử XP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          history.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có lịch sử XP',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return Column(
                children: transactions.take(15).map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          _sourceEmoji(tx.sourceType),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.description ?? tx.sourceType.label,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDate(tx.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${tx.finalAmount} XP',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: tx.finalAmount > 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                        if (tx.multiplier > 1.0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'x${tx.multiplier}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Lỗi: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceEmoji(XpSourceType type) {
    switch (type) {
      case XpSourceType.quest: return '⚔️';
      case XpSourceType.daily: return '📋';
      case XpSourceType.weekly: return '🏆';
      case XpSourceType.boss: return '🏰';
      case XpSourceType.achievement: return '🎖️';
      case XpSourceType.login: return '🔑';
      case XpSourceType.bonus: return '🎁';
      case XpSourceType.multiplier: return '✨';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _tierColor(int level) {
    if (level >= 76) return const Color(0xFFE65100);
    if (level >= 51) return const Color(0xFF6A1B9A);
    if (level >= 31) return const Color(0xFF00838F);
    if (level >= 16) return const Color(0xFF2E7D32);
    if (level >= 6) return const Color(0xFF1565C0);
    return const Color(0xFF37474F);
  }

  List<Color> _tierGradient(int level) {
    if (level >= 76) return [const Color(0xFFFF8F00), const Color(0xFFE65100)];
    if (level >= 51) return [const Color(0xFFAB47BC), const Color(0xFF6A1B9A)];
    if (level >= 31) return [const Color(0xFF26C6DA), const Color(0xFF00838F)];
    if (level >= 16) return [const Color(0xFF66BB6A), const Color(0xFF2E7D32)];
    if (level >= 6) return [const Color(0xFF42A5F5), const Color(0xFF1565C0)];
    return [const Color(0xFF78909C), const Color(0xFF37474F)];
  }
}
