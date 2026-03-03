import 'dart:math';

class CeoLevel {
  static const int maxLevel = 100;

  static int xpForLevel(int level) => (100 * pow(level, 1.5)).floor();

  static int levelFromXp(int totalXp) {
    int lvl = 1;
    while (lvl < maxLevel && xpForLevel(lvl + 1) <= totalXp) {
      lvl++;
    }
    return lvl;
  }

  static String titleForLevel(int level) {
    if (level >= 100) return 'Huyền Thoại';
    if (level >= 76) return 'Đế Vương';
    if (level >= 51) return 'Tướng Quân';
    if (level >= 31) return 'Doanh Nhân';
    if (level >= 16) return 'Ông Chủ';
    if (level >= 6) return 'Chủ Tiệm';
    return 'Tân Binh';
  }

  static String titleEnglish(int level) {
    if (level >= 100) return 'Legend';
    if (level >= 76) return 'Emperor';
    if (level >= 51) return 'General';
    if (level >= 31) return 'Entrepreneur';
    if (level >= 16) return 'Boss';
    if (level >= 6) return 'Shop Owner';
    return 'Rookie';
  }
}

class SkillTree {
  final int leader;
  final int merchant;
  final int strategist;

  const SkillTree({
    this.leader = 0,
    this.merchant = 0,
    this.strategist = 0,
  });

  int get total => leader + merchant + strategist;

  factory SkillTree.fromJson(Map<String, dynamic> json) {
    return SkillTree(
      leader: json['leader'] as int? ?? 0,
      merchant: json['merchant'] as int? ?? 0,
      strategist: json['strategist'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'leader': leader,
        'merchant': merchant,
        'strategist': strategist,
      };

  SkillTree copyWith({int? leader, int? merchant, int? strategist}) {
    return SkillTree(
      leader: leader ?? this.leader,
      merchant: merchant ?? this.merchant,
      strategist: strategist ?? this.strategist,
    );
  }
}

class CeoProfile {
  final String id;
  final String userId;
  final String companyId;
  final int level;
  final int totalXp;
  final String currentTitle;
  final List<String> activeBadges;
  final int streakDays;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final int streakFreezeRemaining;
  final int reputationPoints;
  final int skillPoints;
  final SkillTree skillTree;
  final double businessHealthScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CeoProfile({
    required this.id,
    required this.userId,
    required this.companyId,
    this.level = 1,
    this.totalXp = 0,
    this.currentTitle = 'Tân Binh',
    this.activeBadges = const [],
    this.streakDays = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
    this.streakFreezeRemaining = 1,
    this.reputationPoints = 0,
    this.skillPoints = 0,
    this.skillTree = const SkillTree(),
    this.businessHealthScore = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get xpForCurrentLevel => CeoLevel.xpForLevel(level);
  int get xpForNextLevel => level >= CeoLevel.maxLevel ? totalXp : CeoLevel.xpForLevel(level + 1);
  int get xpInCurrentLevel => totalXp - xpForCurrentLevel;
  int get xpNeededForNext => xpForNextLevel - xpForCurrentLevel;
  double get levelProgress =>
      xpNeededForNext > 0 ? (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0) : 1.0;
  bool get isMaxLevel => level >= CeoLevel.maxLevel;

  factory CeoProfile.fromJson(Map<String, dynamic> json) {
    return CeoProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      level: json['level'] as int? ?? 1,
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      currentTitle: json['current_title'] as String? ?? 'Tân Binh',
      activeBadges: (json['active_badges'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      streakDays: json['streak_days'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastLoginDate: json['last_login_date'] != null
          ? DateTime.tryParse(json['last_login_date'] as String)
          : null,
      streakFreezeRemaining: json['streak_freeze_remaining'] as int? ?? 1,
      reputationPoints: json['reputation_points'] as int? ?? 0,
      skillPoints: json['skill_points'] as int? ?? 0,
      skillTree: json['skill_tree'] != null
          ? SkillTree.fromJson(json['skill_tree'] as Map<String, dynamic>)
          : const SkillTree(),
      businessHealthScore: (json['business_health_score'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'company_id': companyId,
        'level': level,
        'total_xp': totalXp,
        'current_title': currentTitle,
        'active_badges': activeBadges,
        'streak_days': streakDays,
        'longest_streak': longestStreak,
        'last_login_date': lastLoginDate?.toIso8601String(),
        'streak_freeze_remaining': streakFreezeRemaining,
        'reputation_points': reputationPoints,
        'skill_points': skillPoints,
        'skill_tree': skillTree.toJson(),
        'business_health_score': businessHealthScore,
      };

  CeoProfile copyWith({
    int? level,
    int? totalXp,
    String? currentTitle,
    List<String>? activeBadges,
    int? streakDays,
    int? longestStreak,
    DateTime? lastLoginDate,
    int? streakFreezeRemaining,
    int? reputationPoints,
    int? skillPoints,
    SkillTree? skillTree,
    double? businessHealthScore,
  }) {
    return CeoProfile(
      id: id,
      userId: userId,
      companyId: companyId,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentTitle: currentTitle ?? this.currentTitle,
      activeBadges: activeBadges ?? this.activeBadges,
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      streakFreezeRemaining: streakFreezeRemaining ?? this.streakFreezeRemaining,
      reputationPoints: reputationPoints ?? this.reputationPoints,
      skillPoints: skillPoints ?? this.skillPoints,
      skillTree: skillTree ?? this.skillTree,
      businessHealthScore: businessHealthScore ?? this.businessHealthScore,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static CeoProfile empty() => CeoProfile(
        id: '',
        userId: '',
        companyId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
