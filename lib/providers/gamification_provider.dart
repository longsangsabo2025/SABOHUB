import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gamification/gamification_models.dart';
import '../services/gamification/gamification_service.dart';
import 'auth_provider.dart';
import 'token_provider.dart';

// ──────────────────────────────────────────────
// Service Provider
// ──────────────────────────────────────────────

final gamificationServiceProvider = Provider<GamificationService>(
  (ref) => GamificationService(),
);

// ──────────────────────────────────────────────
// CEO Profile
// ──────────────────────────────────────────────

class CeoProfileState {
  final CeoProfile? profile;
  final bool isLoading;
  final String? error;

  const CeoProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  CeoProfileState copyWith({
    CeoProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return CeoProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CeoProfileNotifier extends Notifier<CeoProfileState> {
  @override
  CeoProfileState build() {
    final user = ref.watch(currentUserProvider);
    if (user != null && user.companyId != null) {
      Future.microtask(() => loadProfile());
    }
    return const CeoProfileState(isLoading: true);
  }

  GamificationService get _service => ref.read(gamificationServiceProvider);
  String? get _userId => ref.read(currentUserProvider)?.id;
  String? get _companyId => ref.read(currentUserProvider)?.companyId;

  Future<void> loadProfile() async {
    final userId = _userId;
    final companyId = _companyId;
    if (userId == null || companyId == null) {
      state = const CeoProfileState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    try {
      final profile = await _service.getOrCreateProfile(userId, companyId);

      await _service.initializeQuestsForUser(userId, companyId);

      await _service.recordDailyLogin(userId, companyId);

      // Award daily login tokens
      try {
        await ref.read(tokenWalletProvider.notifier).earnTokens(
          5,
          sourceType: 'attendance',
          description: 'Đăng nhập hàng ngày',
        );
      } catch (e) {
        debugPrint('CeoProfileNotifier.loadProfile earnTokens error: $e');
      }

      final updatedProfile = await _service.getCeoProfile(userId, companyId);

      state = CeoProfileState(
        profile: updatedProfile ?? profile,
        isLoading: false,
      );
    } catch (e) {
      state = CeoProfileState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refresh() async => loadProfile();
}

final ceoProfileProvider =
    NotifierProvider<CeoProfileNotifier, CeoProfileState>(() => CeoProfileNotifier());

final ceoLevelProvider = Provider<int>((ref) {
  return ref.watch(ceoProfileProvider).profile?.level ?? 1;
});

final ceoXpProvider = Provider<int>((ref) {
  return ref.watch(ceoProfileProvider).profile?.totalXp ?? 0;
});

final ceoStreakProvider = Provider<int>((ref) {
  return ref.watch(ceoProfileProvider).profile?.streakDays ?? 0;
});

// ──────────────────────────────────────────────
// Quests
// ──────────────────────────────────────────────

final activeQuestsProvider = FutureProvider.autoDispose<List<QuestProgress>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  final allProgress = await service.getQuestProgress(user.id, user.companyId!);

  return allProgress.where((q) => q.status.isActive).toList();
});

final completedQuestsProvider = FutureProvider.autoDispose<List<QuestProgress>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getQuestProgress(user.id, user.companyId!, status: QuestStatus.completed);
});

final questDefinitionsProvider =
    FutureProvider.autoDispose.family<List<QuestDefinition>, QuestType?>((ref, type) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getQuestDefinitions(type: type);
});

// ──────────────────────────────────────────────
// Achievements
// ──────────────────────────────────────────────

final userAchievementsProvider =
    FutureProvider.autoDispose<List<UserAchievement>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getUserAchievements(user.id, user.companyId!);
});

final allAchievementsProvider = FutureProvider.autoDispose<List<Achievement>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getAllAchievements();
});

// ──────────────────────────────────────────────
// XP History
// ──────────────────────────────────────────────

final xpHistoryProvider = FutureProvider.autoDispose<List<XpTransaction>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getXpHistory(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Daily Log
// ──────────────────────────────────────────────

final todayQuestLogProvider = FutureProvider.autoDispose<DailyQuestLog?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return null;

  final service = ref.read(gamificationServiceProvider);
  return service.getTodayLog(user.id, user.companyId!);
});

final loginCalendarProvider = FutureProvider.autoDispose<List<DailyQuestLog>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getLoginHistory(user.id, user.companyId!, days: 30);
});

// ──────────────────────────────────────────────
// Leaderboard
// ──────────────────────────────────────────────

final leaderboardProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getLeaderboard(companyId: user?.companyId);
});

// ──────────────────────────────────────────────
// Actions (for UI to call)
// ──────────────────────────────────────────────

// ──────────────────────────────────────────────
// Daily Quest Results (from evaluate_daily_quests RPC)
// ──────────────────────────────────────────────

final dailyQuestResultsProvider =
    FutureProvider.autoDispose<List<DailyQuestResult>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  final results = await service.evaluateDailyQuests(user.id, user.companyId!);

  return results.map((r) => DailyQuestResult(
    questCode: r['quest_code'] as String,
    isCompleted: r['is_completed'] as bool,
    xpReward: r['xp_reward'] as int,
  )).toList();
});

class DailyQuestResult {
  final String questCode;
  final bool isCompleted;
  final int xpReward;

  const DailyQuestResult({
    required this.questCode,
    required this.isCompleted,
    required this.xpReward,
  });

  String get displayName {
    switch (questCode) {
      case 'attendance': return 'Điểm Danh Hoàn Hảo';
      case 'tasks': return 'Không Ai Bỏ Lại';
      case 'orders': return 'Nhà Buôn Cần Mẫn';
      case 'payment': return 'Thu Tiền Đúng Hạn';
      case 'login': return 'CEO Có Tâm';
      default: return questCode;
    }
  }

  String get description {
    switch (questCode) {
      case 'attendance': return '100% nhân viên điểm danh';
      case 'tasks': return '0 task quá hạn';
      case 'orders': return '3+ đơn hàng trong ngày';
      case 'payment': return '1+ thanh toán trong ngày';
      case 'login': return 'Đăng nhập hôm nay';
      default: return '';
    }
  }

  String get emoji {
    switch (questCode) {
      case 'attendance': return '📋';
      case 'tasks': return '✅';
      case 'orders': return '📦';
      case 'payment': return '💰';
      case 'login': return '🔑';
      default: return '⭐';
    }
  }
}

// ──────────────────────────────────────────────
// Celebration Events
// ──────────────────────────────────────────────

enum CelebrationEvent {
  questComplete,
  levelUp,
  achievementUnlock,
  dailyCombo,
  streakMilestone,
}

class CelebrationData {
  final CelebrationEvent event;
  final String title;
  final String? subtitle;
  final int? xpEarned;
  final int? newLevel;
  final int? tokenEarned;

  const CelebrationData({
    required this.event,
    required this.title,
    this.subtitle,
    this.xpEarned,
    this.newLevel,
    this.tokenEarned,
  });
}

class CelebrationNotifier extends Notifier<CelebrationData?> {
  @override
  CelebrationData? build() => null;

  void celebrate(CelebrationData data) {
    state = data;
  }

  void dismiss() {
    state = null;
  }
}

final celebrationProvider =
    NotifierProvider<CelebrationNotifier, CelebrationData?>(() => CelebrationNotifier());

// ──────────────────────────────────────────────
// Actions (for UI to call)
// ──────────────────────────────────────────────

class GamificationActions {
  final Ref _ref;
  GamificationActions(this._ref);

  GamificationService get _service => _ref.read(gamificationServiceProvider);
  String? get _userId => _ref.read(currentUserProvider)?.id;
  String? get _companyId => _ref.read(currentUserProvider)?.companyId;

  Future<void> completeQuestStep(String progressId, int newProgress) async {
    final oldProfile = _ref.read(ceoProfileProvider).profile;
    final oldLevel = oldProfile?.level ?? 1;

    await _service.updateQuestProgress(
      progressId: progressId,
      newProgress: newProgress,
    );
    _invalidate();

    // Award quest completion tokens
    if (newProgress >= 100) {
      try {
        await _ref.read(tokenWalletProvider.notifier).earnTokens(
          20,
          sourceType: 'quest',
          sourceId: progressId,
          description: 'Hoàn thành quest',
        );
      } catch (e) {
        debugPrint('GamificationActions.completeQuestStep earnTokens error: $e');
      }
    }

    // Check for level up after quest completion
    await Future.delayed(const Duration(milliseconds: 500));
    final newProfile = _ref.read(ceoProfileProvider).profile;
    if (newProfile != null && newProfile.level > oldLevel) {
      // Award level-up bonus tokens
      try {
        await _ref.read(tokenWalletProvider.notifier).earnTokens(
          100,
          sourceType: 'bonus',
          description: 'Lên level ${newProfile.level}!',
        );
      } catch (e) {
        debugPrint('GamificationActions.completeQuestStep levelUp earnTokens error: $e');
      }
      _ref.read(celebrationProvider.notifier).celebrate(CelebrationData(
        event: CelebrationEvent.levelUp,
        title: newProfile.currentTitle,
        subtitle: 'Level ${newProfile.level}',
        newLevel: newProfile.level,
        tokenEarned: 100,
      ));
    }
  }

