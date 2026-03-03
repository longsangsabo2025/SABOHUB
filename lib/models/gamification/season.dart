class SeasonPassInfo {
  final String seasonName;
  final int seasonNumber;
  final int seasonXp;
  final int currentTier;
  final List<int> claimedTiers;
  final DateTime startDate;
  final DateTime endDate;
  final double bonusMultiplier;
  final int daysRemaining;

  const SeasonPassInfo({
    required this.seasonName,
    required this.seasonNumber,
    this.seasonXp = 0,
    this.currentTier = 0,
    this.claimedTiers = const [],
    required this.startDate,
    required this.endDate,
    this.bonusMultiplier = 1.0,
    this.daysRemaining = 0,
  });

  factory SeasonPassInfo.fromJson(Map<String, dynamic> json) {
    return SeasonPassInfo(
      seasonName: json['season_name'] as String,
      seasonNumber: json['season_number'] as int,
      seasonXp: json['season_xp'] as int? ?? 0,
      currentTier: json['current_tier'] as int? ?? 0,
      claimedTiers: (json['claimed_tiers'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      bonusMultiplier: (json['bonus_multiplier'] as num?)?.toDouble() ?? 1.0,
      daysRemaining: json['days_remaining'] as int? ?? 0,
    );
  }
}

class SeasonPassTier {
  final String id;
  final String seasonId;
  final int tier;
  final int xpRequired;
  final String rewardType;
  final Map<String, dynamic> rewardValue;
  final String rewardName;
  final String rewardIcon;
  final bool isPremium;

  const SeasonPassTier({
    required this.id,
    required this.seasonId,
    required this.tier,
    required this.xpRequired,
    required this.rewardType,
    this.rewardValue = const {},
    required this.rewardName,
    this.rewardIcon = 'star',
    this.isPremium = false,
  });

  String get iconEmoji {
    const map = {
      'bolt': '⚡', 'star': '⭐', 'shield': '🛡️', 'sword': '⚔️',
      'crown': '👑', 'fire': '🔥', 'diamond': '💎',
    };
    return map[rewardIcon] ?? '🎁';
  }

  factory SeasonPassTier.fromJson(Map<String, dynamic> json) {
    return SeasonPassTier(
      id: json['id'] as String,
      seasonId: json['season_id'] as String,
      tier: json['tier'] as int,
      xpRequired: json['xp_required'] as int,
      rewardType: json['reward_type'] as String,
      rewardValue: json['reward_value'] as Map<String, dynamic>? ?? {},
      rewardName: json['reward_name'] as String,
      rewardIcon: json['reward_icon'] as String? ?? 'star',
      isPremium: json['is_premium'] as bool? ?? false,
    );
  }
}

class PrestigeInfo {
  final int prestigeLevel;
  final Map<String, dynamic> prestigeBonuses;
  final bool canPrestige;
  final int totalPrestiges;
  final int highestLevelEver;

  const PrestigeInfo({
    this.prestigeLevel = 0,
    this.prestigeBonuses = const {},
    this.canPrestige = false,
    this.totalPrestiges = 0,
    this.highestLevelEver = 1,
  });

  int get xpBonusPercent => (prestigeBonuses['xp_bonus_percent'] as num?)?.toInt() ?? 0;
  int get reputationBonusPercent => (prestigeBonuses['reputation_bonus_percent'] as num?)?.toInt() ?? 0;
  int get maxStreakFreeze => (prestigeBonuses['max_streak_freeze'] as num?)?.toInt() ?? 1;

  factory PrestigeInfo.fromJson(Map<String, dynamic> json) {
    return PrestigeInfo(
      prestigeLevel: json['prestige_level'] as int? ?? 0,
      prestigeBonuses: json['prestige_bonuses'] as Map<String, dynamic>? ?? {},
      canPrestige: json['can_prestige'] as bool? ?? false,
      totalPrestiges: json['total_prestiges'] as int? ?? 0,
      highestLevelEver: json['highest_level_ever'] as int? ?? 1,
    );
  }
}

class CompanyRankEntry {
  final int rank;
  final String companyId;
  final String companyName;
  final String? businessType;
  final int ceoCount;
  final int totalXp;
  final int avgLevel;
  final double avgHealth;
  final int totalReputation;
  final int totalEmployees;
  final double avgStaffRating;

  const CompanyRankEntry({
    required this.rank,
    required this.companyId,
    required this.companyName,
    this.businessType,
    this.ceoCount = 0,
    this.totalXp = 0,
    this.avgLevel = 0,
    this.avgHealth = 0,
    this.totalReputation = 0,
    this.totalEmployees = 0,
    this.avgStaffRating = 0,
  });

  factory CompanyRankEntry.fromJson(Map<String, dynamic> json) {
    return CompanyRankEntry(
      rank: (json['rank'] as num).toInt(),
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String? ?? 'Company',
      businessType: json['business_type'] as String?,
      ceoCount: (json['ceo_count'] as num?)?.toInt() ?? 0,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      avgLevel: (json['avg_level'] as num?)?.toInt() ?? 0,
      avgHealth: (json['avg_health'] as num?)?.toDouble() ?? 0,
      totalReputation: (json['total_reputation'] as num?)?.toInt() ?? 0,
      totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
      avgStaffRating: (json['avg_staff_rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
