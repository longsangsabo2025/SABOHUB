import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/gamification/gamification_models.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/gamification/ceo_game_summary_card.dart';
import '../../widgets/gamification/daily_quest_panel.dart';
import '../../widgets/gamification/quest_card.dart';
import '../../widgets/gamification/quest_celebration_overlay.dart';
import '../../widgets/gamification/quest_notification_bar.dart';
import '../../widgets/gamification/streak_counter.dart';
import '../../widgets/gamification/streak_freeze_button.dart';
import '../../widgets/gamification/business_health_bar.dart';
import '../../widgets/gamification/staff_leaderboard.dart';
import '../../widgets/gamification/notification_bell.dart';

class QuestHubPage extends ConsumerStatefulWidget {
  const QuestHubPage({super.key});

  @override
  ConsumerState<QuestHubPage> createState() => _QuestHubPageState();
}

class _QuestHubPageState extends ConsumerState<QuestHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(ceoProfileProvider);
    final profile = profileState.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quest Hub'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          GameNotificationBell(
            onTap: () => context.push(AppRoutes.gameNotifications),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analytics',
            onPressed: () => context.push(AppRoutes.gamificationAnalytics),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Quest Config',
            onPressed: () => context.push(AppRoutes.aiQuestConfig),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '⚔️ Nhiệm vụ'),
            Tab(text: '📋 Hàng ngày'),
            Tab(text: '🎖️ Thành tựu'),
            Tab(text: '🏆 Bảng xếp hạng'),
            Tab(text: '👥 Team'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CeoGameSummaryCard(
                onTap: () => _navigateToProfile(context),
              ),
            ),
          // ── Quick Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _quickActionChip(
                    '🏪 Cửa hàng Uy Tín',
                    const Color(0xFFFF8F00),
                    () => context.push(AppRoutes.uytinStore),
                  ),
                  const SizedBox(width: 8),
                  _quickActionChip(
                    '🎫 Season Pass',
                    const Color(0xFF7B1FA2),
                    () => context.push(AppRoutes.seasonPass),
                  ),
                  const SizedBox(width: 8),
                  _quickActionChip(
                    '⚔️ Guild War',
                    const Color(0xFFC62828),
                    () => context.push(AppRoutes.companyRanking),
                  ),
                  const SizedBox(width: 8),
                  _quickActionChip(
                    '📊 Xếp hạng CEO',
                    const Color(0xFF1565C0),
                    () => context.push(AppRoutes.leaderboard),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMainQuestsTab(),
                _buildDailyTab(profile),
                _buildAchievementsTab(),
                _buildLeaderboardTab(),
                _buildTeamTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────── Tab 1: Main Quests ────────

  Widget _buildMainQuestsTab() {
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedQuests = ref.watch(completedQuestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gamificationActionsProvider).evaluateMainQuests();
        ref.invalidate(activeQuestsProvider);
        ref.invalidate(completedQuestsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Đang thực hiện', '⚔️'),
          const SizedBox(height: 8),
          activeQuests.when(
            data: (quests) {
              if (quests.isEmpty) {
                return _emptyState('Chưa có nhiệm vụ nào.\nBắt đầu hành trình CEO!');
              }
              return Column(
                children: quests
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: QuestCard(progress: q, onTap: () => _onQuestTap(q)),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _errorState(e.toString()),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Đã hoàn thành', '✅'),
          const SizedBox(height: 8),
          completedQuests.when(
            data: (quests) {
              if (quests.isEmpty) {
                return _emptyState('Chưa hoàn thành nhiệm vụ nào.');
              }
              return Column(
                children: quests
                    .take(10)
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: QuestCard(progress: q),
                        ))
                    .toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ──────── Tab 2: Daily Quests ────────

  Widget _buildDailyTab(CeoProfile? profile) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(gamificationActionsProvider).evaluateDailyQuests();
        ref.invalidate(dailyQuestResultsProvider);
        ref.invalidate(todayQuestLogProvider);
        ref.invalidate(loginCalendarProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null)
            StreakCounter(
              streakDays: profile.streakDays,
              longestStreak: profile.longestStreak,
              freezeRemaining: profile.streakFreezeRemaining,
            ),
          const SizedBox(height: 12),
          const StreakFreezeButton(),
          const SizedBox(height: 16),
          if (profile != null)
            BusinessHealthBar(score: profile.businessHealthScore),
          const SizedBox(height: 16),
          _sectionHeader('Nhiệm vụ hôm nay', '📋'),
          const SizedBox(height: 8),
          const DailyQuestPanel(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _onRefreshDailyQuests,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Cập nhật Daily Quests'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefreshDailyQuests() async {
    final actions = ref.read(gamificationActionsProvider);
    await actions.evaluateDailyQuests();

    final asyncResults = ref.read(dailyQuestResultsProvider);
    final results = asyncResults is AsyncData<List<DailyQuestResult>> ? asyncResults.value : <DailyQuestResult>[];
    final combo = results.where((r) => r.isCompleted).length >= 5;

    if (combo && mounted) {
      QuestCelebrationOverlay.show(
        context,
        type: CelebrationType.dailyCombo,
        title: 'Daily Combo hoàn thành!',
        subtitle: 'Tất cả 5 nhiệm vụ hàng ngày',
        xpEarned: 50,
      );
    }

    final newlyCompleted = results.where((r) => r.isCompleted && r.xpReward > 0).toList();
    if (newlyCompleted.isNotEmpty && mounted) {
      final totalXp = newlyCompleted.fold<int>(0, (s, r) => s + r.xpReward);
      QuestNotificationBar.show(
        context,
        type: QuestNotificationType.xpGain,
        message: '${newlyCompleted.length} daily quests hoàn thành!',
        xpAmount: totalXp,
      );
    }
  }

  // ──────── Tab 3: Achievements ────────

  Widget _buildAchievementsTab() {
    final allAchievements = ref.watch(allAchievementsProvider);
    final userAchievements = ref.watch(userAchievementsProvider);

    return allAchievements.when(
      data: (achievements) {
        final unlockedIds = userAchievements.value
                ?.map((ua) => ua.achievementId)
                .toSet() ??
            {};

        final unlockedCount = achievements.where((a) => unlockedIds.contains(a.id)).length;

        return RefreshIndicator(
          onRefresh: _onScanAchievements,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$unlockedCount / ${achievements.length} Thành Tựu',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white,
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                              minHeight: 6,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onScanAchievements,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Quét', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...achievements.map((achievement) {
                final isUnlocked = unlockedIds.contains(achievement.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAchievementTile(achievement, isUnlocked),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: _errorState(e.toString())),
    );
  }

  Future<void> _onScanAchievements() async {
    final actions = ref.read(gamificationActionsProvider);
    final results = await actions.evaluateAchievements();

    if (!mounted) return;

    final newlyUnlocked = results.where((r) => r['newly_unlocked'] == true).toList();
    if (newlyUnlocked.isNotEmpty) {
      final first = newlyUnlocked.first;
      QuestCelebrationOverlay.show(
        context,
        type: CelebrationType.achievementUnlock,
        title: first['achievement_name'] as String? ?? 'Thành tựu mới!',
        subtitle: 'Rarity: ${first['rarity']}',
      );
    } else {
      QuestNotificationBar.show(
        context,
        type: QuestNotificationType.achievementUnlock,
        message: 'Chưa có thành tựu mới — tiếp tục cố gắng!',
      );
    }
  }

  Widget _buildAchievementTile(Achievement achievement, bool isUnlocked) {
    final rarityColors = {
      AchievementRarity.common: const Color(0xFF78909C),
      AchievementRarity.rare: const Color(0xFF1E88E5),
      AchievementRarity.epic: const Color(0xFF7B1FA2),
      AchievementRarity.legendary: const Color(0xFFFF8F00),
      AchievementRarity.mythic: const Color(0xFFC62828),
    };
    final color = rarityColors[achievement.rarity] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(achievement.rarity.emoji, style: const TextStyle(fontSize: 18))
                  : Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.isSecret && !isUnlocked ? '???' : achievement.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isUnlocked ? AppColors.textPrimary : Colors.grey.shade400,
                  ),
                ),
                if (achievement.description != null)
                  Text(
                    achievement.isSecret && !isUnlocked
                        ? 'Thành tựu ẩn'
                        : achievement.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked ? AppColors.textSecondary : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              achievement.rarity.label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ──────── Tab 4: Leaderboard ────────

  Widget _buildLeaderboardTab() {
    final leaderboard = ref.watch(leaderboardProvider);

    return leaderboard.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(child: _emptyState('Chưa có dữ liệu bảng xếp hạng'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = entry['rank'] as num;
            final isTopThree = rank <= 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTopThree
                      ? _rankColor(rank.toInt()).withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: isTopThree
                          ? Text(
                              _rankEmoji(rank.toInt()),
                              style: const TextStyle(fontSize: 22),
                            )
                          : Text(
                              '#${rank.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['full_name'] as String? ?? 'CEO',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry['current_title']} • Lv.${entry['level']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry['total_xp']} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      if ((entry['streak_days'] as num?) != null && (entry['streak_days'] as num) > 0)
                        Text(
                          '🔥 ${entry['streak_days']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: _errorState(e.toString())),
    );
  }

  // ──────── Tab 5: Team (Staff Performance) ────────

  Widget _buildTeamTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StaffLeaderboard(compact: false),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.staffPerformance),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Chi tiết Team Performance'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // ──────── Helpers ────────

  Widget _quickActionChip(String label, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _errorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Lỗi: $message',
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }

  String _rankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return Colors.grey;
    }
  }

  void _onQuestTap(QuestProgress progress) {
    if (progress.quest == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _QuestDetailSheet(
        progress: progress,
        onRefreshQuests: () {
          ref.read(gamificationActionsProvider).evaluateMainQuests();
        },
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    context.push(AppRoutes.ceoGameProfile);
  }
}

class _QuestDetailSheet extends StatelessWidget {
  final QuestProgress progress;
  final VoidCallback? onRefreshQuests;
  const _QuestDetailSheet({required this.progress, this.onRefreshQuests});

  QuestDefinition? get quest => progress.quest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                quest?.questType.icon ?? '📋',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest?.name ?? 'Quest',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    if (quest?.act != null)
                      Text(
                        'Act ${quest!.act} — ${quest!.questType.label}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (quest?.description != null)
            Text(
              quest!.description!,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.progressCurrent} / ${progress.progressTarget} — ${(progress.progressPercent * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Phần thưởng',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (quest != null && quest!.xpReward > 0)
                _rewardChip('⚡ ${quest!.xpReward} XP', AppColors.warning),
              if (quest?.reputationReward != null && quest!.reputationReward > 0)
                _rewardChip('⭐ ${quest!.reputationReward} Uy Tín', AppColors.info),
              if (quest?.badgeReward != null)
                _rewardChip('🎖️ Badge: ${quest!.badgeReward}', AppColors.secondary),
              if (quest?.titleReward != null)
                _rewardChip('👑 Title: ${quest!.titleReward}', const Color(0xFFFF8F00)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                onRefreshQuests?.call();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Kiểm tra tiến độ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