  Future<void> grantAchievement(String achievementId) async {
    if (_userId == null || _companyId == null) return;
    await _service.grantAchievement(_userId!, _companyId!, achievementId);
    // Award achievement tokens
    try {
      await _ref.read(tokenWalletProvider.notifier).earnTokens(
        50,
        sourceType: 'achievement',
        sourceId: achievementId,
        description: 'Mở khóa thành tựu',
      );
    } catch (e) {
      debugPrint('GamificationActions.grantAchievement earnTokens error: $e');
    }
    _invalidate();
  }

  Future<void> evaluateDailyQuests() async {
    if (_userId == null || _companyId == null) return;
    await _service.evaluateDailyQuests(_userId!, _companyId!);
    _invalidate();
  }

  Future<void> evaluateMainQuests() async {
    if (_userId == null || _companyId == null) return;
    await _service.evaluateMainQuests(_userId!, _companyId!);
    _invalidate();
  }

  Future<({bool success, int remaining, String message})> useStreakFreeze() async {
    if (_userId == null || _companyId == null) {
      return (success: false, remaining: 0, message: 'Not logged in');
    }
    final result = await _service.useStreakFreeze(_userId!, _companyId!);
    _ref.read(ceoProfileProvider.notifier).refresh();
    return result;
  }

  Future<List<Map<String, dynamic>>> evaluateAchievements() async {
    if (_userId == null || _companyId == null) return [];
    final results = await _service.evaluateAchievements(_userId!, _companyId!);
    _ref.invalidate(userAchievementsProvider);
    _ref.invalidate(allAchievementsProvider);

    for (final r in results) {
      if (r['newly_unlocked'] == true) {
        // Award achievement tokens
        try {
          await _ref.read(tokenWalletProvider.notifier).earnTokens(
            50,
            sourceType: 'achievement',
            sourceId: r['achievement_id'] as String?,
            description: r['achievement_name'] as String? ?? 'Thành tựu mới',
          );
        } catch (e) {
          debugPrint('GamificationActions.evaluateAchievements earnTokens error: $e');
        }
        _ref.read(celebrationProvider.notifier).celebrate(CelebrationData(
          event: CelebrationEvent.achievementUnlock,
          title: r['achievement_name'] as String? ?? 'Thành tựu mới!',
          subtitle: r['rarity'] as String?,
          tokenEarned: 50,
        ));
      }
    }
    return results;
  }

  Future<double> refreshHealthScore() async {
    if (_userId == null || _companyId == null) return 0;
    final score = await _service.calculateBusinessHealth(_userId!, _companyId!);
    _ref.read(ceoProfileProvider.notifier).refresh();
    return score;
  }

  Future<void> recalculateStaffScores() async {
    if (_companyId == null) return;
    await _service.recalculateStaffScores(_companyId!);
    _ref.invalidate(staffLeaderboardProvider);
    _ref.invalidate(staffProfilesProvider);
  }

  Future<({bool success, String message})> allocateSkillPoint(String skillCode) async {
    if (_userId == null || _companyId == null) {
      return (success: false, message: 'Not logged in');
    }
    final result = await _service.allocateSkillPoint(_userId!, _companyId!, skillCode);
    _ref.read(ceoProfileProvider.notifier).refresh();
    _ref.invalidate(activeSkillEffectsProvider);
    _ref.invalidate(currentMultiplierProvider);
    return (success: result.success, message: result.message);
  }

  Future<({bool success, String message})> purchaseStoreItem(String itemCode) async {
    if (_userId == null || _companyId == null) {
      return (success: false, message: 'Not logged in');
    }
    final result = await _service.purchaseStoreItem(_userId!, _companyId!, itemCode);
    _ref.read(ceoProfileProvider.notifier).refresh();
    _ref.invalidate(userPurchasesProvider);
    return (success: result.success, message: result.message);
  }

