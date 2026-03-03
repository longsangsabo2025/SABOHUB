import '../../core/services/base_service.dart';
import '../../models/gamification/gamification_models.dart';

class GamificationService extends BaseService {
  @override
  String get serviceName => 'GamificationService';

  // ──────────────────────────────────────────────
  // CEO Profile
  // ──────────────────────────────────────────────

  Future<CeoProfile?> getCeoProfile(String userId, String companyId) async {
    return safeCall(
      operation: 'getCeoProfile',
      action: () async {
        final response = await client
            .from('ceo_profiles')
            .select()
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .maybeSingle();

        if (response == null) return null;
        return CeoProfile.fromJson(response);
      },
    );
  }

  Future<CeoProfile> getOrCreateProfile(String userId, String companyId) async {
    return safeCall(
      operation: 'getOrCreateProfile',
      action: () async {
        final existing = await getCeoProfile(userId, companyId);
        if (existing != null) return existing;

        final response = await client
            .from('ceo_profiles')
            .insert({'user_id': userId, 'company_id': companyId})
            .select()
            .single();

        return CeoProfile.fromJson(response);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Daily Login
  // ──────────────────────────────────────────────

  Future<({int streak, int xpEarned, bool isNewLogin})> recordDailyLogin(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'recordDailyLogin',
      action: () async {
        final response = await client.rpc('record_daily_login', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          streak: data['streak'] as int,
          xpEarned: data['xp_earned'] as int,
          isNewLogin: data['is_new_login'] as bool,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // XP
  // ──────────────────────────────────────────────

  Future<({int newLevel, int newTotalXp, bool leveledUp, String newTitle})> addXp({
    required String userId,
    required String companyId,
    required int amount,
    double multiplier = 1.0,
    String sourceType = 'bonus',
    String? sourceId,
    String? description,
  }) async {
    return safeCall(
      operation: 'addXp',
      action: () async {
        final response = await client.rpc('add_xp', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_amount': amount,
          'p_multiplier': multiplier,
          'p_source_type': sourceType,
          'p_source_id': sourceId,
          'p_description': description,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          newLevel: data['new_level'] as int,
          newTotalXp: (data['new_total_xp'] as num).toInt(),
          leveledUp: data['leveled_up'] as bool,
          newTitle: data['new_title'] as String,
        );
      },
    );
  }

  Future<List<XpTransaction>> getXpHistory(
    String userId,
    String companyId, {
    int limit = 50,
  }) async {
    return safeCall(
      operation: 'getXpHistory',
      action: () async {
        final response = await client
            .from('xp_transactions')
            .select()
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .order('created_at', ascending: false)
            .limit(limit);

        return (response as List)
            .map((json) => XpTransaction.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Quests
  // ──────────────────────────────────────────────

  Future<List<QuestDefinition>> getQuestDefinitions({
    QuestType? type,
    int? act,
    String? businessType,
  }) async {
    return safeCall(
      operation: 'getQuestDefinitions',
      action: () async {
        var query = client
            .from('quest_definitions')
            .select()
            .eq('is_active', true);

        if (type != null) query = query.eq('quest_type', type.value);
        if (act != null) query = query.eq('act', act);
        if (businessType != null) query = query.eq('business_type', businessType);

        final response = await query.order('sort_order');

        return (response as List)
            .map((json) => QuestDefinition.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<QuestProgress>> getQuestProgress(
    String userId,
    String companyId, {
    QuestStatus? status,
  }) async {
    return safeCall(
      operation: 'getQuestProgress',
      action: () async {
        var query = client
            .from('quest_progress')
            .select('*, quest_definitions(*)')
            .eq('user_id', userId)
            .eq('company_id', companyId);

        if (status != null) query = query.eq('status', status.value);

        final response = await query.order('updated_at', ascending: false);

        return (response as List)
            .map((json) => QuestProgress.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<void> initializeQuestsForUser(String userId, String companyId) async {
    return safeCall(
      operation: 'initializeQuestsForUser',
      action: () async {
        final existingProgress = await client
            .from('quest_progress')
            .select('quest_id')
            .eq('user_id', userId)
            .eq('company_id', companyId);

        final existingQuestIds =
            (existingProgress as List).map((e) => e['quest_id'] as String).toSet();

        final act1Quests = await client
            .from('quest_definitions')
            .select()
            .eq('is_active', true)
            .eq('quest_type', 'main')
            .eq('act', 1)
            .order('sort_order');

        final newEntries = <Map<String, dynamic>>[];
        final questList = act1Quests as List;
        for (int i = 0; i < questList.length; i++) {
          final quest = questList[i] as Map<String, dynamic>;
          if (existingQuestIds.contains(quest['id'])) continue;

          newEntries.add({
            'user_id': userId,
            'company_id': companyId,
            'quest_id': quest['id'],
            'status': i == 0 ? 'available' : 'locked',
            'progress_current': 0,
            'progress_target': _targetFromConditions(quest['conditions']),
          });
        }

        if (newEntries.isNotEmpty) {
          await client.from('quest_progress').upsert(
                newEntries,
                onConflict: 'user_id,company_id,quest_id',
              );
        }
      },
    );
  }

  Future<QuestProgress> updateQuestProgress({
    required String progressId,
    required int newProgress,
  }) async {
    return safeCall(
      operation: 'updateQuestProgress',
      action: () async {
        final current = await client
            .from('quest_progress')
            .select('*, quest_definitions(*)')
            .eq('id', progressId)
            .single();

        final progress = QuestProgress.fromJson(current);
        final isNowComplete = newProgress >= progress.progressTarget;

        final updateData = <String, dynamic>{
          'progress_current': newProgress,
          'status': isNowComplete ? 'completed' : 'in_progress',
          if (progress.startedAt == null) 'started_at': DateTime.now().toIso8601String(),
          if (isNowComplete) 'completed_at': DateTime.now().toIso8601String(),
        };

        final response = await client
            .from('quest_progress')
            .update(updateData)
            .eq('id', progressId)
            .select('*, quest_definitions(*)')
            .single();

        if (isNowComplete && progress.quest != null) {
          await addXp(
            userId: progress.userId,
            companyId: progress.companyId,
            amount: progress.quest!.xpReward,
            sourceType: 'quest',
            sourceId: progress.questId,
            description: 'Hoàn thành: ${progress.quest!.name}',
          );

          await _unlockNextQuest(progress.userId, progress.companyId, progress.questId);
        }

        return QuestProgress.fromJson(response);
      },
    );
  }

  Future<void> _unlockNextQuest(String userId, String companyId, String completedQuestId) async {
    final allProgress = await client
        .from('quest_progress')
        .select('quest_id, status')
        .eq('user_id', userId)
        .eq('company_id', companyId);

    final completedIds = (allProgress as List)
        .where((p) => p['status'] == 'completed')
        .map((p) => p['quest_id'] as String)
        .toSet();

    final lockedProgress = await client
        .from('quest_progress')
        .select('id, quest_id, quest_definitions(prerequisites)')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .eq('status', 'locked');

    for (final locked in lockedProgress as List) {
      final questDef = locked['quest_definitions'] as Map<String, dynamic>?;
      final prereqs = (questDef?['prerequisites'] as List<dynamic>?) ?? [];

      if (prereqs.isEmpty) continue;

      final allPrereqsMet = prereqs.every((p) => completedIds.contains(p));
      if (allPrereqsMet) {
        await client
            .from('quest_progress')
            .update({'status': 'available'})
            .eq('id', locked['id']);
      }
    }
  }

  int _targetFromConditions(dynamic conditions) {
    if (conditions == null || conditions is! Map) return 1;
    final value = conditions['value'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  // ──────────────────────────────────────────────
  // Achievements
  // ──────────────────────────────────────────────

  Future<List<Achievement>> getAllAchievements({bool includeSecret = false}) async {
    return safeCall(
      operation: 'getAllAchievements',
      action: () async {
        var query = client.from('achievements').select();
        if (!includeSecret) query = query.eq('is_secret', false);

        final response = await query.order('sort_order');
        return (response as List)
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<UserAchievement>> getUserAchievements(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'getUserAchievements',
      action: () async {
        final response = await client
            .from('user_achievements')
            .select('*, achievements(*)')
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .order('unlocked_at', ascending: false);

        return (response as List)
            .map((json) => UserAchievement.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<UserAchievement> grantAchievement(
    String userId,
    String companyId,
    String achievementId,
  ) async {
    return safeCall(
      operation: 'grantAchievement',
      action: () async {
        final response = await client
            .from('user_achievements')
            .upsert(
              {
                'user_id': userId,
                'company_id': companyId,
                'achievement_id': achievementId,
              },
              onConflict: 'user_id,company_id,achievement_id',
            )
            .select('*, achievements(*)')
            .single();

        return UserAchievement.fromJson(response);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Leaderboard
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaderboard({
    String? companyId,
    int limit = 20,
  }) async {
    return safeCall(
      operation: 'getLeaderboard',
      action: () async {
        final response = await client.rpc('get_ceo_leaderboard', params: {
          'p_company_id': companyId,
          'p_limit': limit,
        });

        return (response as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Daily Quest Evaluation
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> evaluateDailyQuests(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'evaluateDailyQuests',
      action: () async {
        final response = await client.rpc('evaluate_daily_quests', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });

        return (response as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
  }

  Future<void> evaluateMainQuests(String userId, String companyId) async {
    return safeCall(
      operation: 'evaluateMainQuests',
      action: () async {
        await client.rpc('evaluate_user_quests', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_event_type': 'manual',
        });
      },
    );
  }

  // ──────────────────────────────────────────────
  // Streak Freeze
  // ──────────────────────────────────────────────

  Future<({bool success, int remaining, String message})> useStreakFreeze(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'useStreakFreeze',
      action: () async {
        final response = await client.rpc('use_streak_freeze', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          remaining: data['remaining'] as int,
          message: data['message'] as String,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Daily Quest Log
  // ──────────────────────────────────────────────

  Future<DailyQuestLog?> getTodayLog(String userId, String companyId) async {
    return safeCall(
      operation: 'getTodayLog',
      action: () async {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final response = await client
            .from('daily_quest_log')
            .select()
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .eq('log_date', today)
            .maybeSingle();

        if (response == null) return null;
        return DailyQuestLog.fromJson(response);
      },
    );
  }

  Future<List<DailyQuestLog>> getLoginHistory(
    String userId,
    String companyId, {
    int days = 30,
  }) async {
    return safeCall(
      operation: 'getLoginHistory',
      action: () async {
        final fromDate =
            DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);

        final response = await client
            .from('daily_quest_log')
            .select()
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .gte('log_date', fromDate)
            .order('log_date', ascending: false);

        return (response as List)
            .map((json) => DailyQuestLog.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Achievement Auto-Evaluation
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> evaluateAchievements(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'evaluateAchievements',
      action: () async {
        final response = await client.rpc('evaluate_achievements', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });

        return (response as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Business Health Score
  // ──────────────────────────────────────────────

  Future<double> calculateBusinessHealth(String userId, String companyId) async {
    return safeCall(
      operation: 'calculateBusinessHealth',
      action: () async {
        final response = await client.rpc('calculate_business_health', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return (response as num).toDouble();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Staff Gamification
  // ──────────────────────────────────────────────

  Future<List<EmployeeGameProfile>> getStaffProfiles(String companyId) async {
    return safeCall(
      operation: 'getStaffProfiles',
      action: () async {
        final response = await client
            .from('employee_game_profiles')
            .select('*, employees(full_name)')
            .eq('company_id', companyId)
            .order('total_xp', ascending: false);

        return (response as List)
            .map((json) => EmployeeGameProfile.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<EmployeeGameProfile?> getStaffProfile(
    String employeeId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'getStaffProfile',
      action: () async {
        final response = await client
            .from('employee_game_profiles')
            .select('*, employees(full_name)')
            .eq('employee_id', employeeId)
            .eq('company_id', companyId)
            .maybeSingle();

        if (response == null) return null;
        return EmployeeGameProfile.fromJson(response);
      },
    );
  }

  Future<List<StaffLeaderboardEntry>> getStaffLeaderboard(
    String companyId, {
    int limit = 20,
  }) async {
    return safeCall(
      operation: 'getStaffLeaderboard',
      action: () async {
        final response = await client.rpc('get_staff_leaderboard', params: {
          'p_company_id': companyId,
          'p_limit': limit,
        });

        return (response as List)
            .map((e) => StaffLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<void> recalculateStaffScores(String companyId) async {
    return safeCall(
      operation: 'recalculateStaffScores',
      action: () async {
        await client.rpc('calculate_employee_scores', params: {
          'p_company_id': companyId,
        });
      },
    );
  }

  // ──────────────────────────────────────────────
  // Skill Tree
  // ──────────────────────────────────────────────

  Future<List<SkillDefinition>> getSkillDefinitions() async {
    return safeCall(
      operation: 'getSkillDefinitions',
      action: () async {
        final response = await client
            .from('skill_definitions')
            .select()
            .order('branch')
            .order('tier');

        return (response as List)
            .map((json) => SkillDefinition.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<({bool success, String message, Map<String, dynamic> newTree, int remaining})>
      allocateSkillPoint(String userId, String companyId, String skillCode) async {
    return safeCall(
      operation: 'allocateSkillPoint',
      action: () async {
        final response = await client.rpc('allocate_skill_point', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_skill_code': skillCode,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
          newTree: data['new_skill_tree'] as Map<String, dynamic>,
          remaining: data['remaining_points'] as int,
        );
      },
    );
  }

  Future<List<SkillEffect>> getActiveSkillEffects(String userId, String companyId) async {
    return safeCall(
      operation: 'getActiveSkillEffects',
      action: () async {
        final response = await client.rpc('get_skill_effects', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });

        return (response as List)
            .map((e) => SkillEffect.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ──────────────────────────────────────────────
  // XP Multiplier
  // ──────────────────────────────────────────────

  Future<double> getCurrentMultiplier(String userId, String companyId) async {
    return safeCall(
      operation: 'getCurrentMultiplier',
      action: () async {
        final response = await client.rpc('get_current_multiplier', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return (response as num).toDouble();
      },
    );
  }

  // ──────────────────────────────────────────────
  // Uy Tín Store
  // ──────────────────────────────────────────────

  Future<List<UytinStoreItem>> getStoreItems() async {
    return safeCall(
      operation: 'getStoreItems',
      action: () async {
        final response = await client
            .from('uytin_store_items')
            .select()
            .eq('is_active', true)
            .order('sort_order');

        return (response as List)
            .map((json) => UytinStoreItem.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<UytinPurchase>> getUserPurchases(String userId, String companyId) async {
    return safeCall(
      operation: 'getUserPurchases',
      action: () async {
        final response = await client
            .from('uytin_purchases')
            .select('*, uytin_store_items(*)')
            .eq('user_id', userId)
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('purchased_at', ascending: false);

        return (response as List)
            .map((json) => UytinPurchase.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<({bool success, String message, int remainingReputation})>
      purchaseStoreItem(String userId, String companyId, String itemCode) async {
    return safeCall(
      operation: 'purchaseStoreItem',
      action: () async {
        final response = await client.rpc('purchase_store_item', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_item_code': itemCode,
        });

        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
          remainingReputation: data['remaining_reputation'] as int,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Enhanced Leaderboards (Materialized Views)
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({int limit = 50}) async {
    return safeCall(
      operation: 'getGlobalLeaderboard',
      action: () async {
        final response = await client.rpc('get_global_leaderboard', params: {'p_limit': limit});
        return (response as List).map((e) => e as Map<String, dynamic>).toList();
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyLeaderboard({int limit = 50}) async {
    return safeCall(
      operation: 'getMonthlyLeaderboard',
      action: () async {
        final response = await client.rpc('get_monthly_leaderboard', params: {'p_limit': limit});
        return (response as List).map((e) => e as Map<String, dynamic>).toList();
      },
    );
  }

  Future<List<CompanyRankEntry>> getCompanyRanking({int limit = 50}) async {
    return safeCall(
      operation: 'getCompanyRanking',
      action: () async {
        final response = await client.rpc('get_company_ranking', params: {'p_limit': limit});
        return (response as List)
            .map((e) => CompanyRankEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<void> refreshLeaderboards() async {
    return safeCall(
      operation: 'refreshLeaderboards',
      action: () async {
        await client.rpc('refresh_leaderboards');
      },
    );
  }

  // ──────────────────────────────────────────────
  // Season Pass
  // ──────────────────────────────────────────────

  Future<SeasonPassInfo?> getSeasonPass(String userId, String companyId) async {
    return safeCall(
      operation: 'getSeasonPass',
      action: () async {
        final response = await client.rpc('get_season_pass', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        final list = response as List;
        if (list.isEmpty) return null;
        return SeasonPassInfo.fromJson(list.first as Map<String, dynamic>);
      },
    );
  }

  Future<List<SeasonPassTier>> getSeasonTiers() async {
    return safeCall(
      operation: 'getSeasonTiers',
      action: () async {
        final season = await client.from('seasons').select('id').eq('is_active', true).maybeSingle();
        if (season == null) return <SeasonPassTier>[];

        final response = await client
            .from('season_pass_tiers')
            .select()
            .eq('season_id', season['id'])
            .eq('is_premium', false)
            .order('tier');

        return (response as List)
            .map((json) => SeasonPassTier.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<({bool success, String message, String rewardName})> claimSeasonTier(
    String userId,
    String companyId,
    int tier,
  ) async {
    return safeCall(
      operation: 'claimSeasonTier',
      action: () async {
        final response = await client.rpc('claim_season_tier', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_tier': tier,
        });
        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
          rewardName: data['reward_name'] as String? ?? '',
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Prestige
  // ──────────────────────────────────────────────

  Future<PrestigeInfo?> getPrestigeInfo(String userId, String companyId) async {
    return safeCall(
      operation: 'getPrestigeInfo',
      action: () async {
        final response = await client.rpc('get_prestige_info', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        final list = response as List;
        if (list.isEmpty) return null;
        return PrestigeInfo.fromJson(list.first as Map<String, dynamic>);
      },
    );
  }

  Future<({bool success, String message, int newPrestigeLevel})> prestigeReset(
    String userId,
    String companyId,
  ) async {
    return safeCall(
      operation: 'prestigeReset',
      action: () async {
        final response = await client.rpc('prestige_reset', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
          newPrestigeLevel: data['new_prestige_level'] as int? ?? 0,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Analytics
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQuestAnalytics({String? companyId}) async {
    return safeCall(
      operation: 'getQuestAnalytics',
      action: () async {
        final response = await client.rpc('get_quest_analytics', params: {
          'p_company_id': companyId,
        });
        return (response as List).map((e) => e as Map<String, dynamic>).toList();
      },
    );
  }

  Future<List<XpAnalytics>> getXpAnalytics({String? companyId, int days = 30}) async {
    return safeCall(
      operation: 'getXpAnalytics',
      action: () async {
        final response = await client.rpc('get_xp_analytics', params: {
          'p_company_id': companyId,
          'p_days': days,
        });
        return (response as List)
            .map((e) => XpAnalytics.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<EngagementMetric>> getEngagementMetrics({String? companyId}) async {
    return safeCall(
      operation: 'getEngagementMetrics',
      action: () async {
        final response = await client.rpc('get_engagement_metrics', params: {
          'p_company_id': companyId,
        });
        return (response as List)
            .map((e) => EngagementMetric.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<QuestDropoff>> getQuestDropoff({String? companyId}) async {
    return safeCall(
      operation: 'getQuestDropoff',
      action: () async {
        final response = await client.rpc('get_quest_dropoff', params: {
          'p_company_id': companyId,
        });
        return (response as List)
            .map((e) => QuestDropoff.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<LevelDistribution>> getLevelDistribution({String? companyId}) async {
    return safeCall(
      operation: 'getLevelDistribution',
      action: () async {
        final response = await client.rpc('get_level_distribution', params: {
          'p_company_id': companyId,
        });
        return (response as List)
            .map((e) => LevelDistribution.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<List<XpTrendPoint>> getXpTrend({String? companyId, int days = 14}) async {
    return safeCall(
      operation: 'getXpTrend',
      action: () async {
        final response = await client.rpc('get_xp_trend', params: {
          'p_company_id': companyId,
          'p_days': days,
        });
        return (response as List)
            .map((e) => XpTrendPoint.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<WeeklySummary?> getWeeklySummary(String userId, String companyId) async {
    return safeCall(
      operation: 'getWeeklySummary',
      action: () async {
        final response = await client.rpc('generate_weekly_summary', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        final list = response as List;
        if (list.isEmpty) return null;
        return WeeklySummary.fromJson(list.first as Map<String, dynamic>);
      },
    );
  }

  // ──────────────────────────────────────────────
  // Notifications
  // ──────────────────────────────────────────────

  Future<List<GameNotification>> getNotifications(
    String userId,
    String companyId, {
    bool unreadOnly = false,
    int limit = 20,
  }) async {
    return safeCall(
      operation: 'getNotifications',
      action: () async {
        final response = await client.rpc('get_game_notifications', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_limit': limit,
          'p_unread_only': unreadOnly,
        });
        return (response as List)
            .map((e) => GameNotification.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<int> generateNotifications(String userId, String companyId) async {
    return safeCall(
      operation: 'generateNotifications',
      action: () async {
        final response = await client.rpc('generate_game_notifications', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return response as int? ?? 0;
      },
    );
  }

  Future<int> markNotificationsRead(String userId, String companyId, {List<String>? ids}) async {
    return safeCall(
      operation: 'markNotificationsRead',
      action: () async {
        final response = await client.rpc('mark_notifications_read', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
          'p_notification_ids': ids,
        });
        return response as int? ?? 0;
      },
    );
  }

  Future<int> getUnreadCount(String userId, String companyId) async {
    return safeCall(
      operation: 'getUnreadCount',
      action: () async {
        final response = await client.rpc('get_unread_notification_count', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return response as int? ?? 0;
      },
    );
  }

  // ──────────────────────────────────────────────
  // Premium Pass
  // ──────────────────────────────────────────────

  Future<bool> hasPremiumPass(String userId, String companyId) async {
    return safeCall(
      operation: 'hasPremiumPass',
      action: () async {
        final response = await client.rpc('has_premium_pass', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return response as bool? ?? false;
      },
    );
  }

  Future<({bool success, String message})> buyPremiumPass(String userId, String companyId) async {
    return safeCall(
      operation: 'buyPremiumPass',
      action: () async {
        final response = await client.rpc('buy_premium_pass', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Business Type Config
  // ──────────────────────────────────────────────

  Future<BusinessConfig> getBusinessConfig(String businessType) async {
    return safeCall(
      operation: 'getBusinessConfig',
      action: () async {
        final response = await client.rpc('get_business_config', params: {
          'p_business_type': businessType,
        });
        final list = (response as List)
            .map((e) => BusinessTypeMapping.fromJson(e as Map<String, dynamic>))
            .toList();
        return BusinessConfig.fromList(businessType, list);
      },
    );
  }

  Future<int> initializeQuestsForCompany(String userId, String companyId) async {
    return safeCall(
      operation: 'initializeQuestsForCompany',
      action: () async {
        final response = await client.rpc('initialize_quests_for_company', params: {
          'p_user_id': userId,
          'p_company_id': companyId,
        });
        return response as int? ?? 0;
      },
    );
  }

  // ──────────────────────────────────────────────
  // AI Quest Generation
  // ──────────────────────────────────────────────

  Future<AiGeneratedConfig?> getLatestAiConfig(String companyId) async {
    return safeCall(
      operation: 'getLatestAiConfig',
      action: () async {
        final response = await client
            .from('ai_generated_configs')
            .select()
            .eq('company_id', companyId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response == null) return null;
        return AiGeneratedConfig.fromJson(response);
      },
    );
  }

  Future<String> generateAiConfig(String companyId, String businessType) async {
    return safeCall(
      operation: 'generateAiConfig',
      action: () async {
        final response = await client.functions.invoke(
          'generate-quest-config',
          body: {
            'company_id': companyId,
            'business_type': businessType,
          },
        );
        final data = response.data as Map<String, dynamic>;
        return data['config_id'] as String;
      },
    );
  }

  Future<({bool success, String message, int configsApplied, int questsCreated})>
      applyAiConfig(String configId, String userId) async {
    return safeCall(
      operation: 'applyAiConfig',
      action: () async {
        final response = await client.rpc('apply_ai_config', params: {
          'p_config_id': configId,
          'p_user_id': userId,
        });
        final data = (response as List).first as Map<String, dynamic>;
        return (
          success: data['success'] as bool,
          message: data['message'] as String,
          configsApplied: data['configs_applied'] as int? ?? 0,
          questsCreated: data['quests_created'] as int? ?? 0,
        );
      },
    );
  }

  Future<String?> getCompanyBusinessType(String companyId) async {
    return safeCall(
      operation: 'getCompanyBusinessType',
      action: () async {
        final response = await client
            .from('companies')
            .select('business_type')
            .eq('id', companyId)
            .maybeSingle();
        return response?['business_type'] as String?;
      },
    );
  }

  Future<void> rejectAiConfig(String configId) async {
    return safeCall(
      operation: 'rejectAiConfig',
      action: () async {
        await client
            .from('ai_generated_configs')
            .update({'status': 'rejected'})
            .eq('id', configId);
      },
    );
  }
}
