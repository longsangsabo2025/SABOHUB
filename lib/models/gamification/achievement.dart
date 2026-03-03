enum AchievementRarity {
  common('common', 'Phổ thông', '🟢'),
  rare('rare', 'Hiếm', '🔵'),
  epic('epic', 'Sử thi', '🟣'),
  legendary('legendary', 'Huyền thoại', '🟡'),
  mythic('mythic', 'Thần thoại', '🔴');

  final String value;
  final String label;
  final String emoji;
  const AchievementRarity(this.value, this.label, this.emoji);

  static AchievementRarity fromString(String value) {
    return AchievementRarity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AchievementRarity.common,
    );
  }
}

class Achievement {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String icon;
  final AchievementRarity rarity;
  final String? category;
  final String conditionType;
  final Map<String, dynamic> conditionValue;
  final bool isSecret;
  final int sortOrder;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.icon = 'star',
    this.rarity = AchievementRarity.common,
    this.category,
    required this.conditionType,
    this.conditionValue = const {},
    this.isSecret = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String? ?? 'star',
      rarity: AchievementRarity.fromString(json['rarity'] as String? ?? 'common'),
      category: json['category'] as String?,
      conditionType: json['condition_type'] as String,
      conditionValue: json['condition_value'] as Map<String, dynamic>? ?? {},
      isSecret: json['is_secret'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'description': description,
        'icon': icon,
        'rarity': rarity.value,
        'category': category,
        'condition_type': conditionType,
        'condition_value': conditionValue,
        'is_secret': isSecret,
        'sort_order': sortOrder,
      };
}

class UserAchievement {
  final String id;
  final String userId;
  final String companyId;
  final String achievementId;
  final DateTime unlockedAt;
  final bool notified;

  /// Joined achievement (populated when fetched with join)
  final Achievement? achievement;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.achievementId,
    required this.unlockedAt,
    this.notified = false,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      notified: json['notified'] as bool? ?? false,
      achievement: json['achievements'] != null
          ? Achievement.fromJson(json['achievements'] as Map<String, dynamic>)
          : null,
    );
  }
}