  Future<({bool success, String message, String rewardName})> claimSeasonTier(int tier) async {
    if (_userId == null || _companyId == null) {
      return (success: false, message: 'Not logged in', rewardName: '');
    }
    final result = await _service.claimSeasonTier(_userId!, _companyId!, tier);
    _ref.invalidate(seasonPassProvider);
    if (result.success) {
      // Award season tier tokens
      final tierTokens = tier * 30.0;
      try {
        await _ref.read(tokenWalletProvider.notifier).earnTokens(
          tierTokens,
          sourceType: 'season_reward',
          description: 'Season Tier $tier: ${result.rewardName}',
        );
      } catch (e) {
        debugPrint('GamificationActions.claimSeasonTier earnTokens error: $e');
      }
      _ref.read(celebrationProvider.notifier).celebrate(CelebrationData(
        event: CelebrationEvent.questComplete,
        title: result.rewardName,
        subtitle: 'Season Reward!',
        tokenEarned: tierTokens.toInt(),
      ));
      _invalidate();
    }
    return result;
  }

  Future<({bool success, String message, int newPrestigeLevel})> doPrestige() async {
    if (_userId == null || _companyId == null) {
      return (success: false, message: 'Not logged in', newPrestigeLevel: 0);
    }
    final result = await _service.prestigeReset(_userId!, _companyId!);
    if (result.success) {
      // Award prestige tokens
      final prestigeTokens = result.newPrestigeLevel * 500.0;
      try {
        await _ref.read(tokenWalletProvider.notifier).earnTokens(
          prestigeTokens,
          sourceType: 'bonus',
          description: 'Prestige ${result.newPrestigeLevel} bonus!',
        );
      } catch (e) {
        debugPrint('GamificationActions.doPrestige earnTokens error: $e');
      }
      _ref.read(celebrationProvider.notifier).celebrate(CelebrationData(
        event: CelebrationEvent.levelUp,
        title: 'Prestige ${result.newPrestigeLevel}!',
        subtitle: 'Bắt đầu lại với sức mạnh mới',
        newLevel: result.newPrestigeLevel,
        tokenEarned: prestigeTokens.toInt(),
      ));
      _invalidate();
      _ref.invalidate(prestigeInfoProvider);
    }
    return result;
  }

  Future<void> refreshLeaderboards() async {
    await _service.refreshLeaderboards();
    _ref.invalidate(globalLeaderboardProvider);
    _ref.invalidate(monthlyLeaderboardProvider);
    _ref.invalidate(companyRankingProvider);
  }

  Future<void> markNotificationsRead({List<String>? ids}) async {
    if (_userId == null || _companyId == null) return;
    await _service.markNotificationsRead(_userId!, _companyId!, ids: ids);
    _ref.invalidate(gameNotificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }

  Future<({bool success, String message})> buyPremiumPass() async {
    if (_userId == null || _companyId == null) {
      return (success: false, message: 'Not logged in');
    }
    final result = await _service.buyPremiumPass(_userId!, _companyId!);
    if (result.success) {
      _ref.invalidate(hasPremiumPassProvider);
      _ref.invalidate(seasonTiersProvider);
      _ref.read(ceoProfileProvider.notifier).refresh();
      // Award premium pass bonus tokens
      try {
        await _ref.read(tokenWalletProvider.notifier).earnTokens(
          200,
          sourceType: 'bonus',
          description: 'Premium Pass activation bonus!',
        );
      } catch (e) {
        debugPrint('GamificationActions.buyPremiumPass earnTokens error: $e');
      }
      _ref.read(celebrationProvider.notifier).celebrate(CelebrationData(
        event: CelebrationEvent.questComplete,
        title: 'Premium Pass!',
        subtitle: 'Đã kích hoạt Premium Season Pass',
        tokenEarned: 200,
      ));
    }
    return result;
  }

  void _invalidate() {
    _ref.invalidate(activeQuestsProvider);
    _ref.invalidate(completedQuestsProvider);
    _ref.invalidate(userAchievementsProvider);
    _ref.invalidate(xpHistoryProvider);
    _ref.invalidate(todayQuestLogProvider);
    _ref.invalidate(dailyQuestResultsProvider);
    _ref.invalidate(seasonPassProvider);
    _ref.read(ceoProfileProvider.notifier).refresh();
  }
}

final gamificationActionsProvider = Provider<GamificationActions>(
  (ref) => GamificationActions(ref),
);

// ──────────────────────────────────────────────
// Staff Gamification Providers
// ──────────────────────────────────────────────

final staffProfilesProvider =
    FutureProvider.autoDispose<List<EmployeeGameProfile>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getStaffProfiles(user.companyId!);
});

final staffLeaderboardProvider =
    FutureProvider.autoDispose<List<StaffLeaderboardEntry>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getStaffLeaderboard(user.companyId!);
});

// ──────────────────────────────────────────────
// Skill Tree Providers
// ──────────────────────────────────────────────

final skillDefinitionsProvider =
    FutureProvider.autoDispose<List<SkillDefinition>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getSkillDefinitions();
});

final activeSkillEffectsProvider =
    FutureProvider.autoDispose<List<SkillEffect>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getActiveSkillEffects(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// XP Multiplier Providers
// ──────────────────────────────────────────────

final currentMultiplierProvider = FutureProvider.autoDispose<double>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return 1.0;

  final service = ref.read(gamificationServiceProvider);
  return service.getCurrentMultiplier(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Uy Tín Store Providers
// ──────────────────────────────────────────────

final storeItemsProvider =
    FutureProvider.autoDispose<List<UytinStoreItem>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getStoreItems();
});

final userPurchasesProvider =
    FutureProvider.autoDispose<List<UytinPurchase>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  return service.getUserPurchases(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Enhanced Leaderboard Providers
// ──────────────────────────────────────────────

final globalLeaderboardProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getGlobalLeaderboard();
});

final monthlyLeaderboardProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getMonthlyLeaderboard();
});

final companyRankingProvider =
    FutureProvider.autoDispose<List<CompanyRankEntry>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getCompanyRanking();
});

// ──────────────────────────────────────────────
// Season Pass Providers
// ──────────────────────────────────────────────

final seasonPassProvider =
    FutureProvider.autoDispose<SeasonPassInfo?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return null;

  final service = ref.read(gamificationServiceProvider);
  return service.getSeasonPass(user.id, user.companyId!);
});

final seasonTiersProvider =
    FutureProvider.autoDispose<List<SeasonPassTier>>((ref) async {
  final service = ref.read(gamificationServiceProvider);
  return service.getSeasonTiers();
});

// ──────────────────────────────────────────────
// Prestige Providers
// ──────────────────────────────────────────────

final prestigeInfoProvider =
    FutureProvider.autoDispose<PrestigeInfo?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return null;

  final service = ref.read(gamificationServiceProvider);
  return service.getPrestigeInfo(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Analytics Providers
// ──────────────────────────────────────────────

final engagementMetricsProvider =
    FutureProvider.autoDispose<List<EngagementMetric>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getEngagementMetrics(companyId: user?.companyId);
});

final xpAnalyticsProvider =
    FutureProvider.autoDispose<List<XpAnalytics>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getXpAnalytics(companyId: user?.companyId);
});

final questDropoffProvider =
    FutureProvider.autoDispose<List<QuestDropoff>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getQuestDropoff(companyId: user?.companyId);
});

final levelDistributionProvider =
    FutureProvider.autoDispose<List<LevelDistribution>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getLevelDistribution(companyId: user?.companyId);
});

final xpTrendProvider =
    FutureProvider.autoDispose<List<XpTrendPoint>>((ref) async {
  final user = ref.read(currentUserProvider);
  final service = ref.read(gamificationServiceProvider);
  return service.getXpTrend(companyId: user?.companyId);
});

final weeklySummaryProvider =
    FutureProvider.autoDispose<WeeklySummary?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return null;

  final service = ref.read(gamificationServiceProvider);
  return service.getWeeklySummary(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Notification Providers
// ──────────────────────────────────────────────

final gameNotificationsProvider =
    FutureProvider.autoDispose<List<GameNotification>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return [];

  final service = ref.read(gamificationServiceProvider);
  await service.generateNotifications(user.id, user.companyId!);
  return service.getNotifications(user.id, user.companyId!);
});

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return 0;

  final service = ref.read(gamificationServiceProvider);
  return service.getUnreadCount(user.id, user.companyId!);
});

final hasPremiumPassProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return false;

  final service = ref.read(gamificationServiceProvider);
  return service.hasPremiumPass(user.id, user.companyId!);
});

// ──────────────────────────────────────────────
// Business Config Providers
// ──────────────────────────────────────────────

final businessConfigProvider =
    FutureProvider.autoDispose<BusinessConfig>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return BusinessConfig.empty('unknown');

  final service = ref.read(gamificationServiceProvider);
  final btype = await service.getCompanyBusinessType(user.companyId!) ?? 'billiards';
  return service.getBusinessConfig(btype);
});

final aiConfigProvider =
    FutureProvider.autoDispose<AiGeneratedConfig?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.companyId == null) return null;

  final service = ref.read(gamificationServiceProvider);
  return service.getLatestAiConfig(user.companyId!);
});
